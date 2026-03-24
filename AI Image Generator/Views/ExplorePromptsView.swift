//
//  ExplorePromptsView.swift
//  AI Image Generator
//

import SwiftUI
import PhotosUI

struct PromptType: Identifiable {
    let id = UUID()
    let emoji: String
    let label: String
    let gradient: [Color]
}

private let promptTypes: [PromptType] = [
    PromptType(emoji: "🔥", label: "Sexy",      gradient: [Color(hex: "E8453C"), Color(hex: "F5785A")]),
    PromptType(emoji: "✨", label: "Fantasy",    gradient: [Color(hex: "7C3AED"), Color(hex: "A78BFA")]),
    PromptType(emoji: "🎨", label: "Art",        gradient: [Color(hex: "2563EB"), Color(hex: "60A5FA")]),
    PromptType(emoji: "🌿", label: "Nature",     gradient: [Color(hex: "059669"), Color(hex: "34D399")]),
    PromptType(emoji: "🤖", label: "Sci-Fi",     gradient: [Color(hex: "0891B2"), Color(hex: "67E8F9")]),
    PromptType(emoji: "👤", label: "Portrait",   gradient: [Color(hex: "D97706"), Color(hex: "FCD34D")]),
    PromptType(emoji: "🌃", label: "Cyberpunk",  gradient: [Color(hex: "DB2777"), Color(hex: "F472B6")]),
    PromptType(emoji: "📸", label: "Realistic",  gradient: [Color(hex: "6366F1"), Color(hex: "A5B4FC")]),
    PromptType(emoji: "🎭", label: "Anime",      gradient: [Color(hex: "EC4899"), Color(hex: "F9A8D4")]),
    PromptType(emoji: "💎", label: "Luxury",     gradient: [Color(hex: "B45309"), Color(hex: "F59E0B")]),
]

struct ExplorePromptsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.hideTabBarBinding) private var hideTabBarBinding
    let currentPrompt: String
    let onSelectPrompt: (String) -> Void

    @State private var inputText: String = ""
    @State private var selectedType: PromptType? = nil
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var attachedImage: UIImage? = nil
    @FocusState private var inputFocused: Bool

    @State private var chatMessages: [(role: String, content: String)] = []
    @State private var isSending: Bool = false
    @State private var chatError: String? = nil

    private let api = GeminiAPIService.shared
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground
                .ignoresSafeArea()

            // Imaginea pe întregul ecran ca background, cover
            Image("1")
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .opacity(0.2)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Back
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color.appText)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.top, 4)

                ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Sphere + title
                    VStack(spacing: 20) {
                        HStack(spacing: 8) {
                            ForEach(0..<4, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(Color.appAccent)
                            }
                        }
                        .padding(.top, 24)

                        Text("What would you\nlike to create?")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.appText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)

                        VStack(spacing: 6) {
                            Text("Your AI prompt helper")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.appAccent)
                            Text("Pick a style, describe your idea, and we'll\ncraft the perfect prompt for you.")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.appTextSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                        }
                    }

                    // Type grid
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(promptTypes) { type in
                            typeCard(type)
                        }
                    }
                    .padding(.horizontal, 4)

                    // Selected type indicator
                    if let sel = selectedType {
                        HStack(spacing: 8) {
                            Text(sel.emoji)
                                .font(.system(size: 18))
                            Text(sel.label)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.appText)
                            Spacer()
                            Button {
                                withAnimation(.easeOut(duration: 0.15)) { selectedType = nil }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.appTextSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.appCard)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.appAccent.opacity(0.3), lineWidth: 1)
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                    // Chat messages (răspunsurile de la OpenAI)
                    if !chatMessages.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(chatMessages.enumerated()), id: \.offset) { _, item in
                                HStack(alignment: .top, spacing: 10) {
                                    if item.role == "user" { Spacer(minLength: 40) }
                                    Text(item.content)
                                        .font(.system(size: 15, weight: .regular, design: .rounded))
                                        .foregroundStyle(Color.appText)
                                        .padding(12)
                                        .background(item.role == "user" ? Color.appAccent.opacity(0.2) : Color.appCard)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                    if item.role == "assistant" { Spacer(minLength: 40) }
                                }
                            }
                            if isSending {
                                HStack(alignment: .top, spacing: 10) {
                                    ProgressView().tint(Color.appAccent)
                                    Text("Thinking...")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundStyle(Color.appTextSecondary)
                                }
                            }
                            if let err = chatError {
                                Text(err)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(.red)
                            }
                            if let last = chatMessages.last, last.role == "assistant", !last.content.isEmpty {
                                Button {
                                    onSelectPrompt(last.content)
                                    dismiss()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Use this prompt")
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundStyle(Color.appBackground)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.appAccent)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }

                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                Spacer(minLength: 0)
                inputBar
            }
        }
        .tint(Color.appAccent)
        .navigationBarHidden(true)
        .onAppear { hideTabBarBinding.wrappedValue = true }
        .onDisappear { hideTabBarBinding.wrappedValue = false }
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    attachedImage = img
                } else {
                    attachedImage = nil
                }
            }
        }
    }

    // MARK: - Type card
    private func typeCard(_ type: PromptType) -> some View {
        let isSelected = selectedType?.id == type.id
        return Button {
            withAnimation(.easeOut(duration: 0.15)) {
                selectedType = isSelected ? nil : type
            }
        } label: {
            VStack(spacing: 6) {
                Text(type.emoji)
                    .font(.system(size: 26))
                Text(type.label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: type.gradient.map { $0.opacity(isSelected ? 1.0 : 0.6) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white.opacity(0.5) : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Input bar
    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.appDivider)

            // Image preview
            if let img = attachedImage {
                HStack(spacing: 10) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Text("Reference image")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.appTextSecondary)
                    Spacer()
                    Button {
                        attachedImage = nil
                        selectedPhotoItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }

            HStack(spacing: 8) {
                // Photo picker
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Image(systemName: attachedImage != nil ? "photo.fill" : "photo")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.appAccent)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // Text field
                HStack(spacing: 8) {
                    if let sel = selectedType {
                        Text(sel.emoji)
                            .font(.system(size: 16))
                    }
                    TextField("Describe your image...", text: $inputText, axis: .vertical)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.appText)
                        .lineLimit(1...3)
                        .focused($inputFocused)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(inputFocused ? Color.appAccent.opacity(0.5) : Color.appDivider, lineWidth: 1)
                )
                .onSubmit { submitInput() }

                // Send
                Button { submitInput() } label: {
                    Circle()
                        .fill(canSubmit ? Color.appAccent : Color.appDivider)
                        .frame(width: 38, height: 38)
                        .overlay(
                            Image(systemName: "arrow.up")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(canSubmit ? Color.appBackground : Color.appTextSecondary)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(Color.appBackground)
    }

    private var canSubmit: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || attachedImage != nil
    }

    private func submitInput() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefix = selectedType.map { "\($0.label) style: " } ?? ""
        let userContent = text.isEmpty ? "Use the attached image as style reference." : (prefix + text)
        guard !userContent.isEmpty || attachedImage != nil else { return }

        chatError = nil
        chatMessages.append((role: "user", content: userContent))
        inputText = ""
        let category = selectedType?.label
        let imageBase64 = attachedImage.flatMap { img -> String? in
            img.jpegData(compressionQuality: 0.7).map { "data:image/jpeg;base64," + $0.base64EncodedString() }
        }
        if attachedImage != nil {
            attachedImage = nil
            selectedPhotoItem = nil
        }

        let dictMessages = chatMessages.map { ["role": $0.role, "content": $0.content] }
        isSending = true
        api.promptAssistantChat(messages: dictMessages, category: category, imageBase64: imageBase64) { result in
            isSending = false
            switch result {
            case .success(let response):
                if let err = response.error, !err.isEmpty {
                    chatError = err
                    return
                }
                let content = response.message?.content ?? ""
                chatMessages.append((role: "assistant", content: content))
            case .failure(let err):
                chatError = err.localizedDescription
            }
        }
    }
}

#Preview {
    ExplorePromptsView(currentPrompt: "A cat in space") { _ in }
}
