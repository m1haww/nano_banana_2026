import SwiftUI
import Combine

final class UserService: ObservableObject {
    static let shared = UserService()
    
    private let userIdKey = "userId"
    private let backendBaseURL = "https://nano-banana-api-production-4035.up.railway.app"
    private let registrationFlagPrefix = "user.registered"
    
    var userId: String {
        if let id = UserDefaults.standard.string(forKey: userIdKey) {
            return id
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: userIdKey)
            return newId
        }
    }
    
    private let fcmTokenKey = "fcmToken"

    var fcmToken: String? {
        get { UserDefaults.standard.string(forKey: fcmTokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: fcmTokenKey) }
    }

    private var registrationKey: String {
        return registrationFlagPrefix + userId
    }

    var isRegisteredLocally: Bool {
        return UserDefaults.standard.bool(forKey: registrationKey)
    }

    func registerIfNeeded() {
        if UserDefaults.standard.bool(forKey: registrationKey) { return }
        guard var components = URLComponents(string: "\(backendBaseURL)/api/user/register") else { return }
        components.queryItems = [URLQueryItem(name: "user_id", value: userId)]
        if fcmToken != nil {
            components.queryItems?.append(URLQueryItem(name: "fcm_token", value: fcmToken!))
        }
        guard let url = components.url else { return }

        Task {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 30

            do {
                let (data, response) = try await NetworkService.shared.safeSession().data(for: request)
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

                if (200...299).contains(statusCode) || statusCode == 409 {
                    UserDefaults.standard.set(true, forKey: registrationKey)
                    print("User registered successfully")
                    return
                }

                if let apiError = try? JSONDecoder().decode(RegisterErrorResponse.self, from: data) {
                    print("Register user failed: \(apiError.error)")
                } else {
                    print("Register user failed with status: \(statusCode)")
                }
            } catch {
                print("Register user request error: \(error.localizedDescription)")
            }
        }
    }

    /// Positive credits add balance; negative credits consume balance.
    func addCredits(_ credits: Int, completion: ((Bool) -> Void)? = nil) {
        guard credits != 0 else {
            completion?(false)
            return
        }
        guard var components = URLComponents(string: "\(backendBaseURL)/api/user/add_credits") else {
            completion?(false)
            return
        }
        components.queryItems = [
            URLQueryItem(name: "user_id", value: userId),
            URLQueryItem(name: "credits", value: String(credits)),
        ]
        guard let url = components.url else {
            completion?(false)
            return
        }

        Task {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 30

            do {
                let (data, response) = try await NetworkService.shared.safeSession().data(for: request)
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                if (200...299).contains(statusCode) {
                    completion?(true)
                    return
                }
                if let apiError = try? JSONDecoder().decode(RegisterErrorResponse.self, from: data) {
                    print("Add credits failed: \(apiError.error)")
                } else {
                    print("Add credits failed with status: \(statusCode)")
                }
                completion?(false)
            } catch {
                print("Add credits request error: \(error.localizedDescription)")
                completion?(false)
            }
        }
    }

    /// GET /api/user/data/<user_id> — fetches credits and tasks in one call.
    func fetchUserData() async -> UserDataResponse? {
        guard isRegisteredLocally else { return nil }
        guard let url = URL(string: "\(backendBaseURL)/api/user/data/\(userId)") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30

        do {
            let (data, response) = try await NetworkService.shared.safeSession().data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard statusCode == 200 else {
                if let body = try? JSONDecoder().decode(UserDataResponse.self, from: data),
                   let message = body.error {
                    print("Fetch user data failed: \(message)")
                } else {
                    print("Fetch user data failed with status: \(statusCode)")
                }
                return nil
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let payload = try decoder.decode(UserDataResponse.self, from: data)
            return payload
        } catch {
            print("Fetch user data request error: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Response models

private struct RegisterErrorResponse: Decodable {
    let error: String
}

struct UserDataResponse: Decodable {
    let message: String?
    let user: UserDataPayload?
    let tasks: [VideoTask]?
    let pagination: UserDataPagination?
    let error: String?
}

struct UserDataPayload: Decodable {
    let id: String
    let credits: Int
    let fcmToken: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, credits
        case fcmToken = "fcm_token"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
struct UserDataPagination: Decodable {
    let total: Int
    let limit: Int
    let offset: Int
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case total, limit, offset
        case hasMore = "has_more"
    }
}

