import SwiftUI
import PhotosUI
import UIKit

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var subscriptionService = SubscriptionService.shared
    @FocusState private var inputFocused: Bool
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                messagesList

                inputBar
                    .background(Color.appBackground)
            }
            .background(Color.appBackground)
            .onChange(of: selectedPhotoItem) { newItem in
                Task { await loadPickedPhoto(newItem) }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "FFD75E"), Color(hex: "EFAF0C")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 34, height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(Color(hex: "141210"))
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(String(localized: "AI Assistant"))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appText)
                Text(viewModel.isTyping
                     ? String(localized: "typing…")
                     : String(localized: "Ask anything, edit any photo"))
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(Color(hex: "8F897D"))
            }

            Spacer()

            if !viewModel.messages.isEmpty {
                Button {
                    viewModel.clearConversation()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "8F897D"))
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(Color.appBackground)
    }

    // MARK: - Messages list

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    if viewModel.messages.isEmpty {
                        emptyState
                            .padding(.top, 60)
                            .padding(.horizontal, 24)
                    } else {
                        ForEach(viewModel.messages) { msg in
                            ChatBubble(message: msg)
                                .id(msg.id)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
            .onTapGesture { inputFocused = false }
            .onChange(of: viewModel.messages) { _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    if let last = viewModel.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Empty state (before any messages)

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "FFD75E").opacity(0.25), Color(hex: "EFAF0C").opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 24))

                Image(systemName: "sparkles")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(Color.appAccent)
            }

            Text(String(localized: "Start a conversation"))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appText)

            Text(String(localized: "Ask any question or attach a photo and tell me how to edit it. I can remove backgrounds, change outfits, retouch faces and more."))
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(Color(hex: "8F897D"))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 8)

            suggestionsRow
                .padding(.top, 4)
        }
    }

    private var suggestionsRow: some View {
        let suggestions = [
            String(localized: "Remove the background"),
            String(localized: "Make me look sharper"),
            String(localized: "Change my outfit to a suit")
        ]
        return VStack(spacing: 8) {
            ForEach(suggestions, id: \.self) { text in
                Button {
                    viewModel.input = text
                    inputFocused = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.appAccent)
                        Text(text)
                            .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.appText)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(hex: "8F897D"))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(hex: "1F1C17"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Input bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            // Attached image preview
            if let img = viewModel.attachedImage {
                HStack(spacing: 10) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.appAccent.opacity(0.35), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "Photo attached"))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.appText)
                        Text(String(localized: "Describe what to change"))
                            .font(.system(size: 11.5, weight: .regular, design: .rounded))
                            .foregroundStyle(Color(hex: "8F897D"))
                    }

                    Spacer()

                    Button {
                        viewModel.attachedImage = nil
                        selectedPhotoItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color(hex: "8F897D"))
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
            }

            HStack(alignment: .bottom, spacing: 10) {
                // Attach photo button
                PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.appAccent)
                        .frame(width: 42, height: 42)
                        .background(Color.appAccent.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                // Text field
                HStack(alignment: .bottom, spacing: 8) {
                    TextField(
                        String(localized: "Message the assistant…"),
                        text: $viewModel.input,
                        axis: .vertical
                    )
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.appText)
                    .tint(Color.appAccent)
                    .focused($inputFocused)
                    .lineLimit(1...5)
                    .padding(.vertical, 11)
                    .padding(.leading, 14)

                    Button {
                        viewModel.send()
                        inputFocused = false
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(canSend ? Color(hex: "141210") : Color(hex: "8F897D"))
                            .frame(width: 34, height: 34)
                            .background(
                                Group {
                                    if canSend {
                                        LinearGradient(
                                            colors: [Color(hex: "FFD75E"), Color(hex: "EFAF0C")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    } else {
                                        Color.white.opacity(0.08)
                                    }
                                }
                            )
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSend)
                    .padding(.trailing, 6)
                    .padding(.bottom, 5)
                }
                .background(Color(hex: "1F1C17"))
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
    }

    private var canSend: Bool {
        let hasText = !viewModel.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return (hasText || viewModel.attachedImage != nil) && !viewModel.isTyping
    }

    // MARK: - Photo picker handler

    private func loadPickedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            await MainActor.run {
                viewModel.attachedImage = image
            }
        }
    }
}

// MARK: - Chat Bubble

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .user {
                Spacer(minLength: 40)
                bubbleContent
            } else {
                aiAvatar
                bubbleContent
                Spacer(minLength: 40)
            }
        }
    }

    private var aiAvatar: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "FFD75E"), Color(hex: "EFAF0C")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: 28, height: 28)
            .clipShape(Circle())

            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(Color(hex: "141210"))
        }
    }

    @ViewBuilder
    private var bubbleContent: some View {
        if message.isPlaceholder {
            TypingIndicator()
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(Color(hex: "1F1C17"))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else {
            VStack(alignment: .leading, spacing: 8) {
                if let imgData = message.imageData, let uiImage = UIImage(data: imgData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: 240, maxHeight: 240)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                if let text = message.text, !text.isEmpty {
                    Text(text)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(message.role == .user ? Color(hex: "141210") : Color.appText)
                        .lineSpacing(2)
                        .textSelection(.enabled)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(bubbleBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        if message.role == .user {
            LinearGradient(
                colors: [Color(hex: "FFD75E"), Color(hex: "EFAF0C")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color(hex: "1F1C17")
        }
    }
}

// MARK: - Typing indicator (three animated dots)

private struct TypingIndicator: View {
    @State private var phase: Int = 0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.white.opacity(phase == i ? 0.9 : 0.35))
                    .frame(width: 6, height: 6)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { timer in
                Task { @MainActor in
                    phase = (phase + 1) % 3
                }
            }
        }
    }
}
