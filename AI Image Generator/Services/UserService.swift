import SwiftUI
import Combine

final class UserService: ObservableObject {
    static let shared = UserService()
    
    private let userIdKey = "userId"
    private let backendBaseURL = "https://nano-banana-api-production-fa0e.up.railway.app"
    private let registrationFlagPrefix = "user.registered."
    
    var userId: String {
        if let id = UserDefaults.standard.string(forKey: userIdKey) {
            return id
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: userIdKey)
            return newId
        }
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

    /// GET /api/user/credits/<user_id>, only when local registration is already done.
    func fetchUserCreditsIfRegistered(completion: ((Int?) -> Void)? = nil) {
        guard isRegisteredLocally else {
            completion?(nil)
            return
        }
        guard let url = URL(string: "\(backendBaseURL)/api/user/credits/\(userId)") else {
            completion?(nil)
            return
        }

        Task {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 30

            do {
                let (data, response) = try await NetworkService.shared.safeSession().data(for: request)
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                guard statusCode == 200 else {
                    if let apiError = try? JSONDecoder().decode(UserCreditsResponse.self, from: data),
                       let message = apiError.error {
                        print("Fetch user credits failed: \(message)")
                    } else {
                        print("Fetch user credits failed with status: \(statusCode)")
                    }
                    completion?(nil)
                    return
                }
                let payload = try JSONDecoder().decode(UserCreditsResponse.self, from: data)
                completion?(payload.user?.credits)
            } catch {
                print("Fetch user credits request error: \(error.localizedDescription)")
                completion?(nil)
            }
        }
    }
}

private struct RegisterErrorResponse: Decodable {
    let error: String
}

private struct UserCreditsResponse: Decodable {
    let message: String?
    let user: UserCreditsPayload?
    let error: String?
}

private struct UserCreditsPayload: Decodable {
    let credits: Int
}
