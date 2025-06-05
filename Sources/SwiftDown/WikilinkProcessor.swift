//
//  WikilinkProcessor.swift
//
//
//  Created by Claude on 05/06/2025.
//

import Foundation
import Down

public struct WikilinkMatch {
    public let title: String
    public let range: NSRange
    public let contentRange: NSRange
    
    public init(title: String, range: NSRange, contentRange: NSRange) {
        self.title = title
        self.range = range
        self.contentRange = contentRange
    }
}

/// Temporary wikilink information for post-processing
struct TempWikilinkInfo {
    let originalRange: NSRange
    let title: String
    let tempId: String
}

/// AST-based wikilink processor that integrates with Down parser
/// 
/// This processor implements the AST-based detection strategy specified in TI-1:
/// 1. Preprocess wikilinks before CommonMark parsing by converting to temporary markdown
/// 2. Allow Down parser to create standard AST nodes for temporary syntax
/// 3. Post-process AST to convert temporary link nodes back to wikilink nodes
///
/// This approach ensures proper integration with the Down parser AST while maintaining
/// compatibility with standard markdown processing.
class WikilinkProcessor {
    private let wikilinkPattern = #"\[\[([^\]]+)\]\]"#
    private let tempMarker = "WIKILINK_TEMP_"
    private var tempCounter = 0
    
    /// Preprocesses text to convert wikilinks to temporary markdown syntax
    /// 
    /// Converts `[[Title]]` to `[WIKILINK_TEMP_ID](wikilink://Title)` so that
    /// Down parser can create proper link AST nodes that we later convert to wikilinks.
    ///
    /// - Parameter text: The original markdown text containing wikilinks
    /// - Returns: Tuple of processed text and array of temp wikilink info for post-processing
    private func preprocessWikilinksInternal(_ text: String) -> (processedText: String, wikilinkInfo: [TempWikilinkInfo]) {
        var processedText = text
        var wikilinkInfo: [TempWikilinkInfo] = []
        
        let regex = try! NSRegularExpression(pattern: wikilinkPattern, options: [])
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
        
        // Process matches in reverse order to avoid range shifting issues
        for match in matches.reversed() {
            let fullRange = match.range
            let titleRange = match.range(at: 1)
            
            let title = String(text[Range(titleRange, in: text)!]).trimmingCharacters(in: .whitespaces)
            
            // Skip empty wikilinks as per FR-1 acceptance criteria
            if title.isEmpty {
                continue
            }
            
            tempCounter += 1
            let tempId = "\(tempMarker)\(tempCounter)"
            let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? title
            let replacement = "[\(tempId)](http://wikilink/\(encodedTitle))"
            
            // Store original range and info for post-processing
            let tempInfo = TempWikilinkInfo(
                originalRange: fullRange,
                title: title,
                tempId: tempId
            )
            wikilinkInfo.insert(tempInfo, at: 0) // Insert at beginning to maintain order
            
            let startIndex = text.index(text.startIndex, offsetBy: fullRange.location)
            let endIndex = text.index(startIndex, offsetBy: fullRange.length)
            processedText.replaceSubrange(startIndex..<endIndex, with: replacement)
        }
        
        return (processedText, wikilinkInfo)
    }
    
    /// Post-processes AST nodes to convert temporary link nodes back to wikilink nodes
    ///
    /// Identifies link nodes created from temporary wikilink syntax and converts them
    /// to proper wikilink nodes with the correct type and original ranges.
    ///
    /// - Parameters:
    ///   - nodes: Array of MarkdownNode from Down parser
    ///   - wikilinkInfo: Array of temp wikilink info for mapping back
    ///   - offset: Offset used in original processing
    /// - Returns: Array of MarkdownNode with wikilinks properly typed
    func postprocessNodes(_ nodes: [MarkdownNode], wikilinkInfo: [TempWikilinkInfo], offset: Int) -> [MarkdownNode] {
        var processedNodes: [MarkdownNode] = []
        var wikilinkIndex = 0
        
        for node in nodes {
            if node.type == .link && wikilinkIndex < wikilinkInfo.count {
                // Convert this link node to a wikilink using original range
                let wikilinkData = wikilinkInfo[wikilinkIndex]
                let adjustedRange = NSRange(
                    location: wikilinkData.originalRange.location + offset,
                    length: wikilinkData.originalRange.length
                )
                
                let wikilinkNode = MarkdownNode(
                    range: adjustedRange,
                    type: .wikilink,
                    headingLevel: node.headingLevel
                )
                processedNodes.append(wikilinkNode)
                wikilinkIndex += 1
            } else {
                processedNodes.append(node)
            }
        }
        
        return processedNodes
    }
    
    /// Extracts wikilink information from processed text for external API usage
    ///
    /// This method provides the external API for getting wikilink matches,
    /// useful for validation, navigation, and other wikilink operations.
    ///
    /// - Parameter text: The original markdown text
    /// - Returns: Array of WikilinkMatch with title and range information
    func extractWikilinks(from text: String) -> [WikilinkMatch] {
        let regex = try! NSRegularExpression(pattern: wikilinkPattern, options: [])
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
        
        return matches.compactMap { match in
            let fullRange = match.range
            let titleRange = match.range(at: 1)
            
            let title = String(text[Range(titleRange, in: text)!]).trimmingCharacters(in: .whitespaces)
            
            // Skip empty wikilinks as per FR-1 acceptance criteria
            if title.isEmpty {
                return nil
            }
            
            return WikilinkMatch(title: title, range: fullRange, contentRange: titleRange)
        }
    }
    
    /// Validates wikilinks using a provided validator function
    ///
    /// This method provides validation support as specified in FR-6.
    ///
    /// - Parameters:
    ///   - text: The markdown text to validate
    ///   - validator: A closure that returns true if the wikilink title is valid
    /// - Returns: Dictionary mapping wikilink titles to their validation status
    func validateWikilinks(in text: String, using validator: (String) -> Bool) -> [String: Bool] {
        let wikilinks = extractWikilinks(from: text)
        var validationResults: [String: Bool] = [:]
        
        for wikilink in wikilinks {
            if validationResults[wikilink.title] == nil {
                validationResults[wikilink.title] = validator(wikilink.title)
            }
        }
        
        return validationResults
    }
    
    /// Legacy method for backward compatibility with existing tests
    /// 
    /// This maintains compatibility while transitioning to AST-based approach.
    /// Will be deprecated once full AST integration is complete.
    func processWikilinks(in text: String) -> [WikilinkMatch] {
        return extractWikilinks(from: text)
    }
    
    /// Public preprocessing method for AST integration
    /// 
    /// Primary method used by MarkdownEngine for AST-based processing.
    func preprocessWikilinks(_ text: String) -> (processedText: String, wikilinkInfo: [TempWikilinkInfo]) {
        return preprocessWikilinksInternal(text)
    }
    
    /// Legacy preprocessing method for backward compatibility with existing tests
    /// 
    /// Returns the old format for tests that haven't been updated yet.
    func preprocessWikilinksLegacy(_ text: String) -> (processedText: String, wikilinkMap: [String: String]) {
        let (processedText, wikilinkInfo) = preprocessWikilinksInternal(text)
        
        var wikilinkMap: [String: String] = [:]
        for info in wikilinkInfo {
            wikilinkMap[info.tempId] = info.title
        }
        
        return (processedText, wikilinkMap)
    }
}