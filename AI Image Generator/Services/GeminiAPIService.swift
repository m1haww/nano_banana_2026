import Foundation
import UIKit
import Combine

// MARK: - Response types

struct ImageCreationResponse: Codable {
    let model: String
    let prompt: String
    let hasInputImage: Bool
    let result: ImageCreationResult

    private enum CodingKeys: String, CodingKey {
        case model
        case prompt
        case hasInputImage = "has_input_image"
        case result
    }
}

struct ImageCreationResult: Codable {
    let text: String?
    let images: [GeneratedImage]?
}

struct GeneratedImage: Codable {
    let data: String?
    let mimeType: String?

    private enum CodingKeys: String, CodingKey {
        case data
        case mimeType = "mime_type"
    }

    func toUIImage() -> UIImage? {
        guard let imageDataString = data else { return nil }
        let cleanBase64 = imageDataString
            .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
            .replacingOccurrences(of: "data:image/png;base64,", with: "")
            .replacingOccurrences(of: "data:image/gif;base64,", with: "")
            .replacingOccurrences(of: "data:image/webp;base64,", with: "")
        guard let imageData = Data(base64Encoded: cleanBase64) else { return nil }
        return UIImage(data: imageData)
    }
}

struct ErrorResponse: Codable {
    let error: String
}

// MARK: - Poyo API (nano-banana-2-new)

struct PoyoSubmitRequest: Encodable {
    let model: String
    let callback_url: String?
    let input: PoyoInput
}

struct PoyoInput: Encodable {
    let prompt: String
    let image_urls: [String]?
    let size: String?
    let resolution: String?
    let google_search: Bool?
}

struct PoyoSubmitResponse: Decodable {
    let code: Int
    let data: PoyoSubmitData
}

/// Submit response `data` (e.g. `{"created_time":"...","task_id":"..."}` — no `status` until poll).
struct PoyoSubmitData: Decodable {
    let task_id: String
    let created_time: String
}

struct PoyoStatusResponse: Decodable {
    let code: Int
    let data: PoyoStatusData
}

struct PoyoStatusData: Decodable {
    let task_id: String
    let status: String
    let files: [PoyoFile]
    let created_time: String?
    let progress: Int?
    let error_message: String?
}

struct PoyoFile: Decodable {
    let file_url: String
    let file_type: String
}

struct PoyoErrorResponse: Decodable {
    let code: Int?
    let error: PoyoErrorDetail?
}

struct PoyoErrorDetail: Decodable {
    let message: String?
    let type: String?
}

// MARK: - Prompt Assistant (Explore Prompts chat + save)

struct PromptAssistantChatRequest: Encodable {
    let prompt: String
}

struct PromptAssistantChatResponse: Decodable {
    let message: PromptAssistantMessage?
    let error: String?
}

struct PromptAssistantMessage: Decodable {
    let role: String?
    let content: String?
}

struct PromptAssistantSaveRequest: Encodable {
    let prompt_text: String
    let title: String?
}

struct SavedPromptItem: Decodable {
    let id: String?
    let user_id: String?
    let title: String?
    let prompt_text: String?
    let created_at: String?
}

struct PromptAssistantSavedResponse: Decodable {
    let saved_prompts: [SavedPromptItem]?
    let count: Int?
}

struct PromptAssistantSaveResponse: Decodable {
    let message: String?
    let saved_prompt: SavedPromptItem?
}

// MARK: - API Error

enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case encodingError
    case invalidResponse
    case networkError(String)
    case serverError(String)
    case unexpectedStatusCode(Int)
    case imageTooLarge

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .noData: return "No data received"
        case .decodingError: return "Failed to decode response"
        case .encodingError: return "Failed to encode request"
        case .invalidResponse: return "Invalid response from server"
        case .networkError(let message): return "Network: \(message)"
        case .serverError(let message): return "Server: \(message)"
        case .unexpectedStatusCode(let code): return "Status \(code)"
        case .imageTooLarge: return "Image too large. Use a smaller image."
        }
    }
}

// MARK: - Service

final class GeminiAPIService: ObservableObject {
    static let shared = GeminiAPIService()

    /// Backend (Railway). Image generation is proxied here; Poyo API key stays on the server.
    private let backendBaseURL = "https://nano-banana-api-production-fa0e.up.railway.app"
    /// Image job submit (proxies to Poyo on the server). Body matches Poyo: model, callback_url, input { prompt, size, resolution, … }.
    private let generateSubmitPath = "/api/generate"
    private let generateStatusPath = "/api/generate/status"

    @Published var userId: String?
    private let userIdKey = "nanoBananaUserId"

    private init() {
        loadOrCreateUserId()
    }

    /// No client Poyo key; UI can treat this as “backend handles generation”.
    var isBackendImageProxyEnabled: Bool { true }

    private func loadOrCreateUserId() {
        if let stored = UserDefaults.standard.string(forKey: userIdKey) {
            userId = stored
        } else {
            let newId = UUID().uuidString
            userId = newId
            UserDefaults.standard.set(newId, forKey: userIdKey)
        }
    }

    /// Poyo / Nano Banana 2: submit task → poll status → download image.
    /// aspectRatio: one of 1:1, 2:3, 3:2, 3:4, 4:3, 4:5, 5:4, 9:16, 16:9, 21:9 (per Poyo API docs).
    func createImage(prompt: String, image: UIImage? = nil, aspectRatio: String = "1:1", model: String = "nano-banana-2-new", completion: @escaping (Result<ImageCreationResponse, APIError>) -> Void) {
        guard let url = URL(string: "\(backendBaseURL)\(generateSubmitPath)") else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = PoyoSubmitRequest(
            model: model,
            callback_url: nil,
            input: PoyoInput(
                prompt: prompt,
                image_urls: nil,
                size: aspectRatio,
                resolution: "2K",
                google_search: false
            )
        )
        guard let bodyData = try? JSONEncoder().encode(body) else {
            completion(.failure(.encodingError))
            return
        }
        request.httpBody = bodyData
        
        print("Request body sent: \(String(decoding: bodyData, as: UTF8.self))")

        Task { [weak self] in
            guard let self else {
                await MainActor.run { completion(.failure(.invalidResponse)) }
                return
            }
            let result = await self.performCreateImageFlow(submitRequest: request, prompt: prompt, model: model)
            await MainActor.run {
                completion(result)
            }
        }
    }

    /// Submit → poll status → download image using `URLSession.data(for:)`.
    private func performCreateImageFlow(submitRequest: URLRequest, prompt: String, model: String) async -> Result<ImageCreationResponse, APIError> {
        let session = NetworkService.shared.safeSession()
        do {
            let (data, response) = try await session.data(for: submitRequest)
            guard let http = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            print("API response: \(String(data: data, encoding: .utf8) ?? "<too long>")")
            
            guard http.statusCode == 200 else {
                let msg: String
                if let flaskErr = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    msg = flaskErr.error
                } else if let poyoErr = try? JSONDecoder().decode(PoyoErrorResponse.self, from: data), let m = poyoErr.error?.message {
                    msg = m
                } else {
                    msg = String(data: data, encoding: .utf8).flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.flatMap { $0.isEmpty ? nil : $0 } ?? "Request failed"
                }
                return .failure(.serverError(msg))
            }
            guard let submitResp = try? JSONDecoder().decode(PoyoSubmitResponse.self, from: data) else {
                return .failure(.decodingError)
            }
            let taskId = submitResp.data.task_id
            switch await pollTaskStatus(taskId: taskId, pollInterval: 2.5, timeout: 90) {
            case .success(let imageURLString):
                switch await downloadImage(from: imageURLString) {
                case .success(let uiImage):
                    let jpegData = uiImage.jpegData(compressionQuality: 0.9)
                    let base64 = jpegData?.base64EncodedString()
                    let gen = GeneratedImage(data: base64, mimeType: "image/jpeg")
                    let wrapped = ImageCreationResponse(
                        model: model,
                        prompt: prompt,
                        hasInputImage: false,
                        result: ImageCreationResult(text: nil, images: [gen])
                    )
                    return .success(wrapped)
                case .failure(let err):
                    return .failure(err)
                }
            case .failure(let err):
                return .failure(err)
            }
        } catch {
            return .failure(.networkError(error.localizedDescription))
        }
    }

    private func pollTaskStatus(taskId: String, pollInterval: TimeInterval, timeout: TimeInterval) async -> Result<String, APIError> {
        guard let url = URL(string: "\(backendBaseURL)\(generateStatusPath)/\(taskId)") else {
            return .failure(.invalidURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let session = NetworkService.shared.safeSession()
        let start = Date()
        let sleepNs = UInt64(max(pollInterval, 0.1) * 1_000_000_000)

        while Date().timeIntervalSince(start) <= timeout {
            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                      let statusResp = try? JSONDecoder().decode(PoyoStatusResponse.self, from: data) else {
                    return .failure(.invalidResponse)
                }
                let status = statusResp.data.status
                switch status {
                case "finished":
                    if let fileURL = statusResp.data.files.first(where: { $0.file_type == "image" })?.file_url {
                        return .success(fileURL)
                    } else {
                        return .failure(.serverError("No image in response"))
                    }
                case "failed":
                    let msg = statusResp.data.error_message ?? "Generation failed"
                    return .failure(.serverError(msg))
                default:
                    try await Task.sleep(nanoseconds: sleepNs)
                }
            } catch {
                return .failure(.networkError(error.localizedDescription))
            }
        }
        return .failure(.serverError("Generation timed out"))
    }

    private func downloadImage(from urlString: String) async -> Result<UIImage, APIError> {
        guard let url = URL(string: urlString) else {
            return .failure(.invalidURL)
        }
        let session = NetworkService.shared.safeSession()
        do {
            let (data, _) = try await session.data(for: URLRequest(url: url))
            guard let img = UIImage(data: data) else {
                return .failure(.noData)
            }
            return .success(img)
        } catch {
            return .failure(.networkError(error.localizedDescription))
        }
    }

    func fetchDiscover(completion: @escaping (Result<[DiscoverItem], APIError>) -> Void) {
        let urlString = "\(backendBaseURL)/api/discover"
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        NetworkService.shared.safeSession().dataTask(with: request) { data, response, error in
            let result: Result<[DiscoverItem], APIError>
            if let error = error {
                result = .failure(.networkError(error.localizedDescription))
            } else if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                result = .failure(.unexpectedStatusCode(http.statusCode))
            } else if let data = data {
                do {
                    let container = try JSONDecoder().decode(DiscoverResponse.self, from: data)
                    result = .success(container.items)
                } catch {
                    result = .failure(.decodingError)
                }
            } else {
                result = .failure(.noData)
            }
            DispatchQueue.main.async {
                completion(result)
            }
        }.resume()
    }

    func promptAssistantChat(prompt: String, completion: @escaping (Result<PromptAssistantChatResponse, APIError>) -> Void) {
        guard let url = URL(string: "\(backendBaseURL)/api/prompt-assistant/chat") else {
            completion(.failure(.invalidURL))
            return
        }
        print("[PromptAssistant] TRIMIT: prompt=\(prompt.prefix(80))...")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = PromptAssistantChatRequest(prompt: prompt)
        guard let bodyData = try? JSONEncoder().encode(body) else {
            completion(.failure(.encodingError))
            return
        }
        request.httpBody = bodyData
        NetworkService.shared.safeSession().dataTask(with: request) { data, response, error in
            let result: Result<PromptAssistantChatResponse, APIError>
            if let error = error {
                print("[PromptAssistant] PRIMIT: network error=\(error.localizedDescription)")
                result = .failure(.networkError(error.localizedDescription))
            } else if let http = response as? HTTPURLResponse, let data = data {
                if http.statusCode != 200 {
                    let bodyStr = String(data: data, encoding: .utf8) ?? ""
                    switch http.statusCode {
                    case 401:
                        print("[PromptAssistant] EROARE 401 Unauthorized – API key lipsă sau invalidă. body=\(bodyStr.prefix(300))")
                    case 403:
                        print("[PromptAssistant] EROARE 403 Forbidden – Acces interzis. body=\(bodyStr.prefix(300))")
                    case 404:
                        print("[PromptAssistant] EROARE 404 Not Found – URL incorect sau resursă inexistentă. body=\(bodyStr.prefix(300))")
                    case 500:
                        print("[PromptAssistant] EROARE 500 Server Error – Eroare pe server (ex. OPEN_AI_KEY). body=\(bodyStr.prefix(300))")
                    case 503:
                        print("[PromptAssistant] EROARE 503 Service Unavailable – Serviciu indisponibil (ex. prompt assistant neconfigurat). body=\(bodyStr.prefix(300))")
                    default:
                        print("[PromptAssistant] EROARE HTTP \(http.statusCode). body=\(bodyStr.prefix(300))")
                    }
                    result = .failure(.unexpectedStatusCode(http.statusCode))
                } else {
                    do {
                        let decoded = try JSONDecoder().decode(PromptAssistantChatResponse.self, from: data)
                        let contentPreview = (decoded.message?.content ?? "").prefix(80)
                        print("[PromptAssistant] PRIMIT: success, content=\(contentPreview)...")
                        if let err = decoded.error, !err.isEmpty {
                            print("[PromptAssistant] PRIMIT: error in response=\(err)")
                        }
                        result = .success(decoded)
                    } catch {
                        print("[PromptAssistant] PRIMIT: decode error=\(error)")
                        result = .failure(.decodingError)
                    }
                }
            } else {
                print("[PromptAssistant] PRIMIT: no data")
                result = .failure(.noData)
            }
            DispatchQueue.main.async { completion(result) }
        }.resume()
    }

    /// Salvează promptul pentru userul curent.
    func promptAssistantSave(promptText: String, title: String?, completion: @escaping (Result<SavedPromptItem, APIError>) -> Void) {
        guard let url = URL(string: "\(backendBaseURL)/api/prompt-assistant/save") else {
            completion(.failure(.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = PromptAssistantSaveRequest(prompt_text: promptText, title: title)
        guard let bodyData = try? JSONEncoder().encode(body) else {
            completion(.failure(.encodingError))
            return
        }
        request.httpBody = bodyData
        NetworkService.shared.safeSession().dataTask(with: request) { data, response, error in
            let result: Result<SavedPromptItem, APIError>
            if let error = error {
                result = .failure(.networkError(error.localizedDescription))
            } else if let http = response as? HTTPURLResponse, let data = data {
                if http.statusCode != 201 {
                    result = .failure(.unexpectedStatusCode(http.statusCode))
                } else {
                    do {
                        let decoded = try JSONDecoder().decode(PromptAssistantSaveResponse.self, from: data)
                        if let saved = decoded.saved_prompt {
                            result = .success(saved)
                        } else {
                            result = .failure(.decodingError)
                        }
                    } catch {
                        result = .failure(.decodingError)
                    }
                }
            } else {
                result = .failure(.noData)
            }
            DispatchQueue.main.async { completion(result) }
        }.resume()
    }

    /// Listează prompturile salvate.
    func promptAssistantSavedList(completion: @escaping (Result<PromptAssistantSavedResponse, APIError>) -> Void) {
        guard let url = URL(string: "\(backendBaseURL)/api/prompt-assistant/saved") else {
            completion(.failure(.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        NetworkService.shared.safeSession().dataTask(with: request) { data, response, error in
            let result: Result<PromptAssistantSavedResponse, APIError>
            if let error = error {
                result = .failure(.networkError(error.localizedDescription))
            } else if let http = response as? HTTPURLResponse, let data = data {
                if http.statusCode != 200 {
                    result = .failure(.unexpectedStatusCode(http.statusCode))
                } else {
                    do {
                        let decoded = try JSONDecoder().decode(PromptAssistantSavedResponse.self, from: data)
                        result = .success(decoded)
                    } catch {
                        result = .failure(.decodingError)
                    }
                }
            } else {
                result = .failure(.noData)
            }
            DispatchQueue.main.async { completion(result) }
        }.resume()
    }
}
