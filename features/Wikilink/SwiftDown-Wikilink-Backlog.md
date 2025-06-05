# SwiftDown Wikilink Feature - Product Backlog

## Overview
This backlog contains advanced features and improvements for the wikilink implementation in SwiftDown, organized by priority and implementation complexity.

**Related Documentation**: See [SwiftDown-Wikilink-Specifications.md](./SwiftDown-Wikilink-Specifications.md) for detailed functional and technical implementation specifications.

## 🔄 DEVELOPMENT PROCESS

**RULE**: Implement ONE user story at a time. Request user validation before proceeding to next story.

### Process:
1. Implement user story (tests + code + docs)
2. Request user validation 
3. Wait for approval
4. Mark complete and move to next story

---

## Epic 0: Critical Missing API Implementation (BLOCKING)
**Status**: ❌ **NOT STARTED** - BLOCKING ALL INTEGRATION  
**Priority**: P0 (CRITICAL - BLOCKING)  
**Estimated Effort**: 1 sprint  
**Impact**: Nomi app cannot integrate without these features

### User Stories

#### Core API Requirements (PENDING)
- [ ] **SW-001**: As a developer, I can pass `onWikilinkTapped` parameter to SwiftDownEditor initializer
- [ ] **SW-002**: As a developer, I can use `.onWikilinkTapped()` modifier method on SwiftDownEditor  
- [ ] **SW-003**: As a developer, I can use `.wikilinkValidator()` modifier method on SwiftDownEditor
- [ ] **SW-004**: As a developer, I can use `.wikilinkStyle()` modifier method on SwiftDownEditor

#### Essential Detection System (PENDING)
- [ ] **SW-005**: As a user, I can see `[[wikilink]]` patterns automatically detected in text
- [ ] **SW-006**: As a user, I can tap/click on detected wikilinks to trigger callbacks
- [ ] **SW-007**: As a user, I can see wikilinks styled with custom colors and formatting
- [ ] **SW-008**: As a developer, I can retrieve all wikilinks found in current text via `getWikilinks()`

#### Theme Integration (PENDING)
- [ ] **SW-009**: As a developer, I can define WikilinkStyle with textColor, backgroundColor, underlineStyle
- [ ] **SW-010**: As a developer, I can add wikilinkStyle property to existing Theme struct
- [ ] **SW-011**: As a user, I can see wikilinks styled according to light/dark theme
- [ ] **SW-012**: As a developer, I can access defaultLight and defaultDark WikilinkStyle presets

**Real-World Integration Issues Addressed**:
- ✅ Fixes build error: `extra argument 'onWikilinkTapped' in call`
- ✅ Enables automatic `[[Note Title]]` pattern recognition  
- ✅ Provides click/tap detection capabilities
- ✅ Allows wikilink styling and theme customization

**Critical API Requirements**:
```swift
// MUST IMPLEMENT: SwiftDownEditor API extension
public init(
    text: Binding<String>,
    onTextChange: @escaping (String) -> Void = { _ in },
    onSelectionChange: @escaping (NSRange) -> Void = { _ in },
    onWikilinkTapped: ((String) -> Void)? = nil  // MISSING PARAMETER
)

// MUST IMPLEMENT: Modifier methods
public func onWikilinkTapped(_ callback: @escaping (String) -> Void) -> Self
public func wikilinkValidator(_ validator: @escaping (String) -> Bool) -> Self  
public func wikilinkStyle(_ style: WikilinkStyle) -> Self

// MUST IMPLEMENT: WikilinkStyle struct
public struct WikilinkStyle {
    public var textColor: UniversalColor
    public var backgroundColor: UniversalColor
    public var underlineStyle: NSUnderlineStyle
    public var hoverUnderlineStyle: NSUnderlineStyle
}

// MUST IMPLEMENT: Theme extension
extension Theme {
    public var wikilinkStyle: WikilinkStyle { get set }
}

// MUST IMPLEMENT: Detection classes
public class WikilinkProcessor {
    public func extractWikilinks(from text: String) -> [WikilinkMatch]
    public func detectWikilinkAt(position: Int, in text: String) -> WikilinkMatch?
}

public struct WikilinkMatch {
    public let title: String
    public let range: NSRange
    public let contentRange: NSRange
}
```

**TDD Requirements for Epic 0**:
```swift
// FIRST: Write failing tests for missing API
class SwiftDownEditorAPITests: XCTestCase {
    func testWikilinkTappedParameter() {
        // Test that onWikilinkTapped parameter exists and works
        let editor = SwiftDownEditor(
            text: .constant(""),
            onWikilinkTapped: { _ in }  // Must not cause build error
        )
        XCTAssertNotNil(editor)
    }
    
    func testWikilinkModifierMethods() {
        // Test that modifier methods exist and chain properly
        let editor = SwiftDownEditor(text: .constant(""))
            .onWikilinkTapped { _ in }
            .wikilinkValidator { _ in true }
            .wikilinkStyle(WikilinkStyle.defaultLight)
        XCTAssertNotNil(editor)
    }
    
    func testWikilinkDetection() {
        // Test that wikilinks are detected automatically
        let processor = WikilinkProcessor()
        let matches = processor.extractWikilinks(from: "See [[Note Title]]")
        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches[0].title, "Note Title")
    }
}
```

---

## Epic 1: Core Wikilink Implementation (MVP)
**Status**: 🔄 **PARTIALLY COMPLETED** (Missing Epic 0 Dependencies)  
**Priority**: P0 (Critical)

### User Stories
- [x] **SW-001**: As a user, I can create wikilinks using `[[Note Title]]` syntax
- [x] **SW-002**: As a user, I can tap/click wikilinks to navigate
- [x] **SW-003**: As a user, I can see wikilinks styled differently from regular text
- [x] **SW-004**: As a developer, I can configure wikilink callbacks and validation

**Implementation Notes**: 
- Uses AST-based detection through Down parser extension
- Basic theme integration with light/dark mode support
- Platform-specific interaction handling (iOS/macOS)

---

## Epic 2: Enhanced Interaction Model
**Status**: Backlog  
**Priority**: P1 (High)  
**Estimated Effort**: 2-3 sprints

### User Stories

#### Gesture Recognition System
- [ ] **SW-101**: As a user, I can long-press wikilinks on iOS for context menu
- [ ] **SW-102**: As a user, I can right-click wikilinks on macOS for context menu
- [ ] **SW-103**: As a user, I can use secondary gestures for wikilink actions

#### Keyboard Navigation
- [ ] **SW-104**: As a user, I can use Cmd+K to create wikilinks around selected text
- [ ] **SW-105**: As a user, I can Tab through wikilinks for keyboard navigation
- [ ] **SW-106**: As a user, I can use Enter to activate focused wikilinks
- [ ] **SW-107**: As a user, I can use Escape to cancel wikilink creation

#### Drag & Drop Support
- [ ] **SW-108**: As a user, I can drag text onto existing text to create wikilinks
- [ ] **SW-109**: As a user, I can drag wikilinks to reorder or move them
- [ ] **SW-110**: As a user, I can drop external content to create new wikilinks

#### Multi-Selection
- [ ] **SW-111**: As a user, I can select multiple wikilinks for batch operations
- [ ] **SW-112**: As a user, I can apply bulk styling to selected wikilinks
- [ ] **SW-113**: As a user, I can delete multiple wikilinks at once

**Technical Requirements**:
```swift
// Enhanced gesture recognition
public struct WikilinkGestureConfig {
    var longPressDelay: TimeInterval = 0.5
    var tapToSelect: Bool = true
    var multiSelectionEnabled: Bool = false
}

// Keyboard shortcut support
public struct WikilinkKeyboardShortcuts {
    var createWikilink: KeyEquivalent = .init("k", modifiers: .command)
    var navigateNext: KeyEquivalent = .tab
    var activate: KeyEquivalent = .return
}
```

---

## Epic 3: Advanced Styling & Validation
**Status**: Backlog  
**Priority**: P1 (High)  
**Estimated Effort**: 1-2 sprints

### User Stories

#### State-Based Styling
- [ ] **SW-201**: As a user, I can see different styles for valid vs invalid wikilinks
- [ ] **SW-202**: As a user, I can see loading indicators for async validation
- [ ] **SW-203**: As a user, I can see different styles for different wikilink types
- [ ] **SW-204**: As a user, I can see visual feedback for wikilink creation/editing

#### Animation Support
- [ ] **SW-205**: As a user, I can see smooth hover transitions on macOS
- [ ] **SW-206**: As a user, I can see fade-in animations for new wikilinks
- [ ] **SW-207**: As a user, I can see pulse effects for invalid wikilinks
- [ ] **SW-208**: As a user, I can disable animations for accessibility

#### Custom Decorators
- [ ] **SW-209**: As a user, I can see icons next to different wikilink types
- [ ] **SW-210**: As a user, I can see badges indicating wikilink status
- [ ] **SW-211**: As a user, I can see preview tooltips on hover (macOS)
- [ ] **SW-212**: As a developer, I can add custom decorators to wikilinks

#### Semantic Validation
- [ ] **SW-213**: As a user, I can validate wikilinks asynchronously
- [ ] **SW-214**: As a user, I can see suggestions for similar existing notes
- [ ] **SW-215**: As a user, I can auto-complete wikilink titles
- [ ] **SW-216**: As a developer, I can implement custom validation logic

**Technical Requirements**:
```swift
// Enhanced styling system
public struct WikilinkStyle {
    var validState: WikilinkStateStyle
    var invalidState: WikilinkStateStyle
    var loadingState: WikilinkStateStyle
    var decorators: [WikilinkDecorator]
    var animations: WikilinkAnimationConfig
}

// Async validation
public protocol WikilinkValidator {
    func validate(_ title: String) async -> WikilinkValidationResult
    func suggestions(for partial: String) async -> [String]
}
```

---

## Epic 4: Accessibility & Internationalization
**Status**: Backlog  
**Priority**: P2 (Medium)  
**Estimated Effort**: 1 sprint

### User Stories

#### VoiceOver Optimization
- [ ] **SW-301**: As a VoiceOver user, I can hear wikilink titles announced clearly
- [ ] **SW-302**: As a VoiceOver user, I can access custom actions for wikilinks
- [ ] **SW-303**: As a VoiceOver user, I can navigate between wikilinks efficiently
- [ ] **SW-304**: As a VoiceOver user, I can hear wikilink validation status

#### RTL Language Support
- [ ] **SW-305**: As a user, I can use wikilinks in right-to-left languages
- [ ] **SW-306**: As a user, I can see proper text direction for mixed content
- [ ] **SW-307**: As a user, I can see correct cursor positioning in RTL text

#### High Contrast Themes
- [ ] **SW-308**: As a user, I can see wikilinks in high contrast mode
- [ ] **SW-309**: As a user, I can use custom accessibility color schemes
- [ ] **SW-310**: As a user, I can adjust wikilink contrast independently

#### Screen Reader Support
- [ ] **SW-311**: As a screen reader user, I can hear context-aware descriptions
- [ ] **SW-312**: As a screen reader user, I can navigate by wikilink landmarks
- [ ] **SW-313**: As a screen reader user, I can hear wikilink creation feedback

**Technical Requirements**:
```swift
// Accessibility configuration
public struct WikilinkAccessibilityConfig {
    var announceValidation: Bool = true
    var customActions: [WikilinkAccessibilityAction] = []
    var landmarkNavigation: Bool = true
    var contextualDescriptions: Bool = true
}

// RTL support
public struct WikilinkDirectionality {
    var baseDirection: NSWritingDirection = .natural
    var respectsDocumentDirection: Bool = true
    var mixedContentHandling: MixedDirectionHandling = .automatic
}
```

---

## Epic 5: Modern SwiftUI Integration
**Status**: Backlog  
**Priority**: P2 (Medium)  
**Estimated Effort**: 2 sprints

### User Stories

#### Observable Pattern Integration
- [ ] **SW-401**: As a developer, I can use `@Observable` for wikilink state (iOS 17+)
- [ ] **SW-402**: As a developer, I can bind wikilink data to SwiftUI state
- [ ] **SW-403**: As a developer, I can observe wikilink changes reactively

#### SwiftUI State Management
- [ ] **SW-404**: As a developer, I can integrate with `@State` and `@Binding`
- [ ] **SW-405**: As a developer, I can use `@StateObject` for wikilink management
- [ ] **SW-406**: As a developer, I can share wikilink state across views

#### Enhanced View Modifiers
- [ ] **SW-407**: As a developer, I can use fluent modifier API for configuration
- [ ] **SW-408**: As a developer, I can chain wikilink modifiers naturally
- [ ] **SW-409**: As a developer, I can use conditional modifiers for wikilinks

#### Environment Integration
- [ ] **SW-410**: As a developer, I can inherit wikilink themes from environment
- [ ] **SW-411**: As a developer, I can provide wikilink services via environment
- [ ] **SW-412**: As a developer, I can override wikilink behavior per view hierarchy

**Technical Requirements**:
```swift
// Modern SwiftUI API
@Observable
class WikilinkStore {
    var wikilinks: [WikilinkModel] = []
    var validationService: WikilinkValidationService?
}

// Environment integration
struct WikilinkEnvironmentKey: EnvironmentKey {
    static let defaultValue = WikilinkConfiguration.default
}

extension EnvironmentValues {
    var wikilinkConfig: WikilinkConfiguration {
        get { self[WikilinkEnvironmentKey.self] }
        set { self[WikilinkEnvironmentKey.self] = newValue }
    }
}
```

---

## Epic 6: Performance & Scalability
**Status**: Backlog  
**Priority**: P2 (Medium)  
**Estimated Effort**: 1-2 sprints

### User Stories

#### Lazy Evaluation
- [ ] **SW-501**: As a user, I can work with large documents without performance loss
- [ ] **SW-502**: As a user, I can see smooth scrolling with many wikilinks
- [ ] **SW-503**: As a developer, I can enable viewport-based parsing

#### Caching & Optimization
- [ ] **SW-504**: As a user, I can benefit from cached wikilink parsing
- [ ] **SW-505**: As a user, I can see fast re-renders after theme changes
- [ ] **SW-506**: As a developer, I can configure caching strategies

#### Memory Management
- [ ] **SW-507**: As a user, I can work with documents without memory leaks
- [ ] **SW-508**: As a developer, I can monitor wikilink memory usage
- [ ] **SW-509**: As a developer, I can implement custom memory policies

**Technical Requirements**:
```swift
// Performance configuration
public struct WikilinkPerformanceConfig {
    var lazyParsingEnabled: Bool = true
    var viewportParsingThreshold: Int = 100
    var cacheSize: Int = 1000
    var memoryPressureHandling: MemoryPressurePolicy = .automatic
}

// Metrics collection
public protocol WikilinkMetricsCollector {
    func recordParsingTime(_ duration: TimeInterval)
    func recordMemoryUsage(_ bytes: Int)
    func recordCacheHit(_ hit: Bool)
}
```

---

## Epic 7: Developer Experience
**Status**: Backlog  
**Priority**: P3 (Low)  
**Estimated Effort**: 1 sprint

### User Stories

#### Live Preview Support
- [ ] **SW-601**: As a developer, I can see wikilinks in Xcode canvas previews
- [ ] **SW-602**: As a developer, I can test wikilink interactions in previews
- [ ] **SW-603**: As a developer, I can preview different wikilink themes

#### Debug & Profiling
- [ ] **SW-604**: As a developer, I can enable visual debug indicators
- [ ] **SW-605**: As a developer, I can see wikilink parsing performance metrics
- [ ] **SW-606**: As a developer, I can trace wikilink interaction events

#### Migration Utilities
- [ ] **SW-607**: As a developer, I can convert between wikilink formats
- [ ] **SW-608**: As a developer, I can migrate from regex-based implementations
- [ ] **SW-609**: As a developer, I can batch process wikilink transformations

**Technical Requirements**:
```swift
// Debug support
public struct WikilinkDebugConfig {
    var visualIndicators: Bool = false
    var performanceLogging: Bool = false
    var interactionTracing: Bool = false
}

// Migration utilities
public class WikilinkMigrationTool {
    func convertFromRegex(_ text: String) -> String
    func batchProcess(_ documents: [String]) async -> [String]
    func validateMigration(_ original: String, _ migrated: String) -> Bool
}
```

---

## Epic 8: Advanced Features
**Status**: Future Consideration  
**Priority**: P3 (Low)  
**Estimated Effort**: 3+ sprints

### User Stories

#### Bi-directional Links
- [ ] **SW-701**: As a user, I can see backlinks to current note
- [ ] **SW-702**: As a user, I can navigate bidirectionally between notes
- [ ] **SW-703**: As a developer, I can implement link graph analysis

#### Link Previews
- [ ] **SW-704**: As a user, I can see note previews on hover/long-press
- [ ] **SW-705**: As a user, I can see embedded content in previews
- [ ] **SW-706**: As a developer, I can customize preview content

#### Smart Suggestions
- [ ] **SW-707**: As a user, I can see AI-powered link suggestions
- [ ] **SW-708**: As a user, I can auto-create links based on content
- [ ] **SW-709**: As a developer, I can integrate ML models for suggestions

#### Link Types & Metadata
- [ ] **SW-710**: As a user, I can create typed wikilinks (person, place, concept)
- [ ] **SW-711**: As a user, I can see link metadata in tooltips
- [ ] **SW-712**: As a developer, I can extend wikilink schema

---

## Implementation Priorities

### Phase 1: Foundation (Current Specs)
- Epic 1: Core Wikilink Implementation
- Basic AST integration and theming

### Phase 2: Enhanced UX  
- Epic 2: Enhanced Interaction Model
- Epic 3: Advanced Styling & Validation

### Phase 3: Accessibility & Modern APIs
- Epic 4: Accessibility & Internationalization  
- Epic 5: Modern SwiftUI Integration

### Phase 4: Optimization & DX
- Epic 6: Performance & Scalability
- Epic 7: Developer Experience

### Phase 5: Advanced Features
- Epic 8: Advanced Features (Future)

## Definition of Done

### All User Stories Must Include:
- [ ] **TDD Compliance**: Tests written before implementation (Red-Green-Refactor)
- [ ] **Code Coverage**: Unit tests with >95% coverage (100% for core logic)
- [ ] **Integration Tests**: Component interaction verification
- [ ] **SRP Compliance**: Single responsibility per class/file (<300 lines max)
- [ ] **Architecture Review**: Clear separation of concerns verified
- [ ] **API Documentation**: DocC-compatible documentation with examples
- [ ] **Usage Examples**: Working code samples in documentation
- [ ] **Accessibility Verification**: VoiceOver and keyboard navigation tested
- [ ] **Performance Benchmarks**: Where applicable, with baseline comparisons

### Epic Completion Criteria:
- [ ] **All user stories completed** following TDD methodology
- [ ] **End-to-end testing passed** across iOS and macOS platforms
- [ ] **Performance requirements met** (parsing <100ms for 100+ wikilinks)
- [ ] **Documentation updated** including README, API docs, and ADRs
- [ ] **Demo/example updated** with new functionality showcase
- [ ] **Code review completed** with team approval
- [ ] **Accessibility audit passed** with assistive technology verification

### TDD Quality Gates:
- [ ] **Red Phase**: All tests fail initially (feature not implemented)
- [ ] **Green Phase**: Minimal implementation makes tests pass
- [ ] **Refactor Phase**: Code quality improved while maintaining green tests
- [ ] **Coverage Gate**: Minimum coverage thresholds met
- [ ] **Performance Gate**: No regressions in benchmark tests

### Code Quality Gates:
- [ ] **SRP Gate**: Each file has single responsibility and <300 lines
- [ ] **Dependency Gate**: No circular dependencies, proper injection used
- [ ] **Architecture Gate**: Clear abstraction layers maintained
- [ ] **Protocol Gate**: Interfaces defined for testability and extensibility
- [ ] **Method Size Gate**: No method exceeds 50 lines
- [ ] **Class Size Gate**: No class exceeds 10 methods

### Mandatory File Structure Requirements:
```
Sources/SwiftDown/Wikilink/
├── Core/
│   ├── WikilinkParser.swift           # <300 lines, parsing only
│   ├── WikilinkValidator.swift        # <300 lines, validation only
│   └── WikilinkNode.swift            # <300 lines, data models only
├── Processing/
│   ├── WikilinkProcessor.swift        # <300 lines, orchestration only
│   └── WikilinkRenderer.swift        # <300 lines, rendering only
├── Theme/
│   ├── WikilinkStyle.swift           # <300 lines, styling only
│   └── WikilinkThemeManager.swift    # <300 lines, theme management only
├── UI/
│   ├── WikilinkInteraction+iOS.swift  # <300 lines, iOS interactions only
│   └── WikilinkInteraction+macOS.swift # <300 lines, macOS interactions only
└── Protocols/
    └── WikilinkProtocols.swift       # <300 lines, interfaces only
```

---

## 🚨 CURRENT STATUS: CRITICAL BLOCKING ISSUES

### Executive Summary
**Status**: ❌ **INTEGRATION BLOCKED**  
**Impact**: **Nomi app cannot use SwiftDown wikilinks**  
**Root Cause**: **Epic 0 API components completely missing**

### Immediate Action Required
The SwiftDown library currently **DOES NOT HAVE** any wikilink implementation. Based on real-world integration testing with the Nomi note-taking app, the following critical components are entirely missing:

#### Missing Core Components:
1. ❌ **SwiftDownEditor API**: No `onWikilinkTapped` parameter or modifier methods
2. ❌ **WikilinkProcessor**: No wikilink detection or processing classes  
3. ❌ **WikilinkStyle**: No theme system integration for wikilinks
4. ❌ **Interaction Handling**: No click/tap detection for wikilinks
5. ❌ **AST Integration**: No markdown engine extension for wikilinks

### Integration Failure Evidence:
```swift
// CURRENT: This code causes build error
SwiftDownEditor(
    text: $content,
    onWikilinkTapped: { title in ... }  // ❌ Build Error: "extra argument"
)

// WORKAROUND: Nomi app forced to show pending status
"SwiftDown + Wikilinks: Pending Implementation"
```

### Implementation Priority:
**MUST COMPLETE FIRST**: Epic 0 (Critical Missing API Implementation)
- **Before**: Any other epic can be started
- **Estimated**: 1 sprint (1-2 weeks)
- **Deliverable**: Basic functional API that enables integration

### Success Criteria for Epic 0:
- [ ] Nomi app builds without errors when using wikilink API
- [ ] Basic `[[wikilink]]` detection and styling works
- [ ] Simple click/tap navigation triggers callbacks
- [ ] Theme integration allows color customization

**Next Steps**: Assign Epic 0 to AI agent for immediate implementation following TDD methodology and architectural constraints outlined in this document.