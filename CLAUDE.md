# Claude Code AI Agent Instructions

This file contains instructions and context for Claude Code AI agents working on the SwiftDown project.

## 🎯 Project Overview

**SwiftDown** is an enhanced fork of [qeude/SwiftDown](https://github.com/qeude/SwiftDown) - a markdown editor component for SwiftUI applications with comprehensive wikilink support.

### Fork Status
- **Original**: `qeude/SwiftDown` (upstream)
- **Enhanced Fork**: `DonaldoDes/SwiftDown` (this repository)
- **Main Branch**: `develop`
- **Package URL**: `https://github.com/DonaldoDes/SwiftDown.git`

## 🏗️ Architecture

### Core Components
```
Sources/SwiftDown/
├── SwiftDownEditor.swift      # Main SwiftUI component with wikilink API
├── SwiftDown.swift           # Core text view with platform-specific handling
├── MarkdownEngine.swift      # AST processing with wikilink integration
├── WikilinkProcessor.swift   # Wikilink detection and processing
├── Theme.swift              # Theming system with WikilinkStyle
├── MarkdownNode.swift       # AST nodes including .wikilink type
└── [other markdown components]
```

### Test Coverage
- **Location**: `Tests/SwiftDownTests/`
- **Coverage**: 73+ tests passing including comprehensive wikilink functionality
- **Key Test Files**: 
  - `SwiftDownEditorWikilinkTests.swift`
  - `WikilinkProcessorTests.swift`
  - `WikilinkStyleTests.swift`
  - `WikilinkAST IntegrationTests.swift`

## 🔗 Wikilink Implementation Status

### Epic 0: ✅ COMPLETED
All core wikilink functionality is implemented and tested:
- SwiftDownEditor API with callbacks
- AST-based wikilink detection
- Theme integration
- Platform-specific interactions (iOS/macOS)
- Programmatic wikilink extraction/validation

### API Reference
```swift
// Basic usage
SwiftDownEditor(text: $text)
    .onWikilinkTapped { title in /* navigation */ }
    .wikilinkValidator { title in /* validation */ }
    .wikilinkStyle(WikilinkStyle.defaultLight)
    .theme(Theme.BuiltIn.defaultLight.theme())

// Data extraction
let wikilinks = editor.getWikilinks()
let validation = editor.validateWikilinks()
```

## 🛠️ Development Guidelines

### Testing Requirements
- **TDD Methodology**: Write failing tests first (Red-Green-Refactor)
- **Coverage**: Maintain >95% test coverage (100% for core logic)
- **Test Command**: `swift test`

### TDD Quality Gates
- **Red Phase**: All tests fail initially (feature not implemented)
- **Green Phase**: Minimal implementation makes tests pass
- **Refactor Phase**: Code quality improved while maintaining green tests
- **Coverage Gate**: Minimum coverage thresholds met
- **Performance Gate**: No regressions in benchmark tests

### Code Quality Standards
- **SRP Compliance**: Maximum 300 lines per file, 50 lines per method, 10 methods per class
- **Architecture**: Clear separation of concerns, no circular dependencies
- **Protocol-oriented design**: Interfaces for testability and extensibility
- **Platform Support**: iOS and macOS
- **Dependencies**: Built on Down (CommonMark parser)

### Definition of Done (All User Stories Must Include)
- ✅ **TDD Compliance**: Tests written before implementation
- ✅ **Code Coverage**: Unit tests with >95% coverage (100% for core logic)
- ✅ **Integration Tests**: Component interaction verification
- ✅ **SRP Compliance**: Single responsibility per class/file
- ✅ **Architecture Review**: Clear separation of concerns verified
- ✅ **API Documentation**: DocC-compatible documentation with examples
- ✅ **Accessibility Verification**: VoiceOver and keyboard navigation tested

### File Organization
```
features/Wikilink/
├── SwiftDown-Wikilink-Specifications.md    # Technical specs
└── SwiftDown-Wikilink-Backlog.md          # Product backlog
```

## 🚀 Common AI Agent Tasks

### 1. Running Tests
```bash
swift test  # Run all tests
```

### 2. Building Project
```bash
swift build  # Build the project
```

### 3. Working with Wikilinks
- **Implementation**: All wikilink APIs are already complete
- **Testing**: Comprehensive test suite exists
- **Documentation**: See README.md for integration examples

### 4. Adding New Features
1. Check existing Epic status in `features/Wikilink/SwiftDown-Wikilink-Backlog.md`
2. Follow TDD methodology
3. Update tests and documentation
4. Maintain code quality standards

## 📚 Key Documentation

### For Users/Developers
- **README.md**: Complete integration guide with copy-paste examples
- **SwiftDown-Wikilink-Specifications.md**: Technical implementation details

### For AI Agents
- **This file (CLAUDE.md)**: Project context and guidelines
- **Backlog**: Epic status and future development priorities

## 🔄 Epic Development Process

### Current Status
- **Epic 0**: ✅ COMPLETED - Core API implementation
- **Epic 1**: ✅ COMPLETED - Core wikilink implementation (MVP)
- **Epic 2+**: 📋 BACKLOG - Enhanced features

### Development Rules
1. **One Epic at a time**: Complete current epic before starting next
2. **One User Story at a time**: Implement ONE user story at a time
3. **User validation required**: Request approval before proceeding to next story/epic
4. **TDD compliance**: All code must follow Red-Green-Refactor cycle

### Story Development Process
1. Implement user story (tests + code + docs)
2. Request user validation
3. Wait for approval
4. Mark complete and move to next story

## 🎨 Theming

### Built-in Themes
```swift
Theme.BuiltIn.defaultLight.theme()
Theme.BuiltIn.defaultDark.theme()
```

### Wikilink Styles
```swift
WikilinkStyle.defaultLight  // Blue text, no underline
WikilinkStyle.defaultDark   // Light blue text, no underline
```

## 🐛 Troubleshooting

### Common Issues
1. **Build Errors**: Ensure all dependencies are resolved with `swift package resolve`
2. **Test Failures**: Run `swift test` to identify failing tests
3. **Wikilink API**: All APIs are implemented - check README.md for usage

### Debug Commands
```bash
swift package resolve     # Resolve dependencies
swift test --verbose     # Verbose test output
swift build --verbose    # Verbose build output
```

## 📦 Release Process

### Version Bumping
- Current version tracked in `Package.swift`
- Follow semantic versioning (MAJOR.MINOR.PATCH)
- Update README.md package URLs when releasing

### Git Workflow
- **Main branch**: `develop`
- **Commits**: Use conventional commit format
- **Pull Requests**: Target `develop` branch

## 🤖 AI Agent Reminders

### DO:
- ✅ Use existing wikilink APIs (they're fully implemented)
- ✅ Follow TDD methodology for new features
- ✅ Check Epic status before starting work
- ✅ Update documentation when making changes
- ✅ Run tests before committing

### DON'T:
- ❌ Assume wikilink APIs need implementation (they're done)
- ❌ Skip writing tests (TDD required)
- ❌ Work on multiple Epics simultaneously
- ❌ Break existing functionality
- ❌ Ignore code quality standards

### Quick Reference
- **Package URL**: `https://github.com/DonaldoDes/SwiftDown.git`
- **Test Command**: `swift test`
- **Build Command**: `swift build`
- **Main Documentation**: `README.md`
- **Technical Specs**: `features/Wikilink/SwiftDown-Wikilink-Specifications.md`

---

**Last Updated**: December 2024  
**Epic 0 Status**: ✅ COMPLETED - Core API implementation  
**Epic 1 Status**: ✅ COMPLETED - Core wikilink implementation (MVP)  
**Next**: Epic 2+ enhanced features available in backlog