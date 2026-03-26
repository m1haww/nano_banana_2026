import Foundation
import AdServices

final class AppleAttributionService: Sendable {

    static let shared = AppleAttributionService()

    private static let attributionURL = URL(string: "https://api-adservices.apple.com/api/v1/")!
    private static let maxRetries = 3
    private static let retryIntervalSeconds: UInt64 = 5
    private static let initialDelaySeconds: UInt64 = 2

    private init() {}

    @available(iOS 14.3, *)
    func getAttributionToken() throws -> String {
        try AAAttribution.attributionToken()
    }

    @available(iOS 14.3, *)
    func fetchAttributionData() async -> AppleAttributionData? {
        let token: String
        do {
            token = try getAttributionToken()
        } catch {
            print("[AppleAttribution] Failed to get token: \(error)")
            return nil
        }
        
        try? await Task.sleep(nanoseconds: Self.initialDelaySeconds * 1_000_000_000)

        var lastError: Error?
        for attempt in 1...Self.maxRetries {
            let result = await postTokenAndDecode(token: token)
            switch result {
            case .success(let data):
                return data
            case .failure(let error):
                lastError = error
                if case AppleAttributionError.httpStatus(404) = error, attempt < Self.maxRetries {
                    try? await Task.sleep(nanoseconds: Self.retryIntervalSeconds * 1_000_000_000)
                    continue
                }
                return nil
            }
        }
        if let lastError {
            print("[AppleAttribution] Failed after retries: \(lastError)")
        }
        return nil
    }

    private func postTokenAndDecode(token: String) async -> Result<AppleAttributionData?, Error> {
        print("Fetching atribution data...")
        var request = URLRequest(url: Self.attributionURL)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(token.utf8)
        

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await NetworkService.shared.safeSession().data(for: request)
            print("Fetched data from apple:")
            print(String(data: data, encoding: .utf8) ?? "<unreadable>")
        } catch {
            return .failure(error)
        }

        guard let http = response as? HTTPURLResponse else {
            return .failure(AppleAttributionError.invalidResponse)
        }

        switch http.statusCode {
        case 200:
            break
        case 400:
            return .failure(AppleAttributionError.httpStatus(400))
        case 404:
            return .failure(AppleAttributionError.httpStatus(404))
        case 500:
            return .failure(AppleAttributionError.httpStatus(500))
        default:
            return .failure(AppleAttributionError.httpStatus(http.statusCode))
        }

        do {
            let decoded = try JSONDecoder().decode(AppleAttributionData.self, from: data)
            return .success(decoded)
        } catch {
            return .failure(error)
        }
    }
}

enum AppleAttributionError: Error, Sendable {
    case invalidResponse
    case httpStatus(Int)
}
