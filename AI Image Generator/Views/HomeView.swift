import SwiftUI

// MARK: - Tool Example Model

struct ToolExample: Identifiable, Hashable {
    let id = UUID()
    let name: String
    /// Prompt pre-completat în CreateView când se apasă cardul.
    let prompt: String
    let credits: Int
    /// Placeholder colors până când imaginile "before/after" sunt încărcate real.
    let beforeGradient: [Color]
    let afterGradient: [Color]
    /// Numele asset-urilor din Assets.xcassets. Dacă sunt setate, se afișează în locul gradientelor.
    let beforeImage: String?
    let afterImage: String?

    init(
        name: String,
        prompt: String,
        credits: Int,
        beforeGradient: [Color],
        afterGradient: [Color],
        beforeImage: String? = nil,
        afterImage: String? = nil
    ) {
        self.name = name
        self.prompt = prompt
        self.credits = credits
        self.beforeGradient = beforeGradient
        self.afterGradient = afterGradient
        self.beforeImage = beforeImage
        self.afterImage = afterImage
    }
}

extension ToolExample {
    static let defaults: [ToolExample] = [
        ToolExample(
            name: String(localized: "Change background"),
            prompt: "replace the background with a scenic tropical beach at sunset",
            credits: 10,
            beforeGradient: [Color(hex: "3E3833"), Color(hex: "1C1915")],
            afterGradient: [Color(hex: "6B5A3B"), Color(hex: "241E14")],
            beforeImage: "tool_change_bg_before",
            afterImage: "tool_change_bg_after"
        ),
        ToolExample(
            name: String(localized: "Beautify"),
            prompt: "beautify the person in this photo with natural skin retouching, brighter eyes and a healthy glow — keep it realistic, not overly filtered",
            credits: 5,
            beforeGradient: [Color(hex: "2C2A26"), Color(hex: "141210")],
            afterGradient: [Color(hex: "5F5340"), Color(hex: "1E1A14")],
            beforeImage: "tool_beautify_before",
            afterImage: "tool_beautify_after"
        ),
        // DISABLED: Restore old photo — assets & prompt salvate în
        // ui-redesign/disabled-tools/restore-old-photo/ (vezi README.md acolo)
        // ToolExample(
        //     name: String(localized: "Restore old photo"),
        //     prompt: "restore this old damaged photo",
        //     credits: 10,
        //     beforeGradient: [Color(hex: "3B342C"), Color(hex: "17140F")],
        //     afterGradient: [Color(hex: "5A4A32"), Color(hex: "1B1710")],
        //     beforeImage: "tool_restore_photo_before",
        //     afterImage: "tool_restore_photo_after"
        // ),
        // Row 2 — cross alternation (WHITE | RED) — Erase left, Change outfit right
        ToolExample(
            name: String(localized: "Erase an object"),
            prompt: "erase the distracting objects from this photo, seamlessly reconstruct the background",
            credits: 10,
            beforeGradient: [Color(hex: "34302B"), Color(hex: "15130F")],
            afterGradient: [Color(hex: "544738"), Color(hex: "1A1610")],
            beforeImage: "tool_erase_object_before",
            afterImage: "tool_erase_object_after"
        ),
        ToolExample(
            name: String(localized: "Change outfit"),
            prompt: "change the outfit of the person in this photo to a different stylish clothing while keeping the same pose and identity",
            credits: 10,
            beforeGradient: [Color(hex: "2E2823"), Color(hex: "131110")],
            afterGradient: [Color(hex: "3E5140"), Color(hex: "14170F")],
            beforeImage: "tool_change_outfit_before",
            afterImage: "tool_change_outfit_after"
        ),
        // Row 3
        ToolExample(
            name: String(localized: "Muscle boost"),
            prompt: "boost the muscle definition in this photo — give the person a ripped fitness model physique with defined pecs, abs, arms and shoulders, while keeping the exact same face, pose and framing",
            credits: 10,
            beforeGradient: [Color(hex: "2F2A25"), Color(hex: "131110")],
            afterGradient: [Color(hex: "5B4D3A"), Color(hex: "1A1610")],
            beforeImage: "tool_muscle_boost_before",
            afterImage: "tool_muscle_boost_after"
        ),
        ToolExample(
            name: String(localized: "Glow up"),
            prompt: "give the people in this photo an ultimate luxury lifestyle glow up — elegant outfits, expensive jewelry and watches, upscale background, keep their identities",
            credits: 10,
            beforeGradient: [Color(hex: "2A2620"), Color(hex: "13110F")],
            afterGradient: [Color(hex: "5E4D34"), Color(hex: "1B1610")],
            beforeImage: "tool_glow_up_before",
            afterImage: "tool_glow_up_after"
        )
    ]
}

// MARK: - Home View

struct HomeView: View {
    @Binding var initialPromptFromDiscover: String?
    @Binding var selectedTab: MainTab

    @StateObject private var subscriptionService = SubscriptionService.shared

    @State private var pendingPrompt: String? = nil
    @State private var pendingTool: ToolExample? = nil
    @State private var showCreate = false
    @State private var showAllTools = false

    private let tools: [ToolExample] = ToolExample.defaults

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        titleSection
                            .padding(.horizontal, 18)
                            .padding(.top, 4)

                        toolsGrid
                            .padding(.horizontal, 18)

                        describeAnythingCard
                            .padding(.horizontal, 18)
                            .padding(.top, 4)
                    }
                    .padding(.bottom, 24)
                }
            }
            .background(Color.appBackground)
            .navigationDestination(isPresented: $showCreate) {
                CreateView(prefilledPrompt: pendingPrompt, tool: pendingTool, selectedTab: $selectedTab)
            }
            .onAppear {
                if let prompt = initialPromptFromDiscover, !prompt.isEmpty {
                    pendingPrompt = prompt
                    showCreate = true
                    initialPromptFromDiscover = nil
                }
            }
            .navigationDestination(isPresented: $showAllTools) {
                AllToolsPage(tools: tools, selectedTab: $selectedTab)
            }
        }
    }

    // MARK: - Header (logo + credits + Pro)

    private var header: some View {
        HStack(spacing: 5) {
            Image("Icon")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)

            Text(String(localized: "AI Image"))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appText)

            Spacer()

            HStack(spacing: 8) {
                Button {
                    subscriptionService.showShop = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "film")
                            .font(.system(size: 12, weight: .semibold))
                        Text("\(subscriptionService.credits)")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .lineLimit(1)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .foregroundStyle(Color.appAccent)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .background(Color.clear)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.appAccent.opacity(0.4), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                if !subscriptionService.isSubscribed {
                    Button {
                        subscriptionService.showPaywall = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "mountain.2.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text(String(localized: "Pro"))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .lineLimit(1)
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        .foregroundStyle(Color(hex: "221B04"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "FFD75E"), Color(hex: "EFAF0C")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .layoutPriority(1)
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(Color.appBackground)
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "See the difference first"))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .firstTextBaseline) {
                Text(String(localized: "Tap an example to run it on your photo"))
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(Color(hex: "8F897D"))
                Spacer(minLength: 8)
                Button {
                    showAllTools = true
                } label: {
                    Text(String(localized: "All \(tools.count)"))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.appAccent)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Tools Grid

    private var toolsGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 14) {
            ForEach(tools) { tool in
                ToolCard(tool: tool) {
                    pendingTool = tool
                    pendingPrompt = nil
                    showCreate = true
                }
            }
        }
    }

    // MARK: - Create button (large yellow CTA)

    private var describeAnythingCard: some View {
        Button {
            pendingPrompt = nil
            pendingTool = nil
            showCreate = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .heavy))
                Text(String(localized: "Create"))
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(Color(hex: "141210"))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    colors: [Color(hex: "FFD75E"), Color(hex: "EFAF0C")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 25))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tool Card

private struct ToolCard: View {
    let tool: ToolExample
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                BeforeAfterSlider(
                    beforeGradient: tool.beforeGradient,
                    afterGradient: tool.afterGradient,
                    beforeImage: tool.beforeImage,
                    afterImage: tool.afterImage
                )
                .frame(height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Text(tool.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.appText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 2)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Before / After Slider

private struct BeforeAfterSlider: View {
    let beforeGradient: [Color]
    let afterGradient: [Color]
    var beforeImage: String? = nil
    var afterImage: String? = nil

    @State private var sliderFraction: CGFloat = 0.5
    private let handleSize: CGFloat = 26

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let dividerX = max(handleSize / 2, min(width - handleSize / 2, width * sliderFraction))

            ZStack(alignment: .topLeading) {
                // Right / After background — always full width, revealed on the right.
                halfContent(
                    imageName: afterImage,
                    label: String(localized: "After"),
                    gradient: afterGradient
                )
                .frame(width: width, height: height)

                // Left / Before — clipped to divider position.
                halfContent(
                    imageName: beforeImage,
                    label: String(localized: "Before"),
                    gradient: beforeGradient
                )
                .frame(width: width, height: height)
                .mask(
                    HStack(spacing: 0) {
                        Rectangle().frame(width: dividerX)
                        Color.clear
                    }
                )

                // Divider line
                Rectangle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 2, height: height)
                    .position(x: dividerX, y: height / 2)

                // Draggable handle
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: handleSize, height: handleSize)
                        .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)

                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 8, weight: .heavy))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .heavy))
                    }
                    .foregroundStyle(Color(hex: "141210"))
                }
                .position(x: dividerX, y: height / 2)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newX = min(max(0, value.location.x), width)
                            sliderFraction = newX / max(width, 1)
                        }
                )
            }
            .contentShape(Rectangle())
        }
        .onAppear {
            sliderFraction = 0.5
        }
    }

    @ViewBuilder
    private func halfContent(imageName: String?, label: String, gradient: [Color]) -> some View {
        if let imageName, UIImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            ZStack {
                LinearGradient(
                    colors: gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 5) {
                    Image(systemName: "photo")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.35))
                    Text(label)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.75))
                    Text(String(localized: "or browse files"))
                        .font(.system(size: 10.5, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .underline()
                }
            }
        }
    }
}

// MARK: - All Tools Page (pushed into NavigationStack)

private struct AllToolsPage: View {
    let tools: [ToolExample]
    @Binding var selectedTab: MainTab
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 26) {
                ForEach(tools) { tool in
                    NavigationLink {
                        CreateView(tool: tool, selectedTab: $selectedTab)
                    } label: {
                        AllToolsRow(tool: tool)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color.appBackground)
        .navigationTitle(String(localized: "All tools"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.appText)
                        .frame(width: 34, height: 34)
                        .background(Color(hex: "17150F"))
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - All Tools Row — Before + After stacked full-size

private struct AllToolsRow: View {
    let tool: ToolExample

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(tool.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "8F897D"))
            }

            HStack(spacing: 10) {
                labeledImage(
                    imageName: tool.beforeImage,
                    gradient: tool.beforeGradient,
                    label: String(localized: "Before")
                )
                labeledImage(
                    imageName: tool.afterImage,
                    gradient: tool.afterGradient,
                    label: String(localized: "After")
                )
            }
        }
    }

    @ViewBuilder
    private func labeledImage(imageName: String?, gradient: [Color], label: String) -> some View {
        ZStack(alignment: .topLeading) {
            Group {
                if let imageName, UIImage(named: imageName) != nil {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 26))
                            .foregroundStyle(Color.white.opacity(0.35))
                    )
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.55))
                .clipShape(Capsule())
                .padding(10)
        }
    }
}
