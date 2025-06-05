# SwiftDown

> **📍 Note**: This is an enhanced fork of [qeude/SwiftDown](https://github.com/qeude/SwiftDown) with extended wikilink functionality and AI-optimized documentation.

## 📖 Description

SwiftDown is a markdown editor component for SwiftUI applications with built-in wikilink support.

### 🆕 What's New in This Fork

This enhanced version adds:
- 🔗 **Complete Wikilink Implementation**: Full `[[Note Title]]` syntax support with callbacks
- 🎨 **Wikilink Theming**: Custom styling and theme integration
- 📱 **Platform-Specific Interactions**: Touch (iOS) and hover (macOS) support  
- 🔍 **Programmatic API**: Extract and validate wikilinks in code
- 🤖 **AI-Optimized Documentation**: Copy-paste templates and integration guides
- ✅ **Comprehensive Testing**: 73+ tests covering all wikilink functionality

### ✨ Key Features
- 🎉 **Live Preview**: Real-time markdown rendering without web views
- 🔗 **Wikilinks**: Wikipedia-style `[[Note Title]]` linking with callbacks
- ⚡️ **Performance**: Built on [cmark](https://github.com/commonmark/cmark) for speed
- 🗒 **Standard Markdown**: No proprietary formats
- 💻📱 **Cross-Platform**: iOS and macOS support
- 🎨 **Themeable**: Custom styling and built-in themes

<div align=center><img src="resources/demo.gif" align=center height="500"></div>

## 🛠️ Installation

### Swift Package Manager

Add to your `Package.swift`:
```swift
.package(url: "https://github.com/DonaldoDes/SwiftDown.git", from: "0.5.0")
```

Or in Xcode: File → Add Package Dependencies → `https://github.com/DonaldoDes/SwiftDown.git`

## 🚀 Quick Start

### Step 1: Import SwiftDown
```swift
import SwiftDown
import SwiftUI
```

### Step 2: Basic Markdown Editor
```swift
struct ContentView: View {
    @State private var text = "# Hello\nType **markdown** here!"

    var body: some View {
        SwiftDownEditor(text: $text)
            .theme(Theme.BuiltIn.defaultDark.theme())
            .insetsSize(20)
    }
}
```

### Step 3: Add Wikilink Support
```swift
struct WikilinkEditor: View {
    @State private var text = "Welcome to [[My Notes]]!"

    var body: some View {
        SwiftDownEditor(text: $text)
            .onWikilinkTapped { title in
                print("Navigate to: \(title)")
                // Add your navigation logic here
            }
            .theme(Theme.BuiltIn.defaultLight.theme())
    }
}
```

## 🔗 Wikilinks

Wikilinks use `[[Note Title]]` syntax for note navigation. They are automatically detected, styled, and made interactive.

### 🎯 Implementation Patterns

#### Pattern 1: Basic Navigation
```swift
SwiftDownEditor(text: $text)
    .onWikilinkTapped { title in
        // REQUIRED: Handle navigation
        navigateToNote(title)
    }

func navigateToNote(_ title: String) {
    // Your implementation:
    // - Push new view
    // - Update navigation state  
    // - Load note content
    print("Navigate to: \(title)")
}
```

#### Pattern 2: With Validation
```swift
SwiftDownEditor(text: $text)
    .onWikilinkTapped { title in navigateToNote(title) }
    .wikilinkValidator { title in
        // REQUIRED: Return true if note exists
        return noteDatabase.contains(title)
    }
```

#### Pattern 3: Complete Integration
```swift
SwiftDownEditor(text: $text)
    .onWikilinkTapped { title in
        openNote(title)
    }
    .wikilinkValidator { title in
        noteManager.noteExists(title)
    }
    .wikilinkStyle(WikilinkStyle.defaultLight)
    .theme(Theme.BuiltIn.defaultLight.theme())
```

### 🛠️ Configuration API

#### Navigation (Required)
```swift
.onWikilinkTapped { title in
    // Called on tap/click - IMPLEMENT THIS
    handleNavigation(title)
}
```

#### Hover Support (macOS)
```swift
.onWikilinkHovered { title in
    if let title = title {
        showPreview(title)    // Hover started
    } else {
        hidePreview()         // Hover ended
    }
}
```

#### Validation (Optional)
```swift
.wikilinkValidator { title in
    // Return true if wikilink target exists
    return myNoteDatabase.hasNote(title)
}
```

#### Styling (Optional)
```swift
// Built-in styles
.wikilinkStyle(WikilinkStyle.defaultLight)  // Light theme
.wikilinkStyle(WikilinkStyle.defaultDark)   // Dark theme

// Custom style
.wikilinkStyle(WikilinkStyle(
    textColor: UniversalColor.blue,
    backgroundColor: UniversalColor.clear,
    underlineStyle: [],
    hoverUnderlineStyle: .patternDot
))
```

### 📊 Programmatic API

Extract and validate wikilinks in code:

```swift
// Create editor instance
let editor = SwiftDownEditor(text: $text)

// Get all wikilinks
let wikilinks = editor.getWikilinks()
for wikilink in wikilinks {
    print("Found: '\(wikilink.title)' at \(wikilink.range)")
}

// Validate with current validator
if let validation = editor.validateWikilinks() {
    for (title, isValid) in validation {
        print("'\(title)' is \(isValid ? "valid" : "invalid")")
    }
}
```

### 🎨 Theme Integration

```swift
// Method 1: Use built-in themes
SwiftDownEditor(text: $text)
    .theme(Theme.BuiltIn.defaultDark.theme())
    .wikilinkStyle(WikilinkStyle.defaultDark)

// Method 2: Custom theme file
SwiftDownEditor(text: $text)
    .theme(Theme(themePath: "path/to/theme.json"))
    .wikilinkStyle(customWikilinkStyle)
```

## 🔄 Complete Implementation Template

### Copy-Paste Template for AI Agents

```swift
import SwiftDown
import SwiftUI

struct MyMarkdownEditor: View {
    @State private var text = """
    # My Notes
    
    Welcome to [[Getting Started]]!
    Check out [[Project Ideas]] and [[References]].
    """
    
    var body: some View {
        SwiftDownEditor(text: $text)
            // STEP 1: Required - Handle wikilink navigation
            .onWikilinkTapped { title in
                handleWikilinkNavigation(title)
            }
            // STEP 2: Optional - Validate wikilinks
            .wikilinkValidator { title in
                return validateWikilink(title)
            }
            // STEP 3: Optional - macOS hover support
            .onWikilinkHovered { title in
                handleWikilinkHover(title)
            }
            // STEP 4: Optional - Custom styling
            .wikilinkStyle(WikilinkStyle.defaultLight)
            // STEP 5: Required - Set theme
            .theme(Theme.BuiltIn.defaultLight.theme())
            .insetsSize(20)
    }
    
    // IMPLEMENT: Navigation logic
    private func handleWikilinkNavigation(_ title: String) {
        print("Navigate to: \(title)")
        // TODO: Add your navigation implementation:
        // - navigationController.push(NoteView(title))
        // - Router.navigate(to: .note(title))
        // - selectedNote = title
    }
    
    // IMPLEMENT: Validation logic
    private func validateWikilink(_ title: String) -> Bool {
        // TODO: Check if note exists in your data store
        let existingNotes = ["Getting Started", "Project Ideas", "References"]
        return existingNotes.contains(title)
    }
    
    // IMPLEMENT: Hover logic (macOS only)
    private func handleWikilinkHover(_ title: String?) {
        if let title = title {
            print("Hovering: \(title)")
            // TODO: Show preview popup
        } else {
            print("Hover ended")
            // TODO: Hide preview popup
        }
    }
}
```

### 📋 Quick Reference

#### Essential Methods
```swift
// REQUIRED: Navigation callback
.onWikilinkTapped { title in /* handle navigation */ }

// OPTIONAL: Validation  
.wikilinkValidator { title in /* return bool */ }

// OPTIONAL: Hover (macOS)
.onWikilinkHovered { title in /* handle hover */ }

// OPTIONAL: Styling
.wikilinkStyle(WikilinkStyle.defaultLight)
```

#### Built-in Themes
```swift
Theme.BuiltIn.defaultLight.theme()  // Light theme
Theme.BuiltIn.defaultDark.theme()   // Dark theme
```

#### Wikilink Styles
```swift
WikilinkStyle.defaultLight  // Blue text, no underline
WikilinkStyle.defaultDark   // Light blue text, no underline
```

#### Data Extraction
```swift
let wikilinks = editor.getWikilinks()           // Get all wikilinks
let validation = editor.validateWikilinks()     // Validate all
```

### 🎯 Integration Checklist for AI Agents

- [ ] Import `SwiftDown` and `SwiftUI`
- [ ] Create `@State private var text` with initial content
- [ ] Add `SwiftDownEditor(text: $text)` to view
- [ ] Implement `.onWikilinkTapped { }` callback (REQUIRED)
- [ ] Add `.theme()` modifier (REQUIRED)
- [ ] Test wikilink syntax: `[[Note Title]]`
- [ ] Optional: Add `.wikilinkValidator { }` for validation
- [ ] Optional: Add `.wikilinkStyle()` for custom styling
- [ ] Optional: Add `.onWikilinkHovered { }` for macOS hover

**Result**: Functional markdown editor with clickable wikilinks

See [SwiftDown-Wikilink-Specifications.md](features/Wikilink/SwiftDown-Wikilink-Specifications.md) for technical details.

## 🎨 Themes

### Built-in Themes
```swift
// Light theme
.theme(Theme.BuiltIn.defaultLight.theme())

// Dark theme  
.theme(Theme.BuiltIn.defaultDark.theme())
```

<div style="display: flex; gap: 20px;">
<div>
<strong>Default Light</strong><br>
<img src="resources/default-light-theme.png" height="300">
</div>
<div>
<strong>Default Dark</strong><br>
<img src="resources/default-dark-theme.png" height="300">
</div>
</div>

### Custom Themes
```swift
// From JSON file
let customTheme = Theme(themePath: "path/to/theme.json")
SwiftDownEditor(text: $text).theme(customTheme)

// Programmatic theme
let theme = Theme()
// Configure theme properties...
SwiftDownEditor(text: $text).theme(theme)
```

See theme JSON format: [default-dark.json](./Sources/SwiftDown/Resources/Themes/default-dark.json)

---

## 📚 Resources

- **Technical Specs**: [SwiftDown-Wikilink-Specifications.md](features/Wikilink/SwiftDown-Wikilink-Specifications.md)
- **GitHub Issues**: [Report bugs or request features](https://github.com/DonaldoDes/SwiftDown/issues)
- **Package URL**: `https://github.com/DonaldoDes/SwiftDown.git`
- **Original Project**: [qeude/SwiftDown](https://github.com/qeude/SwiftDown) (upstream)

## 👨🏻‍💻 Authors

### Original Author
**Quentin Eude** - [GitHub](https://github.com/qeude) • [LinkedIn](https://www.linkedin.com/in/quentineude/)

### Fork Maintainer  
**DonaldoDes** - [GitHub](https://github.com/DonaldoDes)

> This enhanced fork adds comprehensive wikilink functionality, AI-optimized documentation, and additional features while maintaining compatibility with the original SwiftDown API.
