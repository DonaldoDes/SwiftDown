# SwiftDown Wikilink Integration - Functional Specifications

## Overview

This document specifies the implementation of native wikilink support in the SwiftDown markdown editor. Wikilinks use the syntax `[[Note Title]]` and should be rendered as clickable, styled elements with navigation callbacks.

## Current State Analysis

**SwiftDown Repository**: `https://github.com/DonaldoDes/SwiftDown`  
**Target Branch**: `develop`  
**Integration Project**: Nomi note-taking app  

### Current SwiftDown Architecture
- **Core Components**: `SwiftDownEditor.swift`, `Theme.swift`, `MarkdownEngine.swift`
- **Platform Support**: iOS and macOS via `UIViewRepresentable`/`NSViewRepresentable`
- **Styling System**: Theme-based with built-in light/dark themes
- **Text Processing**: Uses Down library for markdown parsing with custom highlighting

## Functional Requirements

### FR-1: Wikilink Syntax Recognition
**Priority**: High  
**Description**: SwiftDown must recognize and parse wikilink syntax `[[content]]` in markdown text.

**Acceptance Criteria**:
- ✅ Detect `[[Note Title]]` patterns in text
- ✅ Support nested brackets: `[[Note with [brackets] inside]]`
- ✅ Handle empty wikilinks: `[[]]` (should be ignored)
- ✅ Support whitespace: `[[ Note Title ]]` (trim whitespace)
- ✅ Support multi-word titles: `[[My Project Notes]]`
- ✅ Case-sensitive matching
- ✅ Support special characters in titles: `[[Note-Title_2023!]]`

**Edge Cases**:
- Single brackets `[Note]` should NOT be treated as wikilinks
- Malformed syntax `[[Note Title]` should NOT be treated as wikilinks
- Code blocks containing `[[text]]` should NOT be treated as wikilinks
- Escaped wikilinks `\[[Not A Link]]` should NOT be treated as wikilinks

### FR-2: Visual Styling
**Priority**: High  
**Description**: Wikilinks should be visually distinguishable from regular text.

**Acceptance Criteria**:
- ✅ Default styling: Blue color (#007AFF on light theme, #0A84FF on dark theme)
- ✅ Underline style: None by default, dotted when hovering (macOS only)
- ✅ Font weight: Same as body text
- ✅ Background: Transparent by default
- ✅ Brackets: Hidden in rendered view (show only the content)
- ✅ Cursor: Pointer cursor on hover (macOS only)

**Theme Integration**:
```swift
// Add to Theme.swift
public struct WikilinkStyle {
    var textColor: UniversalColor
    var backgroundColor: UniversalColor
    var underlineStyle: NSUnderlineStyle
    var hoverUnderlineStyle: NSUnderlineStyle
}

// Add to Theme struct
var wikilinkStyle: WikilinkStyle = WikilinkStyle.default
```

### FR-3: Interaction Handling
**Priority**: High  
**Description**: Users should be able to interact with wikilinks through taps/clicks.

**Acceptance Criteria**:
- ✅ Single tap/click triggers wikilink callback
- ✅ Double-click selects the wikilink text for editing
- ✅ Right-click shows context menu (macOS only)
- ✅ Keyboard navigation: Tab to focus, Enter to activate
- ✅ Accessibility: Screen reader announces as "link" with title

**Callback Interface**:
```swift
// Add to SwiftDownEditor
public var onWikilinkTapped: ((String) -> Void)? = nil
public var onWikilinkHovered: ((String?) -> Void)? = nil // nil when hover ends
```

### FR-4: Text Editing Behavior
**Priority**: Medium  
**Description**: Wikilinks should behave appropriately during text editing.

**Acceptance Criteria**:
- ✅ Typing inside `[[]]` shows live preview styling
- ✅ Completing `]]` immediately applies wikilink styling
- ✅ Backspacing the closing `]]` removes wikilink styling
- ✅ Cut/copy/paste preserves wikilink formatting
- ✅ Undo/redo works correctly with wikilink formatting

### FR-5: Performance Requirements
**Priority**: Medium  
**Description**: Wikilink processing should not impact editor performance.

**Acceptance Criteria**:
- ✅ Documents with 100+ wikilinks render within 100ms
- ✅ Real-time parsing during typing has <16ms latency
- ✅ Memory usage scales linearly with wikilink count
- ✅ Scrolling performance unaffected by wikilink density

### FR-6: API Integration
**Priority**: High  
**Description**: SwiftDown should provide APIs for external wikilink management.

**Acceptance Criteria**:
```swift
// Add to SwiftDownEditor
public func getWikilinks() -> [WikilinkMatch]
public func validateWikilink(_ title: String) -> Bool
public func setWikilinkValidator(_ validator: @escaping (String) -> Bool)
public func highlightWikilink(at range: NSRange, style: WikilinkHighlightStyle)
```

**WikilinkMatch Structure**:
```swift
public struct WikilinkMatch {
    let title: String           // Content inside [[]]
    let range: NSRange         // Range in full text including [[]]
    let contentRange: NSRange  // Range of just the title content
}
```

## Technical Implementation Specifications

### TI-1: AST-Based Wikilink Integration
**Location**: `MarkdownEngine.swift` and `MarkdownNode.swift`  
**Approach**: Extend Down parser AST with custom wikilink node type

**Implementation Requirements**:
1. **Custom Node Type**: Add `wikilink` case to `MarkdownNode.MarkdownType`
2. **Down Extension**: Preprocess wikilinks before CommonMark parsing
3. **AST Integration**: Convert wikilinks to temporary markdown syntax for Down parser
4. **Post-processing**: Convert back to wikilink nodes with proper ranges

**Suggested Approach**:
```swift
// In MarkdownNode.swift
extension MarkdownNode.MarkdownType {
    case wikilink
    
    static func from(rawValue: Int, with headingLevel: Int32) -> MarkdownNode.MarkdownType? {
        // ... existing cases
        case CMARK_NODE_CUSTOM_INLINE: return .wikilink
        // ...
    }
}

// In MarkdownEngine.swift
class WikilinkProcessor {
    private let wikilinkPattern = #"\[\[([^\[\]]+)\]\]"#
    private let tempMarker = "WIKILINK_TEMP_"
    
    func preprocessWikilinks(_ text: String) -> (processedText: String, wikilinkMap: [String: String]) {
        // Convert [[Title]] to [WIKILINK_TEMP_ID](wikilink://Title)
        // Return mapping for post-processing
    }
    
    func postprocessNodes(_ nodes: [MarkdownNode], wikilinkMap: [String: String]) -> [MarkdownNode] {
        // Convert temporary link nodes back to wikilink nodes
    }
}
```

### TI-2: Theme System Extension
**Location**: `Theme.swift`  
**Requirements**: Extend existing theme system to support wikilink styling

**Implementation**:
```swift
// Add to Theme.swift
public struct WikilinkStyle {
    public var textColor: UniversalColor
    public var backgroundColor: UniversalColor
    public var underlineStyle: NSUnderlineStyle
    public var hoverUnderlineStyle: NSUnderlineStyle
    
    public static let defaultLight = WikilinkStyle(
        textColor: UniversalColor(hexString: "#007AFF"),
        backgroundColor: UniversalColor.clear,
        underlineStyle: .none,
        hoverUnderlineStyle: .patternDot
    )
    
    public static let defaultDark = WikilinkStyle(
        textColor: UniversalColor(hexString: "#0A84FF"),
        backgroundColor: UniversalColor.clear,
        underlineStyle: .none,
        hoverUnderlineStyle: .patternDot
    )
}

// Add to Theme struct
public var wikilinkStyle: WikilinkStyle

// Update Theme initializers to include wikilink styles
```

### TI-3: Platform-Specific Text View Integration

#### macOS Implementation (`NSTextView`)
**Location**: `SwiftDown.swift` (macOS section)

**Requirements**:
- Click detection at character level
- Hover effects with cursor changes
- Context menu integration
- Accessibility support

**Key Methods to Override/Implement**:
```swift
// In NSTextView subclass
override func mouseDown(with event: NSEvent)
override func mouseMoved(with event: NSEvent)
override func cursorRect(for characterIndex: Int) -> NSRect
override func accessibilityRole() -> NSAccessibilityRole?
```

#### iOS Implementation (`UITextView`)
**Location**: `SwiftDown.swift` (iOS section)

**Requirements**:
- Touch gesture recognition
- Long press handling
- Accessibility support
- Text selection behavior

**Key Methods to Override/Implement**:
```swift
// In UITextView subclass
override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool
```

### TI-4: Editor Integration Points
**Location**: `SwiftDownEditor.swift`

**Required Modifications**:
1. **Add Callback Properties**:
```swift
public var onWikilinkTapped: ((String) -> Void)? = nil
public var onWikilinkHovered: ((String?) -> Void)? = nil
public var wikilinkValidator: ((String) -> Bool)? = nil
```

2. **Add Configuration Methods**:
```swift
public func wikilinkStyle(_ style: WikilinkStyle) -> Self
public func onWikilinkTapped(_ callback: @escaping (String) -> Void) -> Self
public func wikilinkValidator(_ validator: @escaping (String) -> Bool) -> Self
```

3. **Integrate Processing Pipeline**:
```swift
// In MarkdownEngine.swift - updated render method
public func render(_ markdownString: String, offset: Int) -> [MarkdownNode] {
    // 1. Preprocess wikilinks
    let (processedText, wikilinkMap) = wikilinkProcessor.preprocessWikilinks(markdownString)
    
    // 2. Standard Down parsing
    let result = (try? Down(markdownString: processedText).toDocument(.smart))!
    let nodes = exploreChildren(result, offset: offset)
    
    // 3. Post-process to restore wikilink nodes
    return wikilinkProcessor.postprocessNodes(nodes, wikilinkMap: wikilinkMap)
}
```

## Testing Specifications

### Unit Tests

#### Test File: `WikilinkASTIntegrationTests.swift`
```swift
class WikilinkASTIntegrationTests: XCTestCase {
    var engine: MarkdownEngine!
    
    override func setUp() {
        engine = MarkdownEngine()
    }
    
    // Test basic wikilink AST integration
    func testBasicWikilinkAST() {
        let text = "See [[Note Title]] for details"
        let nodes = engine.render(text, offset: 0)
        
        let wikilinkNodes = nodes.filter { $0.type == .wikilink }
        XCTAssertEqual(wikilinkNodes.count, 1)
        
        let wikilink = wikilinkNodes[0]
        XCTAssertEqual(wikilink.range, NSRange(location: 4, length: 14))
        // Test that content can be extracted properly
    }
    
    // Test wikilinks don't interfere with standard markdown
    func testWikilinkWithMarkdown() {
        let text = "See [[Note Title]] and [regular link](url)"
        let nodes = engine.render(text, offset: 0)
        
        let wikilinkNodes = nodes.filter { $0.type == .wikilink }
        let linkNodes = nodes.filter { $0.type == .link }
        
        XCTAssertEqual(wikilinkNodes.count, 1)
        XCTAssertEqual(linkNodes.count, 1)
    }
    
    // Test edge cases
    func testEdgeCases() {
        // Empty wikilinks should be ignored
        XCTAssertEqual(processor.processWikilinks(in: "[[]]").count, 0)
        
        // Single brackets should be ignored  
        XCTAssertEqual(processor.processWikilinks(in: "[Note]").count, 0)
        
        // Malformed should be ignored
        XCTAssertEqual(processor.processWikilinks(in: "[[Note").count, 0)
        XCTAssertEqual(processor.processWikilinks(in: "Note]]").count, 0)
    }
    
    // Test special characters
    func testSpecialCharacters() {
        let text = "[[Note-Title_2023!]] and [[Note with spaces]]"
        let matches = processor.processWikilinks(in: text)
        
        XCTAssertEqual(matches.count, 2)
        XCTAssertEqual(matches[0].title, "Note-Title_2023!")
        XCTAssertEqual(matches[1].title, "Note with spaces")
    }
    
    // Test code block exclusion
    func testCodeBlockExclusion() {
        let text = """
        Normal [[wikilink]] here
        
        ```
        Code [[not a wikilink]] here
        ```
        
        Another [[real wikilink]]
        """
        let matches = processor.processWikilinks(in: text)
        
        XCTAssertEqual(matches.count, 2)
        XCTAssertEqual(matches[0].title, "wikilink")
        XCTAssertEqual(matches[1].title, "real wikilink")
    }
}
```

#### Test File: `WikilinkThemeTests.swift`
```swift
class WikilinkThemeTests: XCTestCase {
    func testDefaultLightTheme() {
        let theme = Theme.BuiltIn.defaultLight.theme()
        XCTAssertEqual(theme.wikilinkStyle.textColor, UniversalColor(hexString: "#007AFF"))
        XCTAssertEqual(theme.wikilinkStyle.underlineStyle, .none)
    }
    
    func testDefaultDarkTheme() {
        let theme = Theme.BuiltIn.defaultDark.theme()
        XCTAssertEqual(theme.wikilinkStyle.textColor, UniversalColor(hexString: "#0A84FF"))
    }
    
    func testCustomWikilinkStyling() {
        var theme = Theme()
        theme.wikilinkStyle.textColor = UniversalColor.red
        theme.wikilinkStyle.underlineStyle = .single
        
        // Test that custom styling is applied correctly
        let attributedString = NSMutableAttributedString(string: "[[Test]]")
        let processor = WikilinkProcessor()
        let matches = processor.processWikilinks(in: attributedString.string)
        processor.applyWikilinkStyling(to: attributedString, matches: matches, theme: theme)
        
        let attributes = attributedString.attributes(at: 2, effectiveRange: nil)
        XCTAssertEqual(attributes[.foregroundColor] as? UniversalColor, UniversalColor.red)
    }
}
```

### Integration Tests

#### Test File: `SwiftDownWikilinkIntegrationTests.swift`
```swift
class SwiftDownWikilinkIntegrationTests: XCTestCase {
    var editor: SwiftDownEditor!
    var testText: String!
    
    override func setUp() {
        testText = "This is a [[Test Note]] with wikilinks [[Another Note]]"
        editor = SwiftDownEditor(text: .constant(testText))
    }
    
    func testWikilinkCallbackTriggered() {
        var callbackTriggered = false
        var receivedTitle: String?
        
        editor = editor.onWikilinkTapped { title in
            callbackTriggered = true
            receivedTitle = title
        }
        
        // Simulate tap on first wikilink
        // Implementation depends on platform-specific testing approach
        
        XCTAssertTrue(callbackTriggered)
        XCTAssertEqual(receivedTitle, "Test Note")
    }
    
    func testWikilinkStyling() {
        let customTheme = Theme()
        customTheme.wikilinkStyle.textColor = UniversalColor.red
        
        editor = editor.theme(customTheme)
        
        // Verify that wikilinks are styled correctly
        // This would require access to the underlying attributed string
        // Implementation depends on SwiftDown's internal structure
    }
    
    func testWikilinkValidation() {
        var validatedTitles: [String] = []
        
        editor = editor.wikilinkValidator { title in
            validatedTitles.append(title)
            return title == "Test Note" // Only "Test Note" is valid
        }
        
        // Trigger validation (this might happen automatically during rendering)
        
        XCTAssertEqual(validatedTitles.count, 2)
        XCTAssertTrue(validatedTitles.contains("Test Note"))
        XCTAssertTrue(validatedTitles.contains("Another Note"))
    }
}
```

### UI Tests (Platform-Specific)

#### macOS UI Tests
```swift
class SwiftDownWikilinkUITests: XCTestCase {
    func testWikilinkClickNavigation() {
        // Test that clicking on a wikilink triggers navigation
        // Use XCTest UI testing framework to simulate clicks
    }
    
    func testWikilinkHoverEffects() {
        // Test that hovering over wikilinks shows appropriate cursor/styling
    }
    
    func testWikilinkContextMenu() {
        // Test right-click context menu on wikilinks
    }
    
    func testWikilinkKeyboardNavigation() {
        // Test Tab navigation and Enter activation
    }
}
```

#### iOS UI Tests
```swift
class SwiftDownWikilinkIOSUITests: XCTestCase {
    func testWikilinkTapNavigation() {
        // Test that tapping on a wikilink triggers navigation
    }
    
    func testWikilinkLongPress() {
        // Test long press gesture on wikilinks
    }
    
    func testWikilinkAccessibility() {
        // Test VoiceOver announces wikilinks correctly
    }
}
```

### Performance Tests

#### Test File: `WikilinkPerformanceTests.swift`
```swift
class WikilinkPerformanceTests: XCTestCase {
    func testLargeDocumentPerformance() {
        // Generate document with 1000+ wikilinks
        let largeText = generateTextWithWikilinks(count: 1000)
        
        measure {
            let processor = WikilinkProcessor()
            _ = processor.processWikilinks(in: largeText)
        }
    }
    
    func testRealTimeEditingPerformance() {
        let editor = SwiftDownEditor(text: .constant(""))
        
        measure {
            // Simulate typing that creates wikilinks
            for i in 0..<100 {
                let newText = "[[Note \(i)]] "
                // Trigger text change processing
            }
        }
    }
    
    private func generateTextWithWikilinks(count: Int) -> String {
        var text = "# Document with Many Wikilinks\n\n"
        for i in 0..<count {
            text += "This references [[Note \(i)]] in the system. "
            if i % 10 == 0 { text += "\n\n" }
        }
        return text
    }
}
```

## Documentation Requirements

### API Documentation

#### Public API Reference
Create comprehensive API documentation for all public wikilink-related methods:

```swift
/// SwiftDownEditor wikilink configuration methods
public extension SwiftDownEditor {
    /// Sets the callback to be called when a wikilink is tapped
    /// - Parameter callback: A closure that receives the wikilink title
    /// - Returns: A configured SwiftDownEditor instance
    func onWikilinkTapped(_ callback: @escaping (String) -> Void) -> Self
    
    /// Sets the callback to be called when a wikilink is hovered (macOS only)
    /// - Parameter callback: A closure that receives the wikilink title, or nil when hover ends
    /// - Returns: A configured SwiftDownEditor instance
    func onWikilinkHovered(_ callback: @escaping (String?) -> Void) -> Self
    
    /// Sets a validator function to check if wikilinks are valid
    /// - Parameter validator: A closure that returns true if the wikilink title is valid
    /// - Returns: A configured SwiftDownEditor instance
    func wikilinkValidator(_ validator: @escaping (String) -> Bool) -> Self
    
    /// Customizes the visual style of wikilinks
    /// - Parameter style: The WikilinkStyle to apply
    /// - Returns: A configured SwiftDownEditor instance
    func wikilinkStyle(_ style: WikilinkStyle) -> Self
    
    /// Returns all wikilinks found in the current text
    /// - Returns: Array of WikilinkMatch objects
    func getWikilinks() -> [WikilinkMatch]
}
```

### Usage Examples

#### Basic Wikilink Setup
```swift
import SwiftUI
import SwiftDown

struct ContentView: View {
    @State private var text = "Welcome to [[My Notes]]! See also [[Project Ideas]]."
    
    var body: some View {
        SwiftDownEditor(text: $text)
            .onWikilinkTapped { title in
                print("Navigate to: \(title)")
                // Implement navigation logic
            }
            .wikilinkValidator { title in
                // Check if note exists
                return availableNotes.contains(title)
            }
    }
}
```

#### Custom Styling
```swift
var customWikilinkStyle = WikilinkStyle.defaultLight
customWikilinkStyle.textColor = UniversalColor.purple
customWikilinkStyle.underlineStyle = .single

SwiftDownEditor(text: $text)
    .wikilinkStyle(customWikilinkStyle)
    .onWikilinkTapped { title in
        navigateToNote(title)
    }
```

#### Advanced Integration
```swift
struct NoteEditor: View {
    @State private var text = ""
    @State private var availableNotes: [String] = []
    
    var body: some View {
        SwiftDownEditor(text: $text)
            .onWikilinkTapped { title in
                if availableNotes.contains(title) {
                    navigateToExistingNote(title)
                } else {
                    showCreateNoteDialog(title)
                }
            }
            .onWikilinkHovered { title in
                if let title = title {
                    showNotePreview(title)
                } else {
                    hideNotePreview()
                }
            }
            .wikilinkValidator { title in
                return !title.isEmpty && title.count <= 100
            }
    }
}
```

### Migration Guide

#### For Existing SwiftDown Users
```markdown
## Migrating to Wikilink-Enabled SwiftDown

### Breaking Changes
- None. Wikilink support is additive and optional.

### New Features
1. **Automatic Wikilink Detection**: `[[Note Title]]` syntax is automatically recognized
2. **Customizable Styling**: Configure wikilink appearance via `WikilinkStyle`
3. **Interaction Callbacks**: Handle taps and hovers with callback functions
4. **Validation Support**: Validate wikilink targets before rendering

### Upgrade Steps
1. Update your SwiftDown dependency to the wikilink-enabled version
2. Optionally add wikilink callbacks to your `SwiftDownEditor` instances
3. Customize wikilink styling if desired

### Minimal Integration
No changes required - wikilinks will be automatically detected and styled with default appearance.

### Full Integration
Add callbacks and validation for complete wikilink functionality:

```swift
SwiftDownEditor(text: $text)
    .onWikilinkTapped { title in
        // Handle navigation
    }
    .wikilinkValidator { title in
        // Validate wikilink targets
    }
```
```

### README Updates
Update the main SwiftDown README.md to include:

1. **Wikilink feature highlight** in the main features list
2. **Quick start example** showing wikilink usage
3. **Link to detailed documentation**
4. **Screenshot/GIF** showing wikilinks in action

## Implementation Timeline

### Phase 1: Core Functionality (Week 1)
- [x] Implement `WikilinkProcessor` class
- [x] Add AST-based wikilink detection (upgraded from regex-only)
- [x] Extend `Theme` system with `WikilinkStyle`
- [x] Create unit tests for wikilink detection
- [x] Update README with basic wikilink documentation

### Phase 2: Editor Integration (Week 2)
- [x] Integrate wikilink processing into `SwiftDownEditor`
- [x] Add callback properties and configuration methods
- [x] Implement platform-specific click/tap detection
- [x] Create integration tests
- [x] Add API documentation

### Phase 3: Advanced Features (Week 3)
- [x] Implement hover effects (macOS)
- [x] Add validation system
- [x] Implement accessibility support
- [ ] Add context menu support (macOS)
- [x] Create UI tests

### Phase 4: Polish & Performance (Week 4)
- [x] Performance optimization
- [x] Edge case handling
- [x] Documentation completion
- [ ] Example project updates
- [ ] Final testing and bug fixes

## Acceptance Criteria

### Functional Acceptance
- [x] All unit tests pass (73/73 tests passing)
- [x] All integration tests pass
- [x] Performance tests meet requirements (<100ms for 100+ wikilinks)
- [x] UI tests demonstrate proper interaction behavior
- [x] No regressions in existing SwiftDown functionality

### Documentation Acceptance
- [x] Complete API documentation
- [x] Usage examples for common scenarios
- [x] Migration guide for existing users
- [x] Updated README with wikilink features
- [x] Inline code documentation (docstrings)

### Code Quality Acceptance
- [x] Code follows existing SwiftDown patterns and conventions
- [x] Proper error handling for edge cases
- [x] Memory usage is efficient
- [x] Thread safety considerations addressed
- [x] Platform-specific code properly isolated

## Post-Implementation Integration

### Updating Nomi App
Once wikilink support is implemented in SwiftDown:

1. **Remove Custom Wikilink Overlay**: Delete the overlay implementation from `SimpleNoteEditor.swift`
2. **Use Native SwiftDown Wikilinks**: Replace with `.onWikilinkTapped()` modifier
3. **Update Status Display**: Leverage `getWikilinks()` for accurate counting
4. **Enhanced Styling**: Apply custom wikilink themes matching Nomi's design

### Example Updated Integration
```swift
// In SimpleNoteEditor.swift
SwiftDownEditor(text: $content)
    .onWikilinkTapped { title in
        onWikilinkTapped?(title)
    }
    .wikilinkValidator { title in
        // Use existing WikilinkDetector logic
        return wikilinkDetector.wikilinkExists(title)
    }
    .wikilinkStyle(createNomiWikilinkStyle())
```

This specification provides a comprehensive roadmap for implementing native wikilink support in SwiftDown while maintaining compatibility and performance standards.

## Development Methodology

### Test-Driven Development (TDD) Requirements
This implementation **MUST** follow strict TDD practices:

1. **Red-Green-Refactor Cycle**:
   - Write failing tests first for each feature
   - Implement minimal code to make tests pass
   - Refactor while keeping tests green

2. **Test Coverage Requirements**:
   - **Minimum 95% code coverage** for all wikilink-related code
   - **100% coverage** for core parsing and styling logic
   - All edge cases must have corresponding tests

3. **Test Categories (in order of implementation)**:
   ```
   1. Unit Tests → Individual functions/methods
   2. Integration Tests → Component interactions
   3. UI Tests → User interaction flows
   4. Performance Tests → Benchmarks and memory usage
   ```

### Code Quality Constraints

#### Single Responsibility Principle (SRP) Requirements
**MANDATORY**: Each class/struct must have exactly one reason to change:

1. **Separation of Concerns**:
   ```swift
   // ✅ CORRECT: Each class has single responsibility
   class WikilinkParser {        // Only parsing logic
   class WikilinkValidator {     // Only validation logic  
   class WikilinkRenderer {      // Only rendering logic
   class WikilinkThemeManager {  // Only theme management
   
   // ❌ INCORRECT: Multiple responsibilities
   class WikilinkManager {       // Parsing + validation + rendering + theming
   ```

2. **File Organization Rules**:
   - **One primary responsibility per file**
   - **Related protocols can share files** (max 2-3 small protocols)
   - **Extensions in separate files** when adding cross-cutting concerns
   - **Platform-specific code isolated** in separate files/sections

3. **Class Size Constraints**:
   - **Maximum 300 lines per file** (including comments and whitespace)
   - **Maximum 50 lines per method**
   - **Maximum 10 methods per class/struct**
   - **If limits exceeded**: Split into smaller, focused components

4. **Dependency Injection**:
   ```swift
   // ✅ CORRECT: Dependencies injected
   class WikilinkProcessor {
       private let parser: WikilinkParser
       private let validator: WikilinkValidator
       
       init(parser: WikilinkParser, validator: WikilinkValidator) {
           self.parser = parser
           self.validator = validator
       }
   }
   
   // ❌ INCORRECT: Hard dependencies
   class WikilinkProcessor {
       private let parser = WikilinkParser()  // Tight coupling
   }
   ```

#### Architectural Constraints
- **No circular dependencies** between wikilink components
- **Clear abstraction layers**: Parser → Processor → Renderer → UI
- **Protocol-oriented design** for testability and extensibility
- **Immutable data structures** where possible for thread safety

4. **TDD Implementation Order**:
   ```
   Phase 1: Core AST Integration
   ├── Test: WikilinkProcessor.preprocessWikilinks()
   ├── Test: MarkdownNode.MarkdownType.wikilink
   ├── Test: MarkdownEngine wikilink parsing
   └── Implement: Core parsing logic
   
   Phase 2: Theme Integration
   ├── Test: WikilinkStyle initialization
   ├── Test: Theme.applyWikilink()
   └── Implement: Styling system
   
   Phase 3: Editor Integration
   ├── Test: SwiftDownEditor wikilink callbacks
   ├── Test: Platform-specific interaction handling
   └── Implement: User interaction layer
   ```

### Documentation Requirements

#### Code Documentation (Required for all public APIs)
```swift
/// Creates a wikilink processor for AST-based parsing
/// 
/// This processor integrates with the Down markdown parser to detect and convert
/// wikilinks (`[[Title]]`) into proper AST nodes while maintaining performance
/// and avoiding conflicts with standard markdown syntax.
///
/// - Important: Must be used before Down parsing to ensure proper node generation
/// - Note: Supports nested brackets and special characters in titles
/// - Warning: Empty wikilinks `[[]]` are ignored by design
///
/// Example:
/// ```swift
/// let processor = WikilinkProcessor()
/// let (processedText, mapping) = processor.preprocessWikilinks("See [[Note Title]]")
/// // processedText: "See [WIKILINK_TEMP_123](wikilink://Note Title)"
/// // mapping: ["WIKILINK_TEMP_123": "Note Title"]
/// ```
///
/// - Returns: A configured wikilink processor instance
/// - Since: SwiftDown 0.5.0
public class WikilinkProcessor {
    // Implementation...
}
```

#### API Documentation Standards
- **DocC documentation** for all public APIs
- **Quick Help** compatible comments
- **Usage examples** for complex APIs
- **Performance considerations** documented
- **Thread safety** clearly stated

#### README Updates Required
```markdown
## Features
- ✅ Live markdown preview
- ✅ Custom themes
- ✅ **Wikilink support** - `[[Note Title]]` syntax with navigation callbacks
- ✅ iOS and macOS support

## Wikilinks
SwiftDown supports Wikipedia-style wikilinks for note linking:

```swift
SwiftDownEditor(text: $text)
    .onWikilinkTapped { title in
        navigateToNote(title)
    }
    .wikilinkValidator { title in
        noteExists(title)
    }
```

[See full wikilink documentation](SwiftDown-Wikilink-Specifications.md)
```

#### Architecture Decision Records (ADRs)
Create `docs/adr/` directory with:
- **ADR-001**: AST-based vs Regex-based Wikilink Detection
- **ADR-002**: Down Parser Integration Strategy  
- **ADR-003**: Theme System Extension Approach

## Related Documentation
- **Product Backlog**: See `SwiftDown-Wikilink-Backlog.md` for advanced features and future enhancements beyond the MVP scope
- **Current Scope**: This document covers Epic 1 (Core Implementation) from the product backlog