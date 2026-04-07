import SwiftUI

/// Pagină Result: imagine generată, Style / Atmosphere / Aspect Ratio, Edit Prompt, Re-generate, Share, Download.
struct ResultView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage
    @Binding var prompt: String
    let initialAspectRatio: String
    let onFinalize: () -> Void
    let onReGenerate: () -> Void
    let onShare: () -> Void
    let onDownload: () -> Void

    @State private var editPromptText: String = ""
    @State private var selectedStyle: String
    @State private var selectedAtmosphere: String
    @State private var selectedAspectRatio: String

    private let styleOptions = ["Hyper Realistic", "Anime", "Concept Art", "Minimal", "Fantasy"]
    private let atmosphereOptions = ["Mystical", "Dark", "Bright", "Natural", "Dramatic", "Soft"]

    init(image: UIImage, prompt: Binding<String>, initialAspectRatio: String, onFinalize: @escaping () -> Void, onReGenerate: @escaping () -> Void, onShare: @escaping () -> Void, onDownload: @escaping () -> Void) {
        self.image = image
        _prompt = prompt
        self.initialAspectRatio = initialAspectRatio
        self.onFinalize = onFinalize
        self.onReGenerate = onReGenerate
        self.onShare = onShare
        self.onDownload = onDownload
        _selectedStyle = State(initialValue: "Hyper Realistic")
        _selectedAtmosphere = State(initialValue: "Mystical")
        _selectedAspectRatio = State(initialValue: initialAspectRatio)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    imageSection
                    dropdownsSection
                    editPromptSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            bottomActions
        }
        .background(Color.appBackground)
        .onAppear { editPromptText = prompt }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.appText)
            }
            Spacer()
            Text(String(localized: "Result"))
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.appText)
            Spacer()
            Button {
                prompt = editPromptText
                onFinalize()
                dismiss()
            } label: {
                Text(String(localized: "Finalize"))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.appAccent)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.appBackground)
    }

    private var imageSection: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.top, 8)
    }

    private var dropdownsSection: some View {
        HStack(spacing: 10) {
            dropdownMenu(title: String(localized: "Style"), value: $selectedStyle, options: styleOptions)
            dropdownMenu(title: String(localized: "Atmosphere"), value: $selectedAtmosphere, options: atmosphereOptions)
            dropdownMenu(title: String(localized: "Aspect Ratio"), value: $selectedAspectRatio, options: AspectRatioOption.allCases.map(\.rawValue))
        }
    }

    private func dropdownMenu(title: String, value: Binding<String>, options: [String]) -> some View {
        Menu {
            ForEach(options, id: \.self) { opt in
                Button(opt.localized) { value.wrappedValue = opt }
            }
        } label: {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.appTextSecondary)
                Text(truncatedLocalizedSelection(value.wrappedValue))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.appText)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.appPromptBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func truncatedLocalizedSelection(_ raw: String) -> String {
        let loc = raw.localized
        if loc.count > 8 {
            return String(loc.prefix(8)) + "…"
        }
        return loc
    }

    private var editPromptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(String(localized: "Edit Prompt"))
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.appText)
                Spacer()
                Button {
                    prompt = editPromptText
                    dismiss()
                    onReGenerate()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14))
                        Text(String(localized: "Re-generate"))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Color.appAccent)
                }
            }
            TextEditor(text: $editPromptText)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(Color.appText)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80)
                .padding(12)
                .background(Color.appPromptBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appDivider, lineWidth: 1)
                )
        }
    }

    private var bottomActions: some View {
        HStack(spacing: 12) {
            Button(action: onShare) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18))
                    Text(String(localized: "Share"))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Color.appText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.appPromptBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            Button(action: onDownload) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 18))
                    Text(String(localized: "Download"))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.appAccent, Color.appAccentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.appBackground)
    }
}
