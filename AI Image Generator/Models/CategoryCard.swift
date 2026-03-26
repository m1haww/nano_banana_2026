import Foundation

struct CategoryCard: Codable, Identifiable {
    let imageURL: String
    let category: String
    let subtitle: String

    var id: String { imageURL + category + subtitle }

    private enum CodingKeys: String, CodingKey {
        case imageURL = "image_url"
        case image
        case category
        case subtitle
    }

    init(imageURL: String, category: String, subtitle: String) {
        self.imageURL = imageURL
        self.category = category
        self.subtitle = subtitle
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
            ?? container.decode(String.self, forKey: .image)
        category = try container.decode(String.self, forKey: .category)
        subtitle = try container.decode(String.self, forKey: .subtitle)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(imageURL, forKey: .imageURL)
        try container.encode(category, forKey: .category)
        try container.encode(subtitle, forKey: .subtitle)
    }
}

extension CategoryCard {
    static let homeCards: [CategoryCard] = [
        CategoryCard(imageURL: "https://www.img2go.com/assets/blog/Art_Styles.jpg", category: "Art", subtitle: "Generate art-style images"),
        CategoryCard(imageURL: "https://img.freepik.com/free-photo/nature-sunset-tranquil-meadow-rural-scene-beauty-generative-ai_188544-15462.jpg?semt=ais_hybrid&w=740&q=80", category: "Nature", subtitle: "Landscapes, animals, plants"),
        CategoryCard(imageURL: "https://nc-cdn.rockhr.ai/visualgpt/static/ai-portrait-generator/style-business-portrait-female.jpeg", category: "Portrait", subtitle: "People and characters"),
        CategoryCard(imageURL: "https://cdn.cgdream.ai/_next/image?url=https%3A%2F%2Fapi.cgdream.ai%2Frails%2Factive_storage%2Fblobs%2Fredirect%2FeyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBL2lRcEE9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ%3D%3D--bc2f383c1dcc3b9f24840fd033a4be4df42817e3%2F8654d399-8381-49e3-be23-9e4639125434_0.png&w=1920&q=95", category: "Fantasy", subtitle: "Magic, creatures, worlds"),
        CategoryCard(imageURL: "https://images.adsttc.com/media/images/633d/4c64/dd0b/8954/dd1d/630a/newsletter/new-ai-image-generator-can-help-users-redesign-their-own-spaces_5.jpg?1664961650", category: "Minimal", subtitle: "Clean and simple visuals")
    ]
}
