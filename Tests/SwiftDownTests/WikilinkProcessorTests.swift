import XCTest
import Nimble

@testable import SwiftDown

final class WikilinkProcessorTests: XCTestCase {
    var processor: WikilinkProcessor!
    
    override func setUp() {
        processor = WikilinkProcessor()
    }
    
    // MARK: - Basic Wikilink Detection Tests
    
    func testBasicWikilinkDetection() {
        let text = "See [[Note Title]] for details"
        let matches = processor.processWikilinks(in: text)
        
        expect(matches).to(haveCount(1))
        expect(matches[0].title).to(equal("Note Title"))
        expect(matches[0].range).to(equal(NSRange(location: 4, length: 14)))
        expect(matches[0].contentRange).to(equal(NSRange(location: 6, length: 10)))
    }
    
    func testMultipleWikilinks() {
        let text = "See [[Note Title]] and [[Another Note]] for details"
        let matches = processor.processWikilinks(in: text)
        
        expect(matches).to(haveCount(2))
        expect(matches[0].title).to(equal("Note Title"))
        expect(matches[1].title).to(equal("Another Note"))
    }
    
    func testEmptyWikilinksIgnored() {
        let text = "Empty [[]] wikilinks should be ignored"
        let matches = processor.processWikilinks(in: text)
        
        expect(matches).to(haveCount(0))
    }
    
    func testWhitespaceTrimmingInWikilinks() {
        let text = "Whitespace [[ Note Title ]] should be trimmed"
        let matches = processor.processWikilinks(in: text)
        
        expect(matches).to(haveCount(1))
        expect(matches[0].title).to(equal("Note Title"))
    }
    
    func testSpecialCharactersInWikilinks() {
        let text = "Special [[Note-Title_2023!]] characters work"
        let matches = processor.processWikilinks(in: text)
        
        expect(matches).to(haveCount(1))
        expect(matches[0].title).to(equal("Note-Title_2023!"))
    }
    
    func testSimpleWikilinks() {
        let text = "Simple [[Note Title]] without brackets"
        let matches = processor.processWikilinks(in: text)
        
        expect(matches).to(haveCount(1))
        expect(matches[0].title).to(equal("Note Title"))
    }
    
    // MARK: - Edge Case Tests
    
    func testSingleBracketsIgnored() {
        let text = "Single [Note] brackets should not be wikilinks"
        let matches = processor.processWikilinks(in: text)
        
        expect(matches).to(haveCount(0))
    }
    
    func testMalformedWikilinksIgnored() {
        let text1 = "Malformed [[Note Title should be ignored"
        let text2 = "Malformed Note Title]] should be ignored"
        
        expect(self.processor.processWikilinks(in: text1)).to(haveCount(0))
        expect(self.processor.processWikilinks(in: text2)).to(haveCount(0))
    }
    
    func testTripleBracketsContainWikilink() {
        let text = "Triple [[[Note Title]]] contains a wikilink"
        let matches = processor.processWikilinks(in: text)
        
        expect(matches).to(haveCount(1))
        expect(matches[0].title).to(equal("[Note Title"))
    }
    
    func testWikilinksAtStartAndEnd() {
        let text = "[[Start Note]] middle text [[End Note]]"
        let matches = processor.processWikilinks(in: text)
        
        expect(matches).to(haveCount(2))
        expect(matches[0].title).to(equal("Start Note"))
        expect(matches[1].title).to(equal("End Note"))
    }
    
    func testConsecutiveWikilinks() {
        let text = "[[First]][[Second]] consecutive wikilinks"
        let matches = processor.processWikilinks(in: text)
        
        expect(matches).to(haveCount(2))
        expect(matches[0].title).to(equal("First"))
        expect(matches[1].title).to(equal("Second"))
    }
    
    // MARK: - AST-Based Processing Tests
    
    func testPreprocessingWikilinks() {
        let text = "See [[Note Title]] for details"
        let (processedText, wikilinkMap) = processor.preprocessWikilinksLegacy(text)
        
        expect(wikilinkMap).to(haveCount(1))
        expect(wikilinkMap.values.first).to(equal("Note Title"))
        expect(processedText).to(contain("http://wikilink/"))
        expect(processedText).to(contain("WIKILINK_TEMP_"))
    }
    
    func testPostprocessingNodes() {
        // Create mock nodes that represent what Down parser would generate
        let linkNode = MarkdownNode(range: NSRange(location: 4, length: 20), type: .link, headingLevel: 0)
        let bodyNode = MarkdownNode(range: NSRange(location: 25, length: 11), type: .body, headingLevel: 0)
        let nodes = [linkNode, bodyNode]
        
        // Create wikilink info for post-processing
        let wikilinkInfo = [TempWikilinkInfo(
            originalRange: NSRange(location: 4, length: 14),
            title: "Note Title",
            tempId: "WIKILINK_TEMP_1"
        )]
        
        let processedNodes = processor.postprocessNodes(nodes, wikilinkInfo: wikilinkInfo, offset: 0)
        
        expect(processedNodes).to(haveCount(2))
        expect(processedNodes[0].type).to(equal(MarkdownNode.MarkdownType.wikilink))
        expect(processedNodes[1].type).to(equal(MarkdownNode.MarkdownType.body))
    }
    
    func testPreprocessingMultipleWikilinks() {
        let text = "See [[Note A]] and [[Note B]]"
        let (_, wikilinkMap) = processor.preprocessWikilinksLegacy(text)
        
        expect(wikilinkMap).to(haveCount(2))
        expect(wikilinkMap.values).to(contain("Note A"))
        expect(wikilinkMap.values).to(contain("Note B"))
    }
    
    func testPreprocessingEmptyWikilinks() {
        let text = "Empty [[]] should be ignored"
        let (processedText, wikilinkMap) = processor.preprocessWikilinksLegacy(text)
        
        expect(wikilinkMap).to(haveCount(0))
        expect(processedText).to(equal(text)) // Should remain unchanged
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceWithManyWikilinks() {
        let text = generateTextWithWikilinks(count: 100)
        
        measure {
            _ = processor.processWikilinks(in: text)
        }
    }
    
    func testPreprocessingPerformance() {
        let text = generateTextWithWikilinks(count: 100)
        
        measure {
            _ = processor.preprocessWikilinksLegacy(text)
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateTextWithWikilinks(count: Int) -> String {
        var text = "Document with many wikilinks:\n\n"
        for i in 0..<count {
            text += "Reference to [[Note \(i)]] here. "
            if i % 10 == 0 { text += "\n" }
        }
        return text
    }
}