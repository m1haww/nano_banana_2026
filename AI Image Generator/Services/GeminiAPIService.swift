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
    var user_id: String?
    var fcm_token: String?
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
    private let backendBaseURL = "https://nano-banana-api-production-4035.up.railway.app"
    /// Image job submit (proxies to Poyo on the server). Body matches Poyo: model, callback_url, input { prompt, size, resolution, … }.
    private let generateSubmitPath = "/api/generate"
    private let generateStatusPath = "/api/generate/status"
    private let callBackPath = "/api/task/postback"

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

    /// Fire-and-forget: submits the task to the backend and returns the task ID immediately.
    /// The backend handles the Poyo callback and sends a push notification when done.
    func submitImageTask(
        prompt: String,
        imageUrls: [String]?,
        aspectRatio: String = "1:1",
        resolution: String = "1K",
        model: String = "nano-banana-2-new",
        userId: String,
        fcmToken: String?
    ) async throws -> String {
        guard let url = URL(string: "\(backendBaseURL)\(generateSubmitPath)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = PoyoSubmitRequest(
            model: model,
            callback_url: "\(backendBaseURL)\(callBackPath)",
            input: PoyoInput(
                prompt: prompt,
                image_urls: imageUrls,
                size: aspectRatio,
                resolution: resolution,
                google_search: false
            ),
            user_id: userId,
            fcm_token: fcmToken
        )
        guard let bodyData = try? JSONEncoder().encode(body) else {
            throw APIError.encodingError
        }
        request.httpBody = bodyData
        
        print("Sending this request body: \(String(data: bodyData, encoding: .utf8)!)")

        let session = NetworkService.shared.safeSession()
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let msg: String
            if let flaskErr = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                msg = flaskErr.error
            } else {
                msg = String(data: data, encoding: .utf8) ?? "Submit failed"
            }
            throw APIError.serverError(msg)
        }

        guard let submitResp = try? JSONDecoder().decode(PoyoSubmitResponse.self, from: data) else {
            throw APIError.decodingError
        }

        return submitResp.data.task_id
    }

    /// Fire-and-forget image generation.
    /// Submits the task, saves it via VideoTaskService, and returns immediately.
    /// The backend handles the Poyo callback and sends a push notification when done.
    func createImage(prompt: String, image: UIImage? = nil, aspectRatio: String = "1:1", model: String = "nano-banana-2-new", resolution: String, completion: @escaping (Result<String, APIError>) -> Void) async {
        // Upload reference image if present
        var imageUrlStrings: [String]? = nil
        if let image {
            do {
                let uploaded = try await FileService.shared.uploadImage(image, uploadPrefix: "generate-input")
                guard let key = uploaded.key, !key.isEmpty else {
                    await MainActor.run {
                        completion(.failure(.serverError("Image upload did not return a file key")))
                    }
                    return
                }
                imageUrlStrings = [FileService.shared.getFileUrl(key: key)]
            } catch {
                await MainActor.run {
                    completion(.failure(.networkError(error.localizedDescription)))
                }
                return
            }
        }

        do {
            let taskId = try await self.submitImageTask(
                prompt: prompt,
                imageUrls: imageUrlStrings,
                aspectRatio: aspectRatio,
                resolution: resolution,
                model: model,
                userId: UserService.shared.userId,
                fcmToken: UserService.shared.fcmToken
            )

            // Save as pending task
            VideoTaskService.shared.addPendingTask(
                VideoTask(id: taskId, userId: UserService.shared.userId, prompt: prompt)
            )

            await MainActor.run { completion(.success(taskId)) }
        } catch let error as APIError {
            await MainActor.run { completion(.failure(error)) }
        } catch {
            await MainActor.run { completion(.failure(.networkError(error.localizedDescription))) }
        }
    }

    /// Polls the backend for task status. Returns the file URL on success.
    /// Intended to be called from a background Task (not blocking UI).
    func pollTaskStatus(taskId: String, pollInterval: TimeInterval = 10, timeout: TimeInterval = 300) async -> Result<PoyoStatusData, APIError> {
        guard let url = URL(string: "\(backendBaseURL)\(generateStatusPath)/\(taskId)") else {
            return .failure(.invalidURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let session = NetworkService.shared.safeSession()
        let start = Date()
        let sleepNs = UInt64(max(pollInterval, 1) * 1_000_000_000)

        while Date().timeIntervalSince(start) <= timeout {
            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                      let statusResp = try? JSONDecoder().decode(PoyoStatusResponse.self, from: data) else {
                    try await Task.sleep(nanoseconds: sleepNs)
                    continue
                }
                switch statusResp.data.status {
                case "finished":
                    return .success(statusResp.data)
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
}
