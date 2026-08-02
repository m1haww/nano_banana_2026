import SwiftUI
import PhotosUI
import UIKit
import Combine

// MARK: - Camera picker wrapper

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    let imageSource: UIImagePickerController.SourceType

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = imageSource
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Chat bubble views

private struct UserBubbleView: View {
    let text: String
    let image: UIImage?

    var body: some View {
        HStack(alignment: .bottom) {
            Spacer(minLength: 48)
            VStack(alignment: .trailing, spacing: 6) {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                if !text.isEmpty {
                    Text(text)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(Color(hex: "221B04"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "FFD75E"), Color(hex: "EFAF0C")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(BubbleShape(isUser: true))
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

private struct TypingDotsView: View {
    @State private var bouncing = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.appAccent.opacity(0.7))
                    .frame(width: 7, height: 7)
                    .offset(y: bouncing ? -5 : 0)
                    .animation(
                        .easeInOut(duration: 0.45)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.15),
                        value: bouncing
                    )
            }
        }
        .onAppear { bouncing = true }
    }
}

private struct AssistantBubbleView: View {
    let text: String
    @State private var copied = false

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                if text.isEmpty {
                    TypingDotsView()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(hex: "1F1C17"))
                        .clipShape(BubbleShape(isUser: false))
                } else {
                    Text(text)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.appText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(hex: "1F1C17"))
                        .clipShape(BubbleShape(isUser: false))

                    HStack(spacing: 8) {
                        Button {
                            UIPasteboard.general.string = text
                            copied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
                        } label: {
                            Label(copied ? String(localized: "Copied") : String(localized: "Copy"), systemImage: copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.appTextSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Color(hex: "2A2721"))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.2), value: copied)

                        Button {
                            ShareService.shared.present(items: [text])
                        } label: {
                            Label(String(localized: "Share"), systemImage: "square.and.arrow.up")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.appTextSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Color(hex: "2A2721"))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 2)
                    .padding(.leading, 4)
                }
            }
            Spacer(minLength: 48)
        }
        .padding(.horizontal, 16)
    }
}

private struct ImageGeneratingBubbleView: View {
    let prompt: String
    @State private var rotationDegrees = 0.0

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                // Icon + label area
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: "2A2520"))
                        .frame(height: 140)

                    VStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "FFD75E"), Color(hex: "EFAF0C")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .rotationEffect(.degrees(rotationDegrees))
                            .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: rotationDegrees)

                        Text(String(localized: "Generating image…"))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(hex: "FFD75E"))
                    }
                }

                // Prompt label
                Text(prompt)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.appTextSecondary.opacity(0.6))
                    .lineLimit(2)
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
            }
            .background(Color(hex: "1A1713"))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "FFD75E").opacity(0.4), Color(hex: "EFAF0C").opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .frame(maxWidth: 260)
            .onAppear {
                rotationDegrees = 360
            }

            Spacer(minLength: 48)
        }
        .padding(.horizontal, 16)
    }
}

private struct ImageReadyBubbleView: View {
    let prompt: String
    let imageURL: String

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: 260)
                            .frame(height: 260)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    case .failure:
                        Color(hex: "1F1C17")
                            .frame(width: 200, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundStyle(Color.appTextSecondary)
                            )
                    default:
                        ZStack {
                            Color(hex: "1F1C17")
                                .frame(width: 200, height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                            ProgressView().tint(Color.appAccent)
                        }
                    }
                }
            }
            Spacer(minLength: 48)
        }
        .padding(.horizontal, 16)
    }
}

private struct ImageFailedBubbleView: View {
    let prompt: String

    var body: some View {
        HStack(alignment: .bottom) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red.opacity(0.8))
                Text(String(localized: "Image generation failed"))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(hex: "1F1C17"))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            Spacer(minLength: 48)
        }
        .padding(.horizontal, 16)
    }
}

// Tail-shaped bubble
private struct BubbleShape: Shape {
    let isUser: Bool
    func path(in rect: CGRect) -> Path {
        let r: CGFloat = 18
        var path = Path()
        if isUser {
            path.addRoundedRect(in: rect, cornerSize: CGSize(width: r, height: r))
        } else {
            path.addRoundedRect(in: rect, cornerSize: CGSize(width: r, height: r))
        }
        return path
    }
}

// MARK: - Attached image preview

private struct AttachedImagePreview: View {
    let image: UIImage
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
            }
            .offset(x: 6, y: -6)
        }
    }
}

// MARK: - Aspect ratio sheet

private struct AspectRatioSheet: View {
    @Binding var aspectRatio: AspectRatioOption
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: [
                    GridItem(.flexible()), GridItem(.flexible()),
                    GridItem(.flexible()), GridItem(.flexible())
                ], spacing: 10) {
                    ForEach(AspectRatioOption.allCases, id: \.self) { ratio in
                        Button {
                            aspectRatio = ratio
                            dismiss()
                        } label: {
                            VStack(spacing: 6) {
                                AspectRatioChipShape(ratioString: ratio.rawValue)
                                    .foregroundStyle(aspectRatio == ratio ? Color(hex: "221B04") : Color.appAccent)
                                Text(ratio.rawValue)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(aspectRatio == ratio ? Color(hex: "221B04") : Color.appAccent)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                aspectRatio == ratio
                                ? AnyShapeStyle(LinearGradient(colors: [Color(hex: "FFD75E"), Color(hex: "EFAF0C")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                : AnyShapeStyle(Color(hex: "1F1C17"))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(aspectRatio == ratio ? Color.clear : Color.appAccent.opacity(0.25), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(18)
            }
            .background(Color.appBackground)
            .navigationTitle(String(localized: "Aspect Ratio"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Done")) { dismiss() }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.appAccent)
                }
            }
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .backgroundStyle(Color.appBackground)
    }
}

// MARK: - Resolution sheet

private struct ResolutionSheet: View {
    @Binding var resolution: ResolutionOption
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ForEach(ResolutionOption.allCases, id: \.self) { res in
                    Button {
                        resolution = res
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(res.rawValue)
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundStyle(resolution == res ? Color(hex: "221B04") : Color.appText)
                                Text("\(res.creditCost) credits per image")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundStyle(resolution == res ? Color(hex: "221B04").opacity(0.7) : Color.appTextSecondary)
                            }
                            Spacer()
                            if resolution == res {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color(hex: "221B04"))
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background(
                            resolution == res
                            ? AnyShapeStyle(LinearGradient(colors: [Color(hex: "FFD75E"), Color(hex: "EFAF0C")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            : AnyShapeStyle(Color(hex: "1F1C17"))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(resolution == res ? Color.clear : Color.appAccent.opacity(0.25), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(18)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Color.appBackground)
            .navigationTitle(String(localized: "Resolution"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Done")) { dismiss() }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.appAccent)
                }
            }
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.visible)
        .backgroundStyle(Color.appBackground)
    }
}

// Mini shape preview inside the sheet grid
private struct AspectRatioChipShape: View {
    let ratioString: String
    private let maxSize: CGFloat = 28
    private let strokeWidth: CGFloat = 2

    private var parsed: (Int, Int) {
        let p = ratioString.split(separator: ":")
        guard p.count == 2, let a = Int(p[0]), let b = Int(p[1]), a > 0, b > 0 else { return (1, 1) }
        return (a, b)
    }
    private var w: CGFloat {
        let (a, b) = parsed
        return a >= b ? maxSize : maxSize * CGFloat(a) / CGFloat(b)
    }
    private var h: CGFloat {
        let (a, b) = parsed
        return b >= a ? maxSize : maxSize * CGFloat(b) / CGFloat(a)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(lineWidth: strokeWidth)
            .frame(width: w, height: h)
            .frame(width: maxSize, height: maxSize)
    }
}

// MARK: - Empty state

private struct ChatEmptyStateView: View {
    @State private var glowPulse = false

    private let suggestions: [(icon: String, text: String)] = [
        ("photo.on.rectangle", "Generate an image from a description"),
        ("wand.and.stars", "Transform a photo you upload"),
        ("bubble.left.and.bubble.right", "Ask me anything")
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "FFD75E").opacity(glowPulse ? 0.18 : 0.08), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: glowPulse)

                Image("Icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            // Title + subtitle
            VStack(spacing: 8) {
                Text("Nano Banana AI")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FFD75E"), Color(hex: "EFAF0C")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("Your creative AI assistant")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.appTextSecondary)
            }

            // Suggestion chips
            VStack(spacing: 10) {
                ForEach(suggestions, id: \.text) { s in
                    HStack(spacing: 12) {
                        Image(systemName: s.icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.appAccent)
                            .frame(width: 32, height: 32)
                            .background(Color.appAccent.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        Text(s.text)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.appText.opacity(0.75))

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(hex: "1A1713"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.appAccent.opacity(0.12), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .onAppear {
            glowPulse = true
        }
    }
}

// MARK: - ChatView

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var inputFocused: Bool

    @State private var showAspectRatioSheet = false
    @State private var showResolutionSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        if viewModel.bubbles.isEmpty {
                            GeometryReader { geo in
                                ChatEmptyStateView()
                                    .frame(width: geo.size.width, height: geo.size.height)
                            }
                            .frame(height: UIScreen.main.bounds.height * 0.65)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.bubbles) { bubble in
                                    bubbleView(for: bubble)
                                        .id(bubble.id)
                                }
                            }
                            .padding(.vertical, 16)
                        }
                    }
                    .onChange(of: viewModel.bubbles.count) { _ in
                        if let last = viewModel.bubbles.last {
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider().background(Color.appDivider)

                // Input bar
                inputBar
            }
            .background(Color.appBackground)
            .navigationTitle(String(localized: "Chat"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showAspectRatioSheet = true
                    } label: {
                        Text(viewModel.aspectRatio.rawValue)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.appAccent)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(Color.appAccent.opacity(0.1))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.appAccent.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showResolutionSheet = true
                    } label: {
                        Text(viewModel.resolution.rawValue)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.appAccent)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(Color.appAccent.opacity(0.1))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.appAccent.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePicker(image: $viewModel.attachedImage, imageSource: viewModel.imageSourceType ?? .camera)
        }
        .sheet(isPresented: $showAspectRatioSheet) {
            AspectRatioSheet(aspectRatio: $viewModel.aspectRatio)
        }
        .sheet(isPresented: $showResolutionSheet) {
            ResolutionSheet(resolution: $viewModel.resolution)
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func bubbleView(for bubble: ChatBubble) -> some View {
        switch bubble {
        case .user(_, let text, let image):
            UserBubbleView(text: text, image: image)
        case .assistant(_, let text):
            AssistantBubbleView(text: text)
        case .imageGenerating(_, let prompt):
            ImageGeneratingBubbleView(prompt: prompt)
        case .imageReady(_, let prompt, let url):
            ImageReadyBubbleView(prompt: prompt, imageURL: url)
        case .imageFailed(_, let prompt):
            ImageFailedBubbleView(prompt: prompt)
        }
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            // The whole input field is one rounded container
            VStack(alignment: .leading, spacing: 0) {
                // Attached image preview inside the field
                if let attached = viewModel.attachedImage {
                    HStack {
                        AttachedImagePreview(image: attached) {
                            viewModel.attachedImage = nil
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 10)
                }

                // Placeholder + TextEditor stacked
                ZStack(alignment: .topLeading) {
                    if viewModel.inputText.isEmpty {
                        Text(String(localized: "Ask anything or describe an image…"))
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundStyle(Color(hex: "8F897D"))
                            .allowsHitTesting(false)
                            .padding(.horizontal, 14)
                            .padding(.top, 10)
                    }
                    TextEditor(text: $viewModel.inputText)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.appText)
                        .scrollContentBackground(.hidden)
                        .frame(height: 62)
                        .padding(.horizontal, 10)
                        .padding(.top, 4)
                        .focused($inputFocused)
                        .onSubmit {
                            inputFocused = false
                            viewModel.send()
                        }
                }

                // Bottom row — attach left, send right
                HStack(alignment: .center) {
                    // Attach button
                    Menu {
                        Button {
                            viewModel.imageSourceType = .photoLibrary
                            viewModel.showImagePicker = true
                        } label: {
                            Label(String(localized: "Photo Library"), systemImage: "photo.on.rectangle.angled")
                        }
                        Button {
                            viewModel.imageSourceType = .camera
                            viewModel.showImagePicker = true
                        } label: {
                            Label(String(localized: "Camera"), systemImage: "camera.fill")
                        }
                    } label: {
                        Image(systemName: "paperclip")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.appAccent)
                            .frame(width: 34, height: 34)
                            .background(Color.appAccent.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Send button
                    let canSend = !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                  || viewModel.attachedImage != nil
                    Button {
                        inputFocused = false
                        viewModel.send()
                    } label: {
                        Group {
                            if viewModel.isUploadingImage {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(Color(hex: "221B04"))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(canSend ? Color(hex: "221B04") : Color.appTextSecondary)
                            }
                        }
                        .frame(width: 32, height: 32)
                        .background(
                            canSend || viewModel.isUploadingImage
                            ? AnyShapeStyle(LinearGradient(colors: [Color(hex: "FFD75E"), Color(hex: "EFAF0C")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            : AnyShapeStyle(Color(hex: "2A2721"))
                        )
                        .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled((!canSend && !viewModel.isStreaming) || viewModel.isUploadingImage)
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
                .padding(.top, 4)
            }
            .background(Color(hex: "1F1C17"))
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.appAccent.opacity(inputFocused ? 0.35 : 0.12), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.appBackground)
    }
}
