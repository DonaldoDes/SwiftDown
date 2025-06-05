import XCTest
import Nimble

@testable import SwiftDown

final class WikilinkASTIntegrationTests: XCTestCase {
    var engine: MarkdownEngine!
    
    override func setUp() {
        engine = MarkdownEngine()
    }
    
    // MARK: - AST Integration Tests
    
    func testBasicWikilinkAST() {
        let text = "See [[Note Title]] for details"
        let nodes = engine.render(text, offset: 0)
        
        let wikilinkNodes = nodes.filter { $0.type == .wikilink }
        expect(wikilinkNodes).to(haveCount(1))
        
        // The range should be approximately where the wikilink was
        let wikilink = wikilinkNodes[0]
        expect(wikilink.range.length).to(beGreaterThan(0))
    }
    
    func testWikilinkWithMarkdown() {
        let text = "See [[Note Title]] and [regular link](url)"
        let nodes = engine.render(text, offset: 0)
        
        let wikilinkNodes = nodes.filter { $0.type == .wikilink }
        let linkNodes = nodes.filter { $0.type == .link }
        
        expect(wikilinkNodes).to(haveCount(1))
        expect(linkNodes).to(haveCount(1))
    }
    
    func testMultipleWikilinks() {
        let text = "See [[Note A]] and [[Note B]] for details"
        let nodes = engine.render(text, offset: 0)
        
        let wikilinkNodes = nodes.filter { $0.type == .wikilink }
        expect(wikilinkNodes).to(haveCount(2))
    }
    
    func testEmptyWikilinksIgnored() {
        let text = "Empty [[]] wikilinks should be ignored"
        let nodes = engine.render(text, offset: 0)
        
        let wikilinkNodes = nodes.filter { $0.type == .wikilink }
        expect(wikilinkNodes).to(haveCount(0))
    }
    
    func testWikilinksWithOffset() {
        let text = "See [[Note Title]] for details"
        let nodes = engine.render(text, offset: 10)
        
        let wikilinkNodes = nodes.filter { $0.type == .wikilink }
        expect(wikilinkNodes).to(haveCount(1))
        
        // With offset, the range should be shifted
        let wikilink = wikilinkNodes[0]
        expect(wikilink.range.location).to(beGreaterThanOrEqualTo(10))
    }
    
    // MARK: - API Integration Tests
    
    func testGetWikilinksAPI() {
        let text = "See [[Note Title]] and [[Another Note]] for details"
        let wikilinks = engine.getWikilinks(from: text)
        
        expect(wikilinks).to(haveCount(2))
        expect(wikilinks[0].title).to(equal("Note Title"))
        expect(wikilinks[1].title).to(equal("Another Note"))
    }
    
    func testGetWikilinksWithWhitespace() {
        let text = "See [[ Note Title ]] for details"
        let wikilinks = engine.getWikilinks(from: text)
        
        expect(wikilinks).to(haveCount(1))
        expect(wikilinks[0].title).to(equal("Note Title"))
    }
    
    func testGetWikilinksSpecialCharacters() {
        let text = "See [[Note-Title_2023!]] for details"
        let wikilinks = engine.getWikilinks(from: text)
        
        expect(wikilinks).to(haveCount(1))
        expect(wikilinks[0].title).to(equal("Note-Title_2023!"))
    }
    
    // MARK: - Performance Tests
    
    func testLargeDocumentPerformance() {
        let text = generateTextWithWikilinks(count: 100)
        
        measure {
            _ = engine.render(text, offset: 0)
        }
    }
    
    func testGetWikilinksPerformance() {
        let text = generateTextWithWikilinks(count: 100)
        
        measure {
            _ = engine.getWikilinks(from: text)
        }
    }
    
    // MARK: - Edge Cases
    
    func testWikilinksInCodeBlocks() {
        let text = """
        Normal [[wikilink]] here
        
        ```
        Code [[not a wikilink]] here
        ```
        
        Another [[real wikilink]]
        """
        
        let nodes = engine.render(text, offset: 0)
        let wikilinkNodes = nodes.filter { $0.type == .wikilink }
        
        // Should only find wikilinks outside code blocks
        expect(wikilinkNodes).to(haveCount(2))
    }
    
    func testWikilinksWithMarkdownSyntax() {
        let text = "See [[**Bold Title**]] and [[*Italic Title*]]"
        let nodes = engine.render(text, offset: 0)
        
        let wikilinkNodes = nodes.filter { $0.type == .wikilink }
        expect(wikilinkNodes).to(haveCount(2))
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