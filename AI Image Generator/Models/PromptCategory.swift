//
//  PromptCategory.swift
//  AI Image Generator
//

import Foundation

struct PromptCategory: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    /// Emoji reprezentativ pentru card (ex: 🎨 🌿 👤)
    let emoji: String
    let prompts: [String]
}

/// Array de categorii cu prompturi exemple pentru Explore Prompts.
enum ExplorePromptsData {
    static let categories: [PromptCategory] = [
        PromptCategory(
            title: "Art & Style",
            icon: "paintbrush.fill",
            emoji: "🎨",
            prompts: [
                "Oil painting of a sunset over mountains, impressionist style",
                "Minimalist line art, single color on white",
                "Cyberpunk neon city at night, rain reflections",
                "Renaissance portrait, dramatic lighting",
                "Watercolor landscape, soft pastel colors"
            ]
        ),
        PromptCategory(
            title: "Nature",
            icon: "leaf.fill",
            emoji: "🌿",
            prompts: [
                "Dense forest with sunlight through trees",
                "Ocean waves at golden hour",
                "Snowy mountain peak at dawn",
                "Tropical beach with palm trees",
                "Northern lights over a frozen lake"
            ]
        ),
        PromptCategory(
            title: "Portrait & People",
            icon: "person.fill",
            emoji: "👤",
            prompts: [
                "Professional headshot, soft studio lighting",
                "Street photography portrait, candid moment",
                "Fantasy character with glowing eyes",
                "Vintage film photo, 1970s style",
                "Anime style portrait, detailed eyes"
            ]
        ),
        PromptCategory(
            title: "Fantasy & Concept",
            icon: "sparkles",
            emoji: "✨",
            prompts: [
                "Magical castle floating in the clouds",
                "Dragon flying over a medieval village",
                "Underwater city with bioluminescent creatures",
                "Steampunk airship in the sky",
                "Mystical forest with fairy lights"
            ]
        ),
        PromptCategory(
            title: "Objects & Product",
            icon: "cube.fill",
            emoji: "📦",
            prompts: [
                "Product shot of a perfume bottle on marble",
                "Coffee cup with steam, cozy morning",
                "Luxury watch on black background",
                "Fresh fruits in a wooden bowl",
                "Vintage camera on a desk"
            ]
        )
    ]
}
