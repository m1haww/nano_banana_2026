import SwiftUI

struct PromptType: Identifiable {
    let id = UUID()
    let emoji: String
    let label: String
    let gradient: [Color]
}

private let promptTypes: [PromptType] = [
    PromptType(emoji: "🔥", label: "Sexy", gradient: [Color(hex: "E8453C"), Color(hex: "F5785A")]),
    PromptType(emoji: "✨", label: "Fantasy", gradient: [Color(hex: "7C3AED"), Color(hex: "A78BFA")]),
    PromptType(emoji: "🎨", label: "Art", gradient: [Color(hex: "2563EB"), Color(hex: "60A5FA")]),
    PromptType(emoji: "🌿", label: "Nature", gradient: [Color(hex: "059669"), Color(hex: "34D399")]),
    PromptType(emoji: "🤖", label: "Sci-Fi", gradient: [Color(hex: "0891B2"), Color(hex: "67E8F9")]),
    PromptType(emoji: "👤", label: "Portrait", gradient: [Color(hex: "D97706"), Color(hex: "FCD34D")]),
    PromptType(emoji: "🌃", label: "Cyberpunk", gradient: [Color(hex: "DB2777"), Color(hex: "F472B6")]),
    PromptType(emoji: "📸", label: "Realistic", gradient: [Color(hex: "6366F1"), Color(hex: "A5B4FC")]),
    PromptType(emoji: "🎭", label: "Anime", gradient: [Color(hex: "EC4899"), Color(hex: "F9A8D4")]),
    PromptType(emoji: "💎", label: "Luxury", gradient: [Color(hex: "B45309"), Color(hex: "F59E0B")]),
]

struct ExplorePromptsView: View {
    @Environment(\.dismiss) private var dismiss
    let currentPrompt: String
    let onSelectPrompt: (String) -> Void

    @State private var inputText: String = ""
    @State private var selectedType: PromptType? = nil
    @FocusState private var inputFocused: Bool

    @State private var generatedPrompt: String = ""
    @State private var isGenerating: Bool = false
    @State private var generationError: String? = nil

    private let openAIService = OpenAIService.shared
    private let columns = [
        GridItem(.flexible(), spacing: 9),
        GridItem(.flexible(), spacing: 9),
        GridItem(.flexible(), spacing: 9),
        GridItem(.flexible(), spacing: 9),
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground
                .ignoresSafeArea()

            Image("1")
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .opacity(0.2)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.appText)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        VStack(spacing: 20) {
                            HStack(spacing: 8) {
                                ForEach(0..<4, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(Color.appAccent)
                                }
                            }
                            .padding(.top, 24)

                            Text(String(localized: "What would you\nlike to create?"))
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.appText)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)

                            VStack(spacing: 6) {
                                Text(String(localized: "Your AI prompt helper"))
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.appAccent)
                                Text(String(localized: "Pick a style, describe your idea, and we'll\ncraft the perfect prompt for you."))
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundStyle(Color.appTextSecondary)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(2)
                            }
                        }

                        LazyVGrid(columns: columns, spacing: 9) {
                            ForEach(promptTypes) { type in
                                typeCard(type)
                            }
                        }
                        .padding(.horizontal, 4)

                        if isGenerating {
                            HStack(spacing: 10) {
                                ProgressView().tint(Color.appAccent)
                                Text(String(localized: "Generating prompt..."))
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.appTextSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if let err = generationError {
                            Text(err)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if !generatedPrompt.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(String(localized: "Generated Prompt"))
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.appAccent)
                                Text(generatedPrompt)
                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                                    .foregroundStyle(Color.appText)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.appCard)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                Button {
                                    onSelectPrompt(generatedPrompt)
                                    dismiss()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text(String(localized: "Use this prompt"))
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
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }

                Spacer(minLength: 0)
                inputBar
            }
        }
        .tint(Color.appAccent)
        .onAppear {
            if inputText.isEmpty && !currentPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                inputText = currentPrompt
            }
        }
    }

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
                Text(type.label.localized)
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

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.appDivider)

            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    if let sel = selectedType {
                        Text(sel.emoji)
                            .font(.system(size: 16))
                    }
                    TextField(
                        "",
                        text: $inputText,
                        prompt: Text(String(localized: "Describe your image..."))
                            .foregroundColor(Color.appText.opacity(0.62)),
                        axis: .vertical
                    )
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
                .disabled(!canSubmit || isGenerating)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(Color.appBackground)
    }

    private var canSubmit: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submitInput() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        generationError = nil
        generatedPrompt = ""
        isGenerating = true

        let category = selectedType?.label
        openAIService.generatePrompt(prompt: text, category: category) { result in
            isGenerating = false
            switch result {
            case .success(let response):
                if !response.error.isEmpty {
                    generationError = response.error
                    return
                }
                generatedPrompt = response.generated_prompt
                if generatedPrompt.isEmpty {
                    generationError = String(localized: "No prompt was generated.")
                }
            case .failure(let err):
                generationError = err.localizedDescription
            }
        }
    }
}
