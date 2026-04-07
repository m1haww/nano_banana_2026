import Foundation
import UIKit
import AVFoundation

final class FileService: NSObject, URLSessionDataDelegate {
    static let shared = FileService()

    private let baseUrl = "https://nano-banana-api-production-fa0e.up.railway.app"

    private lazy var backgroundSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.ai.image.generator.nano.upload")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
    }()

    private var uploadContinuations: [Int: CheckedContinuation<UploadFileResponse, Error>] = [:]
    private var responseData: [Int: Data] = [:]
    private let lock = NSLock()

    private override init() {
        super.init()
    }

    func uploadImage(_ image: UIImage, fileName: String? = nil, uploadPrefix: String? = nil) async throws -> UploadFileResponse {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw FileServiceError.invalidImage
        }

        let imageName = fileName ?? "image_\(Int(Date().timeIntervalSince1970)).jpg"

        let prepareUrl = URL(string: "\(baseUrl)/api/upload/presigned-url")!
        var prepareRequest = URLRequest(url: prepareUrl)
        prepareRequest.httpMethod = "POST"
        prepareRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var prepareBody: [String: String] = ["filename": imageName]
        prepareBody["contentType"] = "image/jpeg"
        if let prefix = uploadPrefix, !prefix.isEmpty {
            prepareBody["uploadPrefix"] = prefix
        }
        prepareRequest.httpBody = try JSONEncoder().encode(prepareBody)

        let (prepareData, prepareResponse) = try await NetworkService.shared.safeSession().data(for: prepareRequest)

        guard let prepareHttp = prepareResponse as? HTTPURLResponse else {
            throw FileServiceError.invalidResponse
        }
        guard prepareHttp.statusCode == 200 else {
            let message = String(data: prepareData, encoding: .utf8) ?? "Unknown error"
            throw FileServiceError.httpError(statusCode: prepareHttp.statusCode, message: message)
        }

        let prepare = try JSONDecoder().decode(PrepareUploadResponse.self, from: prepareData)

        guard let putUrl = URL(string: prepare.upload_url) else {
            throw FileServiceError.invalidURL
        }
        var putRequest = URLRequest(url: putUrl)
        putRequest.httpMethod = "PUT"
        putRequest.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        putRequest.httpBody = imageData

        let (putData, putResponse) = try await NetworkService.shared.safeSession().data(for: putRequest)

        guard let putHttp = putResponse as? HTTPURLResponse else {
            throw FileServiceError.invalidResponse
        }
        guard (200...299).contains(putHttp.statusCode) else {
            let message = String(data: putData, encoding: .utf8) ?? "Upload failed"
            throw FileServiceError.httpError(statusCode: putHttp.statusCode, message: message)
        }

        return UploadFileResponse(message: nil, fileName: imageName, key: prepare.key)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        lock.lock()
        responseData[dataTask.taskIdentifier]?.append(data)
        lock.unlock()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        lock.lock()
        let continuation = uploadContinuations.removeValue(forKey: task.taskIdentifier)
        let data = responseData.removeValue(forKey: task.taskIdentifier)
        lock.unlock()

        if let error = error {
            continuation?.resume(throwing: error)
            return
        }

        guard let httpResponse = task.response as? HTTPURLResponse else {
            continuation?.resume(throwing: FileServiceError.invalidResponse)
            return
        }

        let responseBody = data ?? Data()
        print("Response data: \(String(data: responseBody, encoding: .utf8) ?? "nil")")

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: responseBody, encoding: .utf8) ?? "Unknown error"
            continuation?.resume(throwing: FileServiceError.httpError(statusCode: httpResponse.statusCode, message: errorMessage))
            return
        }

        do {
            let response = try JSONDecoder().decode(UploadFileResponse.self, from: responseBody)
            continuation?.resume(returning: response)
        } catch {
            continuation?.resume(throwing: error)
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate as? NSObject,
               appDelegate.responds(to: Selector(("backgroundSessionCompletionHandler"))) {
                if let handler = appDelegate.value(forKey: "backgroundSessionCompletionHandler") as? (() -> Void) {
                    handler()
                }
            }
        }
    }

    func getFileUrl(key: String? = nil, fileName: String? = nil) -> String {
        if let key = key, !key.isEmpty {
            let encoded = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            return "\(baseUrl)/api/file/preview?key=\(encoded)"
        }
        if let fileName = fileName, !fileName.isEmpty {
            let encoded = fileName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? fileName
            return "\(baseUrl)/api/file/preview?fileName=\(encoded)"
        }
        return "\(baseUrl)/preview"
    }
}

struct PrepareUploadResponse: Codable {
    let upload_url: String
    let key: String
}

struct UploadFileResponse: Codable {
    let message: String?
    let fileName: String
    let key: String?
}

enum FileServiceError: LocalizedError {
    case invalidImage
    case invalidResponse
    case invalidURL
    case thumbnailGenerationFailed
    case httpError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Failed to convert image to data"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidURL:
            return "Invalid video URL"
        case .thumbnailGenerationFailed:
            return "Failed to generate video thumbnail"
        case .httpError(let statusCode, let message):
            return "HTTP Error \(statusCode): \(message)"
        }
    }
}
