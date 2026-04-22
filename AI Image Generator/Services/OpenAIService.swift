import Foundation
import Combine

struct PromptAssistantGenerateRequest: Encodable {
    let prompt: String
    let category: String?
}

struct PromptAssistantGenerateResponse: Decodable {
    let generated_prompt: String
    let error: String
}

final class OpenAIService: ObservableObject {
    static let shared = OpenAIService()

    private let backendBaseURL = "https://nano-banana-api-production-4035.up.railway.app"

    private init() {}

    func generatePrompt(prompt: String, category: String?, completion: @escaping (Result<PromptAssistantGenerateResponse, APIError>) -> Void) {
        guard let url = URL(string: "\(backendBaseURL)/api/prompt-assistant/generate") else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = PromptAssistantGenerateRequest(prompt: prompt, category: category)
        guard let bodyData = try? JSONEncoder().encode(body) else {
            completion(.failure(.encodingError))
            return
        }
        request.httpBody = bodyData

        Task {
            let result = await Self.performGenerate(request: request)
            await MainActor.run {
                completion(result)
            }
        }
    }

    private static func performGenerate(request: URLRequest) async -> Result<PromptAssistantGenerateResponse, APIError> {
        let session = NetworkService.shared.safeSession()
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            guard http.statusCode == 200 else {
                return .failure(.unexpectedStatusCode(http.statusCode))
            }
            guard let decoded = try? JSONDecoder().decode(PromptAssistantGenerateResponse.self, from: data) else {
                return .failure(.decodingError)
            }
            return .success(decoded)
        } catch {
            return .failure(.networkError(error.localizedDescription))
        }
    }
}
