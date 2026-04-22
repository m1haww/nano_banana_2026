import SwiftUI
import Combine

@MainActor
final class VideoTaskService: ObservableObject {
    static let shared = VideoTaskService()

    /// Tasks currently waiting for a backend callback.
    @Published var pendingTasks: [VideoTask] = []

    private let storageKey = "videoTaskService.pendingTasks"

    /// Active background polling tasks keyed by task ID, so we don't double-poll.
    private var pollingTasks: [String: Task<Void, Never>] = [:]

    private init() {
        loadPendingTasks()
    }

    // MARK: - Submit

    /// Fire-and-forget: submits the generation task to the backend, saves it locally, and returns immediately.
    func submitTask(prompt: String, aspectRatio: String = "1:1", resolution: String = "1K", referenceImage: UIImage? = nil) async throws -> VideoTask {
        let api = GeminiAPIService.shared
        let userId = UserService.shared.userId
        let fcmToken = UserService.shared.fcmToken

        // Upload reference image first if present
        var imageUrlStrings: [String]? = nil
        if let image = referenceImage {
            let uploaded = try await FileService.shared.uploadImage(image, uploadPrefix: "generate-input")
            guard let key = uploaded.key, !key.isEmpty else {
                throw APIError.serverError("Image upload did not return a file key")
            }
            imageUrlStrings = [FileService.shared.getFileUrl(key: key)]
        }

        // Submit to backend — the backend will call Poyo and handle the callback
        let taskId = try await api.submitImageTask(
            prompt: prompt,
            imageUrls: imageUrlStrings,
            aspectRatio: aspectRatio,
            resolution: resolution,
            userId: userId,
            fcmToken: fcmToken
        )

        // Save locally as pending
        let task = VideoTask(
            id: taskId,
            userId: userId,
            status: .pending,
            prompt: prompt
        )
        pendingTasks.append(task)
        savePendingTasks()

        return task
    }

    /// Add a task to the pending list, insert a pending gallery placeholder, and start background polling.
    func addPendingTask(_ task: VideoTask) {
        pendingTasks.append(task)
        savePendingTasks()
        GalleryService.shared.addPendingItem(taskId: task.id, prompt: task.prompt)
        startBackgroundPolling(for: task)
    }

    // MARK: - Background polling

    /// Polls the backend in the background for a specific task. Does not block the UI.
    private func startBackgroundPolling(for task: VideoTask) {
        guard pollingTasks[task.id] == nil else { return } // already polling

        let taskId = task.id
        pollingTasks[taskId] = Task.detached { [weak self] in
            let result = await GeminiAPIService.shared.pollTaskStatus(taskId: taskId)

            switch result {
            case .success(let statusData):
                // Update gallery item with the downloaded image
                if let fileURLString = statusData.files.first(where: { $0.file_type == "image" })?.file_url,
                   let fileURL = URL(string: fileURLString) {
                    await GalleryService.shared.completeItem(taskId: taskId, imageURL: fileURL)
                }

                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.pollingTasks.removeValue(forKey: taskId)
                    self.pendingTasks.removeAll { $0.id == taskId }
                    self.savePendingTasks()
                }
            case .failure(let error):
                print("[VideoTaskService] Background poll failed for \(taskId): \(error.localizedDescription)")
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.pollingTasks.removeValue(forKey: taskId)
                    self.pendingTasks.removeAll { $0.id == taskId }
                    self.savePendingTasks()
                    GalleryService.shared.markItemFailed(taskId: taskId)
                }
            }
        }
    }

    /// Resume polling for any tasks that were pending when the app was killed.
    func resumePollingForPendingTasks() {
        for task in pendingTasks {
            startBackgroundPolling(for: task)
        }
    }

    // MARK: - Notification handling

    /// Called from AppDelegate when a push notification arrives (foreground or tap).
    func handleNotification(userInfo: [AnyHashable: Any]) {
        let taskId = userInfo["task_id"] as? String
        let imageUrl = userInfo["imageUrl"] as? String
        let status = userInfo["status"] as? String

        // Cancel any active polling for this task
        if let taskId {
            pollingTasks[taskId]?.cancel()
            pollingTasks.removeValue(forKey: taskId)
            pendingTasks.removeAll { $0.id == taskId }
            savePendingTasks()
        }

        guard let imageUrl, !imageUrl.isEmpty else {
            if let taskId, status == "failed" {
                GalleryService.shared.markItemFailed(taskId: taskId)
                print("[VideoTaskService] Task \(taskId) failed")
            }
            return
        }

        // Update gallery item in the background
        if let taskId, let url = URL(string: imageUrl) {
            Task {
                await GalleryService.shared.completeItem(taskId: taskId, imageURL: url)
            }
        }
    }

    /// Sync tasks fetched from the backend (e.g. on app launch).
    func syncTasks(_ tasks: [VideoTask]) {
        // Update pending list: remove any that are no longer pending on the server
        let serverPendingIds = Set(tasks.filter { $0.status == .pending }.map(\.id))
        pendingTasks = pendingTasks.filter { serverPendingIds.contains($0.id) }

        savePendingTasks()
    }

    // MARK: - Persistence

    private func savePendingTasks() {
        guard let data = try? JSONEncoder().encode(pendingTasks) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func loadPendingTasks() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let tasks = try? JSONDecoder().decode([VideoTask].self, from: data) else { return }
        pendingTasks = tasks
    }
}
