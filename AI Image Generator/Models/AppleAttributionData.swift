import Foundation

struct AppleAttributionData: Codable, Sendable {
    let attribution: Bool
    let orgId: Int?
    let campaignId: Int?
    let adGroupId: Int?
    let keywordId: Int?
    let adId: Int?
    let conversionType: String?
    let claimType: String?
    let countryOrRegion: String?
    let supplyPlacement: String?
    let clickDate: String?
    let impressionDate: String?

    enum CodingKeys: String, CodingKey {
        case attribution
        case orgId
        case campaignId
        case conversionType
        case clickDate
        case claimType
        case adGroupId
        case countryOrRegion
        case keywordId
        case adId
        case supplyPlacement
        case impressionDate
    }
}
