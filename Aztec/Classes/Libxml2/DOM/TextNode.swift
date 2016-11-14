import Foundation

extension Libxml2 {
    /// Text nodes.  Cannot have child nodes (for now, not sure if we will need them).
    ///
    class TextNode: Node, EditableNode, LeafNode {

        private var contents: String

        init(text: String) {
            contents = text

            super.init(name: "text")
        }

        override func customMirror() -> Mirror {
            return Mirror(self, children: ["type": "text", "name": name, "text": contents, "parent": parent.debugDescription], ancestorRepresentation: .Suppressed)
        }

        /// Node length.
        ///
        override func length() -> Int {
            return contents.characters.count
        }

        // MARK: - EditableNode
        
        func append(string: String, undoManager: NSUndoManager? = nil) {
            contents.appendContentsOf(string)
        }

        func deleteCharacters(inRange range: NSRange, undoManager: NSUndoManager? = nil) {

            guard let textRange = contents.rangeFromNSRange(range) else {
                fatalError("The specified range is out of bounds.")
            }

            contents.removeRange(textRange)
        }
        
        func prepend(string: String, undoManager: NSUndoManager? = nil) {
            contents = "\(string)\(contents)"
        }

        func replaceCharacters(inRange range: NSRange, withString string: String, inheritStyle: Bool, undoManager: NSUndoManager? = nil) {

            guard let textRange = contents.rangeFromNSRange(range) else {
                fatalError("The specified range is out of bounds.")
            }

            contents.replaceRange(textRange, with: string)
        }

        func split(atLocation location: Int, undoManager: NSUndoManager? = nil) {
            
            guard location != 0 && location != length() else {
                // Nothing to split, move along...
                
                return
            }
            
            guard location > 0 && location < length() else {
                fatalError("Out of bounds!")
            }
            
            let index = text().startIndex.advancedBy(location)
            
            guard let parent = parent,
                let nodeIndex = parent.children.indexOf(self) else {
                    
                    fatalError("This scenario should not be possible. Review the logic.")
            }
            
            let postRange = index ..< text().endIndex
            
            if postRange.count > 0 {
                let newNode = TextNode(text: text().substringWithRange(postRange))
                
                contents.removeRange(postRange)
                parent.insert(newNode, at: nodeIndex + 1)
            }
        }
        
        func split(forRange range: NSRange, undoManager: NSUndoManager? = nil) {

            guard let swiftRange = contents.rangeFromNSRange(range) else {
                fatalError("This scenario should not be possible. Review the logic.")
            }

            guard let parent = parent,
                let nodeIndex = parent.children.indexOf(self) else {

                fatalError("This scenario should not be possible. Review the logic.")
            }

            let preRange = contents.startIndex ..< swiftRange.startIndex
            let postRange = swiftRange.endIndex ..< contents.endIndex

            if postRange.count > 0 {
                let newNode = TextNode(text: contents.substringWithRange(postRange))

                contents.removeRange(postRange)
                parent.insert(newNode, at: nodeIndex + 1)
            }

            if preRange.count > 0 {
                let newNode = TextNode(text: contents.substringWithRange(preRange))

                contents.removeRange(preRange)
                parent.insert(newNode, at: nodeIndex)
            }
        }


        /// Wraps the specified range inside a node with the specified name.
        ///
        /// - Parameters:
        ///     - targetRange: the range that must be wrapped.
        ///     - elementDescriptor: the descriptor for the element to wrap the range in.
        ///
        func wrap(range targetRange: NSRange, inElement elementDescriptor: ElementNodeDescriptor, undoManager: NSUndoManager? = nil) {

            guard !NSEqualRanges(targetRange, NSRange(location: 0, length: length())) else {
                wrap(inElement: elementDescriptor, undoManager: undoManager)
                return
            }

            split(forRange: targetRange, undoManager: undoManager)
            wrap(inElement: elementDescriptor, undoManager: undoManager)
        }
        
        // MARK: - LeadNode
        
        override func text() -> String {
            return contents
        }
    }
}
