import Foundation

/// How a remote onboarding carousel item should be rendered.
enum OnboardingV3MediaType: String, Codable, Hashable, Sendable {
    case image
    case video
}

/// One carousel slide: either a catalog image (`imageAssetName`) or `url` (bundle file or remote image/video).
struct OnboardingV3ContentItem: Identifiable, Hashable, Sendable {
    let id: String
    let type: OnboardingV3MediaType
    /// Remote image or video. Required for `.video`; for `.image` omit when using `imageAssetName`.
    let url: URL?
    /// Name of an imageset in `Assets.xcassets` (e.g. `"5"` for `5.imageset`).
    let imageAssetName: String?

    /// Image from the asset catalog.
    init(id: String = UUID().uuidString, imageAssetName: String) {
        self.id = id
        self.type = .image
        self.imageAssetName = imageAssetName
        self.url = nil
    }

    /// Remote image or video URL.
    init(id: String = UUID().uuidString, url: URL, type: OnboardingV3MediaType) {
        self.id = id
        self.type = type
        self.url = url
        self.imageAssetName = nil
    }
}

/// A single onboarding screen: headline, body copy, and scrollable media.
struct OnboardingV3Step: Identifiable, Hashable, Sendable {
    let id: String
    var title: String
    /// Substring within `title` that receives the accent gradient. If `nil` or not found, the full title uses default styling.
    var titleEmphasis: String?
    var subtitle: String
    var contents: [OnboardingV3ContentItem]

    init(
        id: String = UUID().uuidString,
        title: String,
        titleEmphasis: String? = nil,
        subtitle: String,
        contents: [OnboardingV3ContentItem],
    ) {
        self.id = id
        self.title = title
        self.titleEmphasis = titleEmphasis
        self.subtitle = subtitle
        self.contents = contents
    }
}

extension OnboardingV3Step {
    /// Default onboarding: carousels, then a bundled-video “Get inspired” step.
    static let defaultFlow: [OnboardingV3Step] = [
        defaultGemini,
        styleAppliedInSeconds,
        wordsPlacedJustRight,
        getInspired
    ]

    /// Third screen: text placement ("Your words, placed just right.").
    /// Uses `onb1`…`onb3` from Assets by default; swap `imageAssetName` to your own imagesets (e.g. `11`…`13`) when added.
    static let wordsPlacedJustRight = OnboardingV3Step(
        id: "onboarding-v3-text-placement",
        title: "Your words, placed just right.",
        titleEmphasis: "Your words",
        subtitle: "Create logos, invites, posters, comics and whatever else you need with clear text. Words fit right into your creation, in many languages.",
        contents: [
            OnboardingV3ContentItem(id: "words-2", imageAssetName: "12"),
            OnboardingV3ContentItem(id: "words-3", imageAssetName: "13"),
            OnboardingV3ContentItem(id: "words-4", imageAssetName: "14"),
            OnboardingV3ContentItem(id: "words-5", imageAssetName: "15")
        ]
    )

    /// Last screen: muted looping videos from `AI Image Generator/Videos/16.mp4`…`19.mp4` (copied into the app bundle as `16.mp4`…`19.mp4`).
    static let getInspired = OnboardingV3Step(
        id: "onboarding-v3-get-inspired",
        title: "Get inspired: Nano Banana",
        titleEmphasis: "Nano Banana",
        subtitle: "Take a look at these fun ways that people are using Nano Banana on Gemini to reimagine their photos.",
        contents: [
            OnboardingV3ContentItem(id: "inspire-1", url: bundledOnboardingVideoURL(fileStem: "16"), type: .video),
            OnboardingV3ContentItem(id: "inspire-2", url: bundledOnboardingVideoURL(fileStem: "17"), type: .video),
            OnboardingV3ContentItem(id: "inspire-3", url: bundledOnboardingVideoURL(fileStem: "18"), type: .video),
            OnboardingV3ContentItem(id: "inspire-4", url: bundledOnboardingVideoURL(fileStem: "19"), type: .video),
        ],
    )

    /// `fileStem` is the name without extension (e.g. `"16"`). Source files live in `AI Image Generator/Videos/`; the synchronized app target copies them into the bundle root.
    fileprivate static func bundledOnboardingVideoURL(fileStem: String) -> URL {
        guard let url = Bundle.main.url(forResource: fileStem, withExtension: "mp4") else {
            fatalError(
                "Missing onboarding video \(fileStem).mp4 in the app bundle. Add `AI Image Generator/Videos/\(fileStem).mp4` and ensure the Videos folder stays in the app target."
            )
        }
        return url
    }

    /// Second screen: "Style applied in seconds."
    static let styleAppliedInSeconds = OnboardingV3Step(
        id: "onboarding-v3-style-reference",
        title: "Style applied in seconds.",
        titleEmphasis: "Style",
        subtitle: "Transform your image using any reference photo's texture, color, or style — no starting from scratch required.",
        contents: [
            OnboardingV3ContentItem(id: "style-1", imageAssetName: "1 1"),
            OnboardingV3ContentItem(id: "style-2", imageAssetName: "2"),
            OnboardingV3ContentItem(id: "style-3", imageAssetName: "3"),
            OnboardingV3ContentItem(id: "style-4", imageAssetName: "4")
        ]
    )

    /// Default first step used when only a single step is passed.
    static let defaultGemini = OnboardingV3Step(
        id: "onboarding-v3-default",
        title: "Dial in every detail with Nano Banana.",
        titleEmphasis: "every detail",
        subtitle: "Transform your image's vibe — shift the lighting, angle, and focus to make your subject pop.",
        contents: [
            OnboardingV3ContentItem(id: "c1", imageAssetName: "5"),
            OnboardingV3ContentItem(id: "c2", imageAssetName: "6"),
            OnboardingV3ContentItem(id: "c3", imageAssetName: "7"),
            OnboardingV3ContentItem(id: "c4", imageAssetName: "8"),
            OnboardingV3ContentItem(id: "c5", imageAssetName: "9"),
            OnboardingV3ContentItem(id: "c6", imageAssetName: "10")
        ]
    )
}
