import XCTest
import Nimble

@testable import SwiftDown

final class WikilinkStyleTests: XCTestCase {
    
    // MARK: - WikilinkStyle Tests
    
    func testDefaultLightWikilinkStyle() {
        let style = WikilinkStyle.defaultLight
        
        expect(style.textColor).to(equal(UniversalColor(hexString: "#007AFF")))
        expect(style.backgroundColor).to(equal(UniversalColor.clear))
        expect(style.underlineStyle).to(equal(NSUnderlineStyle([])))
        expect(style.hoverUnderlineStyle).to(equal(NSUnderlineStyle.patternDot))
    }
    
    func testDefaultDarkWikilinkStyle() {
        let style = WikilinkStyle.defaultDark
        
        expect(style.textColor).to(equal(UniversalColor(hexString: "#0A84FF")))
        expect(style.backgroundColor).to(equal(UniversalColor.clear))
        expect(style.underlineStyle).to(equal(NSUnderlineStyle([])))
        expect(style.hoverUnderlineStyle).to(equal(NSUnderlineStyle.patternDot))
    }
    
    func testCustomWikilinkStyle() {
        let customStyle = WikilinkStyle(
            textColor: UniversalColor.red,
            backgroundColor: UniversalColor.yellow,
            underlineStyle: .single,
            hoverUnderlineStyle: .double
        )
        
        expect(customStyle.textColor).to(equal(UniversalColor.red))
        expect(customStyle.backgroundColor).to(equal(UniversalColor.yellow))
        expect(customStyle.underlineStyle).to(equal(NSUnderlineStyle.single))
        expect(customStyle.hoverUnderlineStyle).to(equal(NSUnderlineStyle.double))
    }
    
    // MARK: - Theme Integration Tests
    
    func testThemeHasWikilinkStyle() {
        let theme = Theme()
        
        expect(theme.wikilinkStyle).toNot(beNil())
        expect(theme.wikilinkStyle.textColor).to(equal(WikilinkStyle.defaultLight.textColor))
    }
    
    func testThemeBuiltInStyles() {
        let lightTheme = Theme.BuiltIn.defaultLight.theme()
        let darkTheme = Theme.BuiltIn.defaultDark.theme()
        
        expect(lightTheme.wikilinkStyle).toNot(beNil())
        expect(darkTheme.wikilinkStyle).toNot(beNil())
    }
    
    func testWikilinkStyleInAllMarkdownTypes() {
        let theme = Theme()
        
        // Ensure all markdown types including wikilink are present
        let allTypes = MarkdownNode.MarkdownType.allCases
        expect(allTypes).to(contain(MarkdownNode.MarkdownType.wikilink))
        
        // Ensure styles are initialized for all types
        for type in allTypes {
            expect(theme.styles[type]).toNot(beNil())
        }
    }
    
    // MARK: - MarkdownNode.MarkdownType Tests
    
    func testWikilinkMarkdownType() {
        let wikilinkType = MarkdownNode.MarkdownType.wikilink
        
        expect(wikilinkType.rawValue).to(equal(22))
        expect(MarkdownNode.MarkdownType.from(rawValue: 22, with: 0)).to(equal(.wikilink))
        expect(MarkdownNode.MarkdownType.from(string: "wikilink")).to(equal(.wikilink))
    }
    
    func testWikilinkMarkdownNode() {
        let range = NSRange(location: 0, length: 10)
        let node = MarkdownNode(range: range, type: .wikilink)
        
        expect(node.type).to(equal(.wikilink))
        expect(node.range).to(equal(range))
        expect(node.rawType).to(equal(22))
        expect(node.headingLevel).to(equal(0))
    }
}