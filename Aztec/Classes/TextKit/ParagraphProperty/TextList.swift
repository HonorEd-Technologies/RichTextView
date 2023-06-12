import Foundation
import UIKit


// MARK: - Text List
//
open class TextList: ParagraphProperty {

    // MARK: - Nested Types

    /// List Styles
    ///
    public enum Style: Int {
        case ordered
        case unordered

        func markerText(forItemNumber number: Int, listDepth: Int) -> String {
            switch self {
            case .ordered:
                switch listDepth%3 {
                case 1:
                    return "\(number)."
                case 2:
                    return "\(intToAlphabeticIndex(from: number))."
                default:
                    return "\(intToRomanIndex(from: number))."
                }
            case .unordered:
                switch listDepth%3 {
                case 1:
                    return "\u{2022}"
                case 2:
                    return "\u{25E6}"
                default:
                    return "\u{25AA}"
                }
            }
        }
        func intToAlphabeticIndex(from num: Int) -> String {
            let letters = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
            let module = num % 26 // which letter, int = 1
            let numOfLetters = module == 0 ? Int(num / 26) : Int(num / 26) + 1
            let pickedLetter = module == 0 ? letters[25] : letters[module - 1]
            return String(repeating: pickedLetter, count: numOfLetters)
        }

        func intToRomanIndex(from num: Int) -> String {
            let alphabet: KeyValuePairs = [1000: "m", 900: "cm", 500: "d", 400: "cd", 100: "c", 90: "xc", 50: "l", 40: "xl", 10: "x", 9: "ix", 5: "v", 4: "iv", 1: "i"]
            var val = num
            var result = ""
            for (int, rom) in alphabet {
                while val >= int {
                    val -= int
                    result += rom
                }
            }
            return result
        }
    }

    public let reversed: Bool

    public let start: Int?

    // MARK: - Properties

    /// Kind of List: Ordered / Unordered
    ///
    let style: Style

    init(style: Style, start: Int? = nil, reversed: Bool = false, with representation: HTMLRepresentation? = nil) {
        self.style = style

        if let representation = representation, case let .element( html ) = representation.kind {
            self.reversed = html.attribute(ofType: .reversed) != nil
            
            if let startAttribute = html.attribute(ofType: .start),
                case let .string( value ) = startAttribute.value,
                let start = Int(value)
            {
                self.start = start
            } else {
                self.start = nil
            }
        } else {
            self.start = start
            self.reversed = reversed
        }
        super.init(with: representation)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        if aDecoder.containsValue(forKey: String(describing: Style.self)),
            let decodedStyle = Style(rawValue:aDecoder.decodeInteger(forKey: String(describing: Style.self))) {
            style = decodedStyle
        } else {
            style = .ordered
        }
        if aDecoder.containsValue(forKey: AttributeType.start.rawValue) {
            let decodedStart = aDecoder.decodeInteger(forKey: AttributeType.start.rawValue)
            start = decodedStart
        } else {
            start = nil
        }

        if aDecoder.containsValue(forKey: AttributeType.reversed.rawValue) {
            let decodedReversed = aDecoder.decodeBool(forKey: AttributeType.reversed.rawValue)
            reversed = decodedReversed
        } else {
            reversed = false
        }

        super.init(coder: aDecoder)
    }

    public override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(style.rawValue, forKey: String(describing: Style.self))
        aCoder.encode(start, forKey: AttributeType.start.rawValue)
        aCoder.encode(reversed, forKey: AttributeType.reversed.rawValue)
    }

    public static func ==(lhs: TextList, rhs: TextList) -> Bool {
        return lhs.style == rhs.style && lhs.start == rhs.start && lhs.reversed == rhs.reversed
    }
}
