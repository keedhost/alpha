import Foundation

enum KeyboardMapping {
    static func mapLatinToUkrainian(_ text: String) -> String {
        return text.map { latinToUkrainian[$0] ?? $0 }.map(String.init).joined()
    }

    static func mapUkrainianToLatin(_ text: String) -> String {
        return text.map { ukrainianToLatin[$0] ?? $0 }.map(String.init).joined()
    }

    private static let latinToUkrainian: [Character: Character] = {
        var map: [Character: Character] = [
            "q": "й", "w": "ц", "e": "у", "r": "к", "t": "е", "y": "н", "u": "г", "i": "ш", "o": "щ", "p": "з", "[": "х", "]": "ї",
            "a": "ф", "s": "і", "d": "в", "f": "а", "g": "п", "h": "р", "j": "о", "k": "л", "l": "д", ";": "ж", "'": "є", "\\": "ґ",
            "z": "я", "x": "ч", "c": "с", "v": "м", "b": "и", "n": "т", "m": "ь", ",": "б", ".": "ю", "/": "."
        ]

        for (k, v) in map {
            if let upperK = k.uppercased().first, let upperV = String(v).uppercased().first {
                map[upperK] = upperV
            }
        }

        return map
    }()

    private static let ukrainianToLatin: [Character: Character] = {
        var map: [Character: Character] = [:]
        for (k, v) in latinToUkrainian {
            map[v] = k
        }
        return map
    }()
}
