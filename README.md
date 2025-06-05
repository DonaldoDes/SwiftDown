# SwiftDown

[![codecov](https://codecov.io/gh/qeude/SwiftDown/branch/main/graph/badge.svg?token=RB6K3Q5QIO)](https://codecov.io/gh/qeude/SwiftDown)

## 📖 Description

A markdown editor component for your SwiftUI apps.

- 🎉 Live preview directly in editor for most of Markdown elements, without web based preview.
- 🔗 **Wikilink support** - Navigate between notes with `[[Note Title]]` syntax
- ⚡️ Fast, built on top of [cmark](https://github.com/commonmark/cmark).
- 🗒 Pure markdown, no proprietary format.
- 💻:📱 macOS and iOS support.

<div align=center><img src="resources/demo.gif" align=center height="500"></div>

## 🛠️ Install

### 📦 Swift Package Manager

Either use Xcode to add the package dependency or add the following dependency to your Package.swift:

```
.package(url: "https://github.com/qeude/SwiftDown.git", from: "0.5.0"),
```

## 🔧 Usage

### Basic Editor

```swift
import SwiftDown
import SwiftUI

struct ContentView: View {
    @State private var text: String = ""

    var body: some View {
        SwiftDownEditor(text: $text)
            .insetsSize(40)
            .theme(Theme.BuiltIn.defaultDark.theme())
    }
}
```

### 🔗 Wikilinks

SwiftDown supports Wikipedia-style wikilinks for note linking and navigation:

```swift
struct NoteEditor: View {
    @State private var text = "Welcome to [[My Notes]]! See also [[Project Ideas]]."

    var body: some View {
        SwiftDownEditor(text: $text)
            .onWikilinkTapped { title in
                navigateToNote(title)
            }
            .onWikilinkHovered { title in
                // macOS only - show preview on hover
                if let title = title {
                    showPreview(title)
                } else {
                    hidePreview()
                }
            }
            .wikilinkValidator { title in
                noteExists(title) // Validate if note exists
            }
            .wikilinkStyle(WikilinkStyle.defaultLight)
    }
    
    func navigateToNote(_ title: String) {
        // Your navigation logic here
    }
    
    func noteExists(_ title: String) -> Bool {
        // Your validation logic here
        return true
    }
}
```

#### Wikilink Features:
- **Syntax**: Use `[[Note Title]]` to create wikilinks
- **Navigation**: Tap/click to trigger navigation callbacks  
- **Validation**: Verify wikilink targets exist
- **Styling**: Customize appearance with themes
- **Platform Support**: Touch on iOS, mouse/hover on macOS
- **API**: Extract and validate wikilinks programmatically

See [SwiftDown-Wikilink-Specifications.md](SwiftDown-Wikilink-Specifications.md) for detailed documentation.

## 🖌️ Themes

### 🖼 BuildIn themes

#### Default Dark

<img src="resources/default-dark-theme.png" height="400">

#### Default Light

<img src="resources/default-light-theme.png" height="400">

### 🧑‍🎨 Custom themes

SwiftDown supports theming by using config `.json` files as [this one](./Sources/SwiftDown/Resources/Themes/default-dark.json)
Then init your custom theme as below.

```swift
Theme(themePath: Bundle.main.path(forResource: "my-custom-theme", ofType: "json"))
```

## 👨🏻‍💻 Author

- Quentin Eude
  - [Github](https://github.com/qeude)
  - [LinkedIn](https://www.linkedin.com/in/quentineude/)
