import Foundation

extension String {
    /// Uses this string as the key in `Localizable.strings` (same as `String(localized: String.LocalizationValue(stringLiteral: self))`).
    var localized: String {
        String(localized: String.LocalizationValue(stringLiteral: self))
    }
}
