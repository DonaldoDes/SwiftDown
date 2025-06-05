//
//  MarkdownEngine.swift
//
//
//  Created by Quentin Eude on 16/03/2021.
//

import Down
import Foundation

public class MarkdownEngine {
  var text = ""
  var lines: [Int] = []
  private let wikilinkProcessor = WikilinkProcessor()

  public init() {}

  private func toMarkdownNode(_ node: Node, offset: Int) -> MarkdownNode? {
    let p = node.cmarkNode.pointee
    if let type = MarkdownNode.MarkdownType.from(
      rawValue: Int(p.type), with: node.cmarkNode.headingLevel) {
      let s = lines[Int(p.start_line) - 1] + Int(p.start_column) - 1
      let e = lines[Int(p.end_line) - 1] + Int(p.end_column) - 1

      let fromIdx = text.utf8.index(text.utf8.startIndex, offsetBy: s)
      let range =
        text.utf8
        .index(text.utf8.startIndex, offsetBy: max(0, e), limitedBy: text.utf8.endIndex)
        .flatMap {
          if ($0 < text.utf8.endIndex && $0 > fromIdx) {
            let range = NSRange(fromIdx...$0, in: text)
            return NSRange(location: range.location + offset, length: range.length)
          } else {
            return nil
          }
        } ?? NSRange(fromIdx..<text.utf8.endIndex, in: text)
      return MarkdownNode(range: range, type: type, headingLevel: node.cmarkNode.headingLevel)
    } else {
      return nil
    }
  }

  func exploreChildren(_ node: Node, offset: Int) -> [MarkdownNode] {
    node.children.reduce(toMarkdownNode(node, offset: offset).map { c in [c] } ?? []) { (r, c) in
      r + exploreChildren(c, offset: offset)
    }
  }

  public func render(_ markdownString: String, offset: Int) -> [MarkdownNode] {
    // Step 1: Preprocess wikilinks before Down parsing (TI-1 specification)
    let (processedText, wikilinkInfo) = wikilinkProcessor.preprocessWikilinks(markdownString)
    
    // Set text to processed version for internal calculations but keep original for post-processing
    text = processedText
    let lcs = processedText.components(separatedBy: .newlines).map { $0.utf8.count }
    var sum = 0
    var counts: [Int] = []
    for l in lcs {
      counts.append(sum)
      sum += (l + 1)
    }
    lines = counts

    // Step 2: Standard Down parsing on preprocessed text
    let result = (try? Down(markdownString: processedText).toDocument(.smart))!
    let nodes = exploreChildren(result, offset: offset)
    
    // Step 3: Post-process to restore wikilink nodes (TI-1 specification)
    return wikilinkProcessor.postprocessNodes(nodes, wikilinkInfo: wikilinkInfo, offset: offset)
  }
  
  /// Extracts wikilinks from markdown text without full AST processing
  ///
  /// This method provides access to wikilink information for external APIs
  /// like validation and navigation, as specified in FR-6.
  ///
  /// - Parameter markdownString: The markdown text to analyze
  /// - Returns: Array of WikilinkMatch objects with title and range information
  public func getWikilinks(from markdownString: String) -> [WikilinkMatch] {
    return wikilinkProcessor.extractWikilinks(from: markdownString)
  }
  
  /// Validates wikilinks in markdown text using a provided validator
  ///
  /// This method provides validation functionality as specified in FR-6.
  ///
  /// - Parameters:
  ///   - markdownString: The markdown text to validate
  ///   - validator: A closure that returns true if the wikilink title is valid
  /// - Returns: Dictionary mapping wikilink titles to their validation status
  public func validateWikilinks(in markdownString: String, using validator: (String) -> Bool) -> [String: Bool] {
    return wikilinkProcessor.validateWikilinks(in: markdownString, using: validator)
  }
}
