//
//  GeminiAPIService.swift
//  AI Image Generator
//

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

struct APIKeyResponse: Codable {
    let apiKey: String?
    let message: String?
    private enum CodingKeys: String, CodingKey {
        case apiKey = "api_key"
        case message
    }
}

struct ErrorResponse: Codable {
    let error: String
}

/// Răspuns de la backend GET /v1/app-config (cheia Poyo din Railway POYO_KEY).
struct AppConfigResponse: Decodable {
    let poyo_api_key: String?
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

struct PoyoSubmitData: Decodable {
    let task_id: String
    let status: String
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
    let messages: [[String: String]]
    let category: String?
    let image_base64: String?
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

    /// Poyo API – Nano Banana 2 (https://docs.poyo.ai/api-manual/image-series/nano-banana-2-new)
    private let baseURL = "https://api.poyo.ai"
    /// Backend (Railway) – categorii / Image Style: GET /v1/categories
    /// Backend public Railway (domeniul generat în Settings → Networking)
    private let backendBaseURL = "https://nano-banana-api-production-fa0e.up.railway.app"
    @Published var userId: String?
    private let userIdKey = "nanoBananaUserId"
    private let apiKeyKey = "poyoAPIKey"

    private init() {
        loadOrCreateUserId()
        if getAPIKey() == nil {
            fetchPoyoKeyFromBackend()
        }
    }

    /// Încarcă cheia Poyo din backend (Railway: variabila POYO_KEY).
    private func fetchPoyoKeyFromBackend() {
        guard let url = URL(string: "\(backendBaseURL)/v1/app-config") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        session().dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, error == nil,
                  let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let data = data,
                  let decoded = try? JSONDecoder().decode(AppConfigResponse.self, from: data),
                  let key = decoded.poyo_api_key, !key.isEmpty else { return }
            DispatchQueue.main.async {
                self.saveAPIKey(key)
            }
        }.resume()
    }

    func getAPIKey() -> String? {
        UserDefaults.standard.string(forKey: apiKeyKey)
    }

    func saveAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: apiKeyKey)
    }

    private func addBearerHeader(to request: inout URLRequest) {
        if let apiKey = getAPIKey() {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
    }

    private func loadOrCreateUserId() {
        if let stored = UserDefaults.standard.string(forKey: userIdKey) {
            userId = stored
        } else {
            let newId = UUID().uuidString
            userId = newId
            UserDefaults.standard.set(newId, forKey: userIdKey)
        }
    }

    private func session() -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }

    /// Register for API key (same backend as nano-banana). Call once if key is missing.
    func registerAPIKey(completion: @escaping (Result<String, APIError>) -> Void) {
        guard let uid = userId, let url = URL(string: "\(baseURL)/v1/api-key/register") else {
            completion(.failure(.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["user_id": uid]
        guard let data = try? JSONSerialization.data(withJSONObject: body) else {
            completion(.failure(.encodingError))
            return
        }
        request.httpBody = data

        session().dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.networkError(error.localizedDescription)))
                    return
                }
                guard let http = response as? HTTPURLResponse else {
                    completion(.failure(.invalidResponse))
                    return
                }
                guard let data = data else {
                    completion(.failure(.noData))
                    return
                }
                switch http.statusCode {
                case 200, 201:
                    do {
                        let decoded = try JSONDecoder().decode(APIKeyResponse.self, from: data)
                        if let key = decoded.apiKey {
                            self?.saveAPIKey(key)
                            completion(.success(key))
                        } else {
                            completion(.failure(.serverError("No API key in response")))
                        }
                    } catch {
                        completion(.failure(.decodingError))
                    }
                case 400, 500:
                    if let err = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        completion(.failure(.serverError(err.error)))
                    } else {
                        completion(.failure(.serverError("Request failed")))
                    }
                default:
                    completion(.failure(.unexpectedStatusCode(http.statusCode)))
                }
            }
        }.resume()
    }

    /// Poyo / Nano Banana 2: submit task → poll status → download image.
    /// aspectRatio: one of 1:1, 2:3, 3:2, 3:4, 4:3, 4:5, 5:4, 9:16, 16:9, 21:9 (per Poyo API docs).
    func createImage(prompt: String, image: UIImage? = nil, aspectRatio: String = "1:1", model: String = "nano-banana-2-new", completion: @escaping (Result<ImageCreationResponse, APIError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/generate/submit") else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addBearerHeader(to: &request)

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

        session().dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async { completion(.failure(.networkError(error.localizedDescription))) }
                return
            }
            guard let http = response as? HTTPURLResponse, let data = data else {
                DispatchQueue.main.async { completion(.failure(.invalidResponse)) }
                return
            }
            guard http.statusCode == 200 else {
                let msg = (try? JSONDecoder().decode(PoyoErrorResponse.self, from: data)).flatMap { $0.error?.message } ?? "Request failed"
                DispatchQueue.main.async { completion(.failure(.serverError(msg))) }
                return
            }
            guard let submitResp = try? JSONDecoder().decode(PoyoSubmitResponse.self, from: data) else {
                DispatchQueue.main.async { completion(.failure(.decodingError)) }
                return
            }
            let taskId = submitResp.data.task_id
            self.pollTaskStatus(taskId: taskId, pollInterval: 2.5, timeout: 90) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let imageURLString):
                        self.downloadImage(from: imageURLString) { imgResult in
                            DispatchQueue.main.async {
                                switch imgResult {
                                case .success(let uiImage):
                                    let jpegData = uiImage.jpegData(compressionQuality: 0.9)
                                    let base64 = jpegData?.base64EncodedString()
                                    let gen = GeneratedImage(data: base64, mimeType: "image/jpeg")
                                    let response = ImageCreationResponse(
                                        model: model,
                                        prompt: prompt,
                                        hasInputImage: false,
                                        result: ImageCreationResult(text: nil, images: [gen])
                                    )
                                    completion(.success(response))
                                case .failure(let err):
                                    completion(.failure(err))
                                }
                            }
                        }
                    case .failure(let err):
                        completion(.failure(err))
                    }
                }
            }
        }.resume()
    }

    private func pollTaskStatus(taskId: String, pollInterval: TimeInterval, timeout: TimeInterval, completion: @escaping (Result<String, APIError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/generate/status/\(taskId)") else {
            completion(.failure(.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addBearerHeader(to: &request)

        let start = Date()
        func poll() {
            if Date().timeIntervalSince(start) > timeout {
                completion(.failure(.serverError("Generation timed out")))
                return
            }
            session().dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }
                if let error = error {
                    completion(.failure(.networkError(error.localizedDescription)))
                    return
                }
                guard let http = response as? HTTPURLResponse, let data = data, http.statusCode == 200,
                      let statusResp = try? JSONDecoder().decode(PoyoStatusResponse.self, from: data) else {
                    completion(.failure(.invalidResponse))
                    return
                }
                let status = statusResp.data.status
                switch status {
                case "finished":
                    if let fileURL = statusResp.data.files.first(where: { $0.file_type == "image" })?.file_url {
                        completion(.success(fileURL))
                    } else {
                        completion(.failure(.serverError("No image in response")))
                    }
                case "failed":
                    let msg = statusResp.data.error_message ?? "Generation failed"
                    completion(.failure(.serverError(msg)))
                default:
                    DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + pollInterval) { poll() }
                }
            }.resume()
        }
        poll()
    }

    private func downloadImage(from urlString: String, completion: @escaping (Result<UIImage, APIError>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        session().dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error.localizedDescription)))
                return
            }
            guard let data = data, let img = UIImage(data: data) else {
                completion(.failure(.noData))
                return
            }
            completion(.success(img))
        }.resume()
    }

    /// Image Style – toate datele din backend (GET /v1/categories → data/image_styles.json).
    func fetchImageStyles(completion: @escaping (Result<[CategoryCard], APIError>) -> Void) {
        let urlString = "\(backendBaseURL)/v1/categories"
        print("[fetchImageStyles] URL: \(urlString)")
        guard let url = URL(string: urlString) else {
            print("[fetchImageStyles] invalidURL")
            completion(.failure(.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        session().dataTask(with: request) { data, response, error in
            let result: Result<[CategoryCard], APIError>
            if let error = error {
                print("[fetchImageStyles] network error: \(error.localizedDescription)")
                result = .failure(.networkError(error.localizedDescription))
            } else if let http = response as? HTTPURLResponse {
                print("[fetchImageStyles] statusCode: \(http.statusCode), data length: \(data?.count ?? 0)")
                if http.statusCode != 200 {
                    result = .failure(.unexpectedStatusCode(http.statusCode))
                } else if let data = data {
                    do {
                        let container = try JSONDecoder().decode(ImageStyleResponse.self, from: data)
                        print("[fetchImageStyles] decode OK: \(container.cards.count) cards")
                        result = .success(container.cards)
                    } catch {
                        print("[fetchImageStyles] decode failed: \(error). Preview: \(String(data: data, encoding: .utf8)?.prefix(200) ?? "nil")")
                        result = .failure(.decodingError)
                    }
                } else {
                    print("[fetchImageStyles] no data")
                    result = .failure(.noData)
                }
            } else {
                print("[fetchImageStyles] no response, no data")
                result = .failure(.noData)
            }
            DispatchQueue.main.async {
                completion(result)
            }
        }.resume()
    }

    /// Discover feed – GET /v1/discover (imagini + prompt + subtitle).
    func fetchDiscover(completion: @escaping (Result<[DiscoverItem], APIError>) -> Void) {
        let urlString = "\(backendBaseURL)/v1/discover"
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        session().dataTask(with: request) { data, response, error in
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

    // MARK: - Prompt Assistant (Explore Prompts: chat + save)

    /// Chat pentru crearea promptului. messages: [ ["role": "user"|"assistant", "content": "..." ] ]
    func promptAssistantChat(messages: [[String: String]], category: String?, imageBase64: String?, completion: @escaping (Result<PromptAssistantChatResponse, APIError>) -> Void) {
        guard let url = URL(string: "\(backendBaseURL)/v1/prompt-assistant/chat") else {
            completion(.failure(.invalidURL))
            return
        }
        // DEBUG: ce trimitem
        print("[PromptAssistant] TRIMIT: messages=\(messages.count), category=\(category ?? "nil"), image=\(imageBase64 != nil ? "da" : "nu")")
        for (i, m) in messages.enumerated() {
            let role = m["role"] ?? "?"
            let content = (m["content"] ?? "").prefix(60)
            print("[PromptAssistant]   [\(i)] \(role): \(content)...")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addBearerHeader(to: &request)
        let body = PromptAssistantChatRequest(messages: messages, category: category, image_base64: imageBase64)
        guard let bodyData = try? JSONEncoder().encode(body) else {
            completion(.failure(.encodingError))
            return
        }
        request.httpBody = bodyData
        session().dataTask(with: request) { data, response, error in
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
        guard let url = URL(string: "\(backendBaseURL)/v1/prompt-assistant/save") else {
            completion(.failure(.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addBearerHeader(to: &request)
        let body = PromptAssistantSaveRequest(prompt_text: promptText, title: title)
        guard let bodyData = try? JSONEncoder().encode(body) else {
            completion(.failure(.encodingError))
            return
        }
        request.httpBody = bodyData
        session().dataTask(with: request) { data, response, error in
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
        guard let url = URL(string: "\(backendBaseURL)/v1/prompt-assistant/saved") else {
            completion(.failure(.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addBearerHeader(to: &request)
        session().dataTask(with: request) { data, response, error in
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
