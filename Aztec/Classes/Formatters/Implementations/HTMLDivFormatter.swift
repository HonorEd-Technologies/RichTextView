import Foundation
import UIKit


// MARK: - HTMLDivFormatter Formatter
//
class HTMLDivFormatter: ParagraphAttributeFormatter {

    /// Attributes to be added by default
    ///
    let placeholderAttributes: [NSAttributedString.Key: Any]?


    /// Designated Initializer
    ///
    init(placeholderAttributes: [NSAttributedString.Key: Any]? = nil) {
        self.placeholderAttributes = placeholderAttributes
    }


    // MARK: - Overwriten Methods

    func apply(to attributes: [NSAttributedString.Key: Any], andStore representation: HTMLRepresentation?) -> [NSAttributedString.Key: Any] {
        let newParagraphStyle = ParagraphStyle()

        if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle {
            newParagraphStyle.setParagraphStyle(paragraphStyle)
        }

        let newProperty = HTMLDiv(with: representation)
        newParagraphStyle.appendProperty(newProperty)
        newParagraphStyle.regularParagraphSpacing = 0
        newParagraphStyle.regularParagraphSpacingBefore = 0
        
        var resultingAttributes = attributes
        resultingAttributes[.paragraphStyle] = newParagraphStyle
        return resultingAttributes
    }

    func remove(from attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        guard let paragraphStyle = attributes[.paragraphStyle] as? ParagraphStyle,
            !paragraphStyle.htmlDiv.isEmpty
        else {
            return attributes
        }

        let newParagraphStyle = ParagraphStyle()
        newParagraphStyle.setParagraphStyle(paragraphStyle)
        newParagraphStyle.removeProperty(ofType: HTMLDiv.self)

        var resultingAttributes = attributes
        resultingAttributes[.paragraphStyle] = newParagraphStyle
        return resultingAttributes
    }

    func present(in attributes: [NSAttributedString.Key: Any]) -> Bool {
        let style = attributes[.paragraphStyle] as? ParagraphStyle
        return style?.htmlDiv.isEmpty == false
    }
}
