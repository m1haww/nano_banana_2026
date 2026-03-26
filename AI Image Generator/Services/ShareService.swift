//
//  ShareService.swift
//  AI Image Generator
//

import Combine
import SwiftUI
import UIKit

/// Presents the system share sheet from a single place (tab root) so feature screens only call `present(items:)`.
final class ShareService: ObservableObject {
    static let shared = ShareService()

    @Published private(set) var items: [Any] = []
    @Published var isPresented = false

    private init() {}

    func present(items: [Any]) {
        guard !items.isEmpty else { return }
        self.items = items
        isPresented = true
    }

    /// Clears payload after the sheet dismisses (swipe or after share) so we don’t retain images.
    func clearPayload() {
        items = []
    }
}

// MARK: - UIKit bridge

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
