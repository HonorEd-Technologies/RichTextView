import Foundation
import UIKit


// MARK: - Lists Formatter
//
class TextListFormatter: ParagraphAttributeFormatter {

    /// Style of the list
    ///
    let listStyle: TextList.Style

    /// Attributes to be added by default
    ///
    let placeholderAttributes: [NSAttributedString.Key: Any]?

    /// Tells if the formatter is increasing the depth of a list or simple changing the current one if any
    let increaseDepth: Bool

    /// Designated Initializer
    ///
    init(style: TextList.Style, placeholderAttributes: [NSAttributedString.Key: Any]? = nil, increaseDepth: Bool = false) {
        self.listStyle = style
        self.placeholderAttributes = placeholderAttributes
        self.increaseDepth = increaseDepth
    }


    // MARK: - Overwriten Methods

    func apply(to attributes: [NSAttributedString.Key: Any], andStore representation: HTMLRepresentation?) -> [NSAttributedString.Key: Any] {
        let newParagraphStyle = ParagraphStyle()
        if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle {
            newParagraphStyle.setParagraphStyle(paragraphStyle)
            newParagraphStyle.removeProperty(ofType: HTMLParagraph.self)
        }

        let newList = TextList(style: self.listStyle, with: representation)
        
        if newParagraphStyle.lists.isEmpty || increaseDepth {
            newParagraphStyle.insertProperty(newList, afterLastOfType: HTMLLi.self)
        } else {
            newParagraphStyle.replaceProperty(ofType: TextList.self, with: newList)
        }

        var resultingAttributes = attributes
        resultingAttributes[.paragraphStyle] = newParagraphStyle

        return resultingAttributes
    }
    
    func apply(to attributes: [NSAttributedString.Key: Any], newList: TextList) -> [NSAttributedString.Key: Any] {
        let newParagraphStyle = ParagraphStyle()
        if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle {
            newParagraphStyle.setParagraphStyle(paragraphStyle)
            newParagraphStyle.removeProperty(ofType: HTMLParagraph.self)
        }
        
        if newParagraphStyle.lists.isEmpty || increaseDepth {
            newParagraphStyle.insertProperty(newList, afterLastOfType: HTMLLi.self)
        } else {
            newParagraphStyle.replaceProperty(ofType: TextList.self, with: newList)
        }

        var resultingAttributes = attributes
        resultingAttributes[.paragraphStyle] = newParagraphStyle

        return resultingAttributes
    }
    
    @discardableResult
    func applyAttributes(to text: NSMutableAttributedString, at range: NSRange) -> NSRange {
        let rangeToApply = applicationRange(for: range, in: text)

        text.replaceOcurrences(of: String(.lineFeed), with: String(.paragraphSeparator), within: rangeToApply)
        
        var newList = TextList(style: self.listStyle, with: nil)

        if let lastParagraphRange = text.paragraphRange(before: rangeToApply) {
            let lastParaAttributes = text.attributes(at: lastParagraphRange.location, effectiveRange: nil)
            
            if let paraStyle = lastParaAttributes[.paragraphStyle] as? NSParagraphStyle,
               let lastList = ParagraphStyle(with: paraStyle).lists.first, lastList.style == self.listStyle {
                newList = lastList
            }
        }
        var range = rangeToApply
        while true {
            if let nextParagraphRange = text.paragraphRange(after: range) {
                var nextParaAttributes = text.attributes(at: nextParagraphRange.location, effectiveRange: nil)
                
                if let paraStyle = nextParaAttributes[.paragraphStyle] as? NSParagraphStyle {
                    let newParaStyle = ParagraphStyle(with: paraStyle)
                    if let nextList = newParaStyle.lists.first, nextList.style == self.listStyle,
                        let listIndex = newParaStyle.properties.firstIndex(where: {Swift.type(of: $0) == TextList.self}) {
                        newParaStyle.properties[listIndex] = newList
                        nextParaAttributes[.paragraphStyle] = newParaStyle
                        text.addAttributes(nextParaAttributes, range: nextParagraphRange)
                        range = nextParagraphRange
                        continue
                    }
                }
            }
            break
        }
        
        text.enumerateAttributes(in: rangeToApply, options: []) { (attributes, range, _) in
            let currentAttributes = text.attributes(at: range.location, effectiveRange: nil)
            let attributes = apply(to: currentAttributes, newList: newList)
            text.addAttributes(attributes, range: range)
        }

        return rangeToApply
    }

    func remove(from attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        guard let paragraphStyle = attributes[.paragraphStyle] as? ParagraphStyle,
              let currentList = paragraphStyle.lists.last,
              currentList.style == self.listStyle
        else {
            return attributes
        }

        let newParagraphStyle = ParagraphStyle()
        newParagraphStyle.setParagraphStyle(paragraphStyle)
        newParagraphStyle.removeProperty(ofType: HTMLLi.self)
        newParagraphStyle.removeProperty(ofType: TextList.self)

        var resultingAttributes = attributes
        resultingAttributes[.paragraphStyle] = newParagraphStyle

        return resultingAttributes
    }

    func present(in attributes: [NSAttributedString.Key: Any]) -> Bool {
        return TextListFormatter.lists(in: attributes).last?.style == listStyle
    }


    // MARK: - Static Helpers

    static func listsOfAnyKindPresent(in attributes: [NSAttributedString.Key: Any]) -> Bool {
        return lists(in: attributes).isEmpty == false
    }

    static func lists(in attributes: [NSAttributedString.Key: Any]) -> [TextList] {
        let style = attributes[.paragraphStyle] as? ParagraphStyle
        return style?.lists ?? []
    }
}

