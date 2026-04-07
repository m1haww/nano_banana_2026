import SwiftUI

/// Full-screen overlay while `createImage` runs (TimelineView ring so parent animations don’t stall it).
struct GenerationLoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()

            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "3B3228").opacity(0.92),
                            Color(hex: "2A231B").opacity(0.9),
                            Color(hex: "1E1A14").opacity(0.88),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 280, height: 240)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.black.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.appAccent.opacity(0.85),
                                    Color.appAccentSecondary.opacity(0.5),
                                    Color.appAccent.opacity(0.85),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: Color.appAccent.opacity(0.35), radius: 24, y: 10)

            VStack(spacing: 22) {
                TimelineView(.animation(minimumInterval: 1 / 60, paused: false)) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    let pulseScale = 0.94 + 0.18 * (0.5 + 0.5 * sin(t * 2.35))
                    let ringRotation = (t * 200).truncatingRemainder(dividingBy: 360)

                    ZStack {
                        Circle()
                            .stroke(Color.appAccent.opacity(0.22), lineWidth: 2)
                            .frame(width: 112, height: 112)
                            .scaleEffect(pulseScale)

                        Circle()
                            .trim(from: 0.12, to: 0.92)
                            .stroke(
                                AngularGradient(
                                    colors: [
                                        Color.appAccent,
                                        Color.appAccentSecondary,
                                        Color.appAccent.opacity(0.3),
                                        Color.appAccent,
                                    ],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 96, height: 96)
                            .rotationEffect(.degrees(ringRotation))

                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 34, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.appAccent, Color.appAccentSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }

                VStack(spacing: 6) {
                    Text(String(localized: "Creating your image"))
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.appText)
                    Text(String(localized: "Hang tight — this usually takes a few seconds."))
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: 280)
            }
        }
    }
}
