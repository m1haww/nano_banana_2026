//
//  CreateView.swift
//  AI Image Generator
//

import SwiftUI
import PhotosUI

struct CreateView: View {
    @StateObject private var viewModel = CreateViewModel()
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false
    @State private var showSaveConfirmation = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @FocusState private var promptFocused: Bool

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                // Header
                VStack(spacing: 6) {
                    Text("Create")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.appText)
                    Text("Describe your image and let AI generate it")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.appTextSecondary)
                }
                .padding(.top, 20)

                // Result or placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.appPromptBackground)
                        .frame(minHeight: 220)
                        .overlay {
                            if viewModel.isGenerating {
                                VStack(spacing: 16) {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                        .tint(Color.appAccent)
                                    Text("Generating…")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundStyle(Color.appTextSecondary)
                                }
                            } else if let img = viewModel.generatedImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 48))
                                    .foregroundStyle(Color.appAccent.opacity(0.5))
                            }
                        }

                    if viewModel.generatedImage != nil && !viewModel.isGenerating {
                        VStack {
                            Spacer()
                            HStack(spacing: 12) {
                                Button {
                                    if let img = viewModel.generatedImage {
                                        viewModel.saveToPhotos(img)
                                        showSaveConfirmation = true
                                    }
                                } label: {
                                    Label("Save", systemImage: "square.and.arrow.down")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundStyle(Color.appAccent)
                                }
                                Button {
                                    if let img = viewModel.generatedImage {
                                        shareItems = [img, viewModel.prompt]
                                        showShareSheet = true
                                    }
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundStyle(Color.appAccent)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                            .padding(.bottom, 16)
                        }
                    }
                }
                .padding(.horizontal, 20)

                if let err = viewModel.errorMessage {
                    Text(err)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Prompt
                VStack(alignment: .leading, spacing: 10) {
                    Text("Prompt")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.appText)
                    TextEditor(text: $viewModel.prompt)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.appText)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 100, maxHeight: 140)
                        .padding(14)
                        .background(Color.appPromptBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.appDivider, lineWidth: 1)
                        )
                        .focused($promptFocused)
                }
                .padding(.horizontal, 20)

                // Reference image
                VStack(alignment: .leading, spacing: 10) {
                    Text("Reference image (optional)")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.appText)
                    if let ref = viewModel.referenceImage {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: ref)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            Button {
                                viewModel.clearReferenceImage()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .shadow(radius: 2)
                            }
                            .padding(8)
                        }
                        .padding(.horizontal, 20)
                    } else {
                        PhotosPicker(
                            selection: $selectedPhotoItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            HStack(spacing: 14) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.title2)
                                    .foregroundStyle(Color.appAccent)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Add reference image")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundStyle(Color.appText)
                                    Text("Optional style or subject reference")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundStyle(Color.appTextSecondary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.appAccent)
                            }
                            .padding(18)
                            .background(Color.appPromptBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.appDivider, lineWidth: 1)
                            )
                        }
                        .onChange(of: selectedPhotoItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let img = UIImage(data: data) {
                                    viewModel.setReferenceImage(img)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                // Generate button
                Button {
                    promptFocused = false
                    Task { await viewModel.generate() }
                } label: {
                    HStack(spacing: 10) {
                        if viewModel.isGenerating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        Text(viewModel.isGenerating ? "Generating…" : "Generate image")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Color.appAccent, Color.appAccentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .disabled(viewModel.isGenerating)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
        }
        .background(Color.appBackground)
        .onTapGesture { promptFocused = false }
        .sheet(isPresented: $showShareSheet) {
            if !shareItems.isEmpty {
                ShareSheet(items: shareItems)
            }
        }
        .alert("Saved", isPresented: $showSaveConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Image saved to Photos.")
        }
    }
}

// Share sheet wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    CreateView()
}
