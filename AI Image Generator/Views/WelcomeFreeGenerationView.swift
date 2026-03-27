//import SwiftUI
//
//struct WelcomeFreeGenerationView: View {
//    var onFinished: () -> Void
//
//    @StateObject private var viewModel = CreateViewModel()
//    @State private var showResult = false
//    @State private var showError = false
//    @State private var errorMessage = ""
//    @State private var showSaveConfirmation = false
//    @FocusState private var promptFocused: Bool
//
//    private var alertTint: Color {
//        if showError || showSaveConfirmation { return .black }
//        return Color.appAccent
//    }
//
//    var body: some View {
//        ZStack {
//            Color.appBackground.ignoresSafeArea()
//
//            ScrollView(showsIndicators: false) {
//                HStack {
//                    Spacer()
//                    Button("Skip") {
//                        onFinished()
//                    }
//                    .font(.system(size: 16, weight: .medium, design: .rounded))
//                    .foregroundStyle(Color.appTextSecondary)
//                }
//                .padding(.top, 24)
//                .padding(.horizontal, 20)
//                
//                VStack(alignment: .leading, spacing: 22) {
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Your first image is free")
//                            .font(.system(size: 28, weight: .bold, design: .rounded))
//                            .foregroundStyle(Color.appText)
//                        Text("Try a short prompt below — 1:1 preview, then save or share from the next screen.")
//                            .font(.system(size: 16, weight: .regular, design: .rounded))
//                            .foregroundStyle(Color.appTextSecondary)
//                    }
//                    .padding(.top, 8)
//
//                    VStack(alignment: .leading, spacing: 10) {
//                        Text("Prompt")
//                            .font(.system(size: 15, weight: .semibold, design: .rounded))
//                            .foregroundStyle(Color.appText)
//
//                        ZStack(alignment: .topLeading) {
//                            TextField("", text: $viewModel.prompt, axis: .vertical)
//                                .font(.system(size: 16, weight: .regular, design: .rounded))
//                                .foregroundStyle(Color.appText)
//                                .lineLimit(4...8)
//                                .focused($promptFocused)
//
//                            if viewModel.prompt.isEmpty {
//                                Text("e.g. Minimal sunset over the ocean")
//                                    .font(.system(size: 16, weight: .regular, design: .rounded))
//                                    .foregroundStyle(Color.white.opacity(0.5))
//                                    .allowsHitTesting(false)
//                            }
//                        }
//                        .padding(14)
//                        .background(Color.appPromptBackground)
//                        .clipShape(RoundedRectangle(cornerRadius: 14))
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 14)
//                                .stroke(Color.appDivider, lineWidth: 1)
//                        )
//                    }
//
//                    Button {
//                        promptFocused = false
//                        Task { await viewModel.generate() }
//                    } label: {
//                        HStack(spacing: 10) {
//                            Text("Generate my free image")
//                                .font(.system(size: 17, weight: .semibold, design: .rounded))
//                            Image(systemName: "sparkles")
//                                .font(.system(size: 17, weight: .semibold))
//                        }
//                        .foregroundStyle(Color.appBackground)
//                        .frame(maxWidth: .infinity)
//                        .padding(.vertical, 16)
//                        .background(
//                            LinearGradient(
//                                colors: [Color.appAccent, Color.appAccentSecondary],
//                                startPoint: .leading,
//                                endPoint: .trailing
//                            )
//                        )
//                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
//                    }
//                    .buttonStyle(.plain)
//                    .disabled(viewModel.isGenerating)
//                    .opacity(viewModel.isGenerating ? 0.55 : 1)
//
//                    Spacer(minLength: 40)
//                }
//                .padding(.horizontal, 20)
//                .padding(.bottom, 40)
//            }
//            .onTapGesture { promptFocused = false }
//
//            if viewModel.isGenerating {
//                GenerationLoadingOverlay()
//                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
//            }
//        }
//        .tint(alertTint)
//        .onAppear {
//            viewModel.aspectRatio = "1:1"
//        }
//        .onChange(of: viewModel.errorMessage) { newValue in
//            if let msg = newValue, !msg.isEmpty {
//                errorMessage = msg
//                showError = true
//            }
//        }
//        .onChange(of: viewModel.didJustGenerate) { did in
//            if did {
//                showResult = true
//            }
//        }
//        .onChange(of: viewModel.isGenerating) { isGen in
//            if isGen {
//                showResult = false
//            }
//        }
//        .fullScreenCover(isPresented: $showResult, onDismiss: {
//            viewModel.didJustGenerate = false
//        }) {
//            if let img = viewModel.generatedImage {
//                HomeGenerationResultView(
//                    image: img,
//                    prompt: $viewModel.prompt,
//                    onShare: {
//                        ShareService.shared.present(items: [img, viewModel.prompt])
//                    },
//                    onSave: {
//                        viewModel.saveToPhotos(img)
//                        showSaveConfirmation = true
//                    },
//                    onContinueToApp: {
//                        showResult = false
//                        onFinished()
//                    }
//                )
//            }
//        }
//        .alert("Notice", isPresented: $showError) {
//            Button("OK", role: .cancel) {
//                viewModel.errorMessage = nil
//            }
//        } message: {
//            Text(errorMessage)
//        }
//        .alert("Saved", isPresented: $showSaveConfirmation) {
//            Button("OK", role: .cancel) {}
//        } message: {
//            Text("Image saved to Photos.")
//        }
//        .toolbarColorScheme(.dark, for: .navigationBar)
//        .toolbarBackground(Color.appBackground, for: .navigationBar)
//        .toolbarBackground(.visible, for: .navigationBar)
//    }
//}
