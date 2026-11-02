import Foundation

/// Uses macOS bundle localization. The user's preferred app language is chosen
/// by the operating system from cs, en and de; English is the development fallback.
enum L10n {
    static func text(_ key: String) -> String {
        Bundle.main.localizedString(forKey: key, value: key, table: "Localizable")
    }

    static func formatted(_ key: String, _ argument: String) -> String {
        String(format: text(key), locale: Locale.current, argument)
    }
}
