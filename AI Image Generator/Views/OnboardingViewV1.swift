import SwiftUI
import StoreKit

struct OnboardingInfo {
    let imageAsset: String
    let title: String
    let subtitle: String
}

struct OnboardingViewV1: View {
    let onFinished: () -> Void
    
    @StateObject private var apiService = GeminiAPIService.shared
    @State private var currentPage = 0
    @Environment(\.requestReview) var requestReview
    
    let onboardingPages = [
        OnboardingInfo(
            imageAsset: "onb1",
            title: "Smart Background Eraser",
            subtitle: "Quickly cut out and swap photo backdrops with high-accuracy AI editing."
        ),
        OnboardingInfo(
            imageAsset: "onb2",
            title: "AI Figure Generator",
            subtitle: "Reimagine yourself as collectible dolls or action figures using trendy AI-generated looks made for sharing."
        ),
        OnboardingInfo(
            imageAsset: "onb3",
            title: "AI Photo Restoration",
            subtitle: "Revive old faded pictures by restoring details and bringing memories back to life."
        ),
        OnboardingInfo(
            imageAsset: "onb4",
            title: "Cartoon & Anime Filter",
            subtitle: "Instantly convert your photos into vibrant cartoon or anime-inspired artwork."
        )
    ]
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(.all)
            
            TabView(selection: $currentPage) {
                ForEach(0..<onboardingPages.count, id: \.self) { index in
                    let page = onboardingPages[index]
                    
                    ZStack(alignment: .top) {
                        VStack(spacing: 0) {
                            ZStack(alignment: .bottom) {
                                Image(page.imageAsset)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.75)
                                    .clipped()
                                
                                LinearGradient(
                                    colors: [
                                        Color.black,
                                        Color.black.opacity(0.95),
                                        Color.black.opacity(0.7),
                                        Color.black.opacity(0.4),
                                        Color.black.opacity(0)
                                    ],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                                .frame(height: UIScreen.main.bounds.height * 0.4)
                            }
                            
                            Spacer()
                        }
                        .ignoresSafeArea()
                        
                        VStack(spacing: 0) {
                            Spacer()
                                .frame(height: UIScreen.main.bounds.height * 0.55)
                            
                            VStack(spacing: 10) {
                                Text(page.title.localized)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 30)
                                
                                Text(page.subtitle.localized)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 30)
                                    .lineSpacing(4)
                            }
                            
                            Spacer()
                        }
                        .padding(.bottom, 120)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .ignoresSafeArea()
            .onAppear(perform: {
                UIScrollView.appearance().isScrollEnabled = false
            })
            
            // Bottom controls overlay
            VStack {
                Spacer()
                
                VStack(spacing: 20) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<onboardingPages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.white : Color.white.opacity(0.4))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                    }
                    
                    // Continue button
                    Button(action: {
                        // Add haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        if currentPage < onboardingPages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            requestReview()
                            onFinished()
                        }
                    }) {
                        Text(currentPage == onboardingPages.count - 1 ? String(localized: "Get Started") : String(localized: "Continue"))
                            .font(.system(size: 18, weight: .semibold))
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(Color(red: 0.95, green: 0.85, blue: 0.3))
                            )
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 50)
            }
        }
        .ignoresSafeArea()
    }
}
