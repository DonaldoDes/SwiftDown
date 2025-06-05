//
//  SwiftDownEditor.swift
//
//
//  Created by Quentin Eude on 16/03/2021.
//

import Down
import SwiftUI
import Combine

#if os(iOS)
  // MARK: - SwiftDownEditor iOS
public struct SwiftDownEditor: UIViewRepresentable {
  private var debounceTime = 0.3
  @Binding var text: String {
    didSet {
      onTextChange(text)
    }
  }

    private(set) var isEditable: Bool = true
    private(set) var theme: Theme = Theme.BuiltIn.defaultDark.theme()
    private(set) var insetsSize: CGFloat = 0
    private(set) var autocapitalizationType: UITextAutocapitalizationType = .sentences
    private(set) var autocorrectionType: UITextAutocorrectionType = .default
    private(set) var keyboardType: UIKeyboardType = .default
    private(set) var hasKeyboardToolbar: Bool = true
    private(set) var textAlignment: TextAlignment = .leading

    public var onTextChange: (String) -> Void = { _ in }
    public var onSelectionChange: (NSRange) -> Void = { _ in }
    public var onWikilinkTapped: ((String) -> Void)? = nil
    public var onWikilinkHovered: ((String?) -> Void)? = nil
    public var wikilinkValidator: ((String) -> Bool)? = nil
    let engine = MarkdownEngine()

    public init(
      text: Binding<String>,
      onTextChange: @escaping (String) -> Void = { _ in },
      onSelectionChange: @escaping (NSRange) -> Void = { _ in }
    ) {
      _text = text
      self.onTextChange = onTextChange
      self.onSelectionChange = onSelectionChange
    }

    public func makeUIView(context: Context) -> SwiftDown {
      let swiftDown = SwiftDown(frame: .zero, theme: theme)
      swiftDown.storage.markdowner = { self.engine.render($0, offset: $1) }
      swiftDown.storage.applyMarkdown = { m in Theme.applyMarkdown(markdown: m, with: self.theme) }
      swiftDown.storage.applyBody = { Theme.applyBody(with: self.theme) }
      swiftDown.delegate = context.coordinator
      swiftDown.isEditable = isEditable
      swiftDown.isScrollEnabled = true
      swiftDown.keyboardType = keyboardType
      swiftDown.hasKeyboardToolbar = hasKeyboardToolbar
      swiftDown.autocapitalizationType = autocapitalizationType
      swiftDown.autocorrectionType = autocorrectionType
      swiftDown.textContainerInset = UIEdgeInsets(
        top: insetsSize, left: insetsSize, bottom: insetsSize, right: insetsSize)
      swiftDown.backgroundColor = theme.backgroundColor
      swiftDown.tintColor = theme.tintColor
      swiftDown.textColor = theme.tintColor
      swiftDown.text = text
      
      // Configure wikilink callbacks
      swiftDown.onWikilinkTapped = onWikilinkTapped
      swiftDown.onWikilinkHovered = onWikilinkHovered
      swiftDown.wikilinkValidator = wikilinkValidator

      return swiftDown
    }

  public func updateUIView(_ uiView: SwiftDown, context: Context) {
    context.coordinator.cancellable?.cancel()
    context.coordinator.cancellable = Timer
      .publish(every: debounceTime, on: .current, in: .default)
      .autoconnect()
      .first()
      .sink { _ in
        let selectedRange = uiView.selectedRange
        uiView.text = text
        uiView.highlighter?.applyStyles()
        uiView.selectedRange = selectedRange
      }
  }

    public func makeCoordinator() -> Coordinator {
      Coordinator(self)
    }
  }

  // MARK: - SwiftDownEditor iOS Coordinator
  extension SwiftDownEditor {
    public class Coordinator: NSObject, UITextViewDelegate {
      var cancellable: Cancellable?
      var parent: SwiftDownEditor

      init(_ parent: SwiftDownEditor) {
        self.parent = parent
      }

      public func textViewDidChange(_ textView: UITextView) {
        guard textView.markedTextRange == nil else { return }

        DispatchQueue.main.async {
          self.parent.text = textView.text
        }
      }

      public func textViewDidChangeSelection(_ textView: UITextView) {
        guard textView.markedTextRange == nil else { return }
        self.parent.onSelectionChange(textView.selectedRange)
      }
    }
  }

  // MARK: - iOS Specifics modifiers
  extension SwiftDownEditor {
    public func autocapitalizationType(_ type: UITextAutocapitalizationType) -> Self {
      var new = self
      new.autocapitalizationType = type
      return new
    }

    public func autocorrectionType(_ type: UITextAutocorrectionType) -> Self {
      var new = self
      new.autocorrectionType = type
      return new
    }

    public func keyboardType(_ type: UIKeyboardType) -> Self {
      var new = self
      new.keyboardType = type
      return new
    }

    public func textAlignment(_ type: TextAlignment) -> Self {
      var new = self
      new.textAlignment = type
      return new
    }

    public func hasKeyboardToolbar(_ hasKeyboardToolbar: Bool) -> Self {
      var editor = self
      editor.hasKeyboardToolbar = hasKeyboardToolbar
      return editor
    }
  }
#else
  // MARK: - SwiftDownEditor macOS
  public struct SwiftDownEditor: NSViewRepresentable {
    private var debounceTime = 0.3
    @Binding var text: String {
      didSet {
        onTextChange(text)
      }
    }

    private(set) var isEditable: Bool = true
    private(set) var theme: Theme = Theme.BuiltIn.defaultDark.theme()
    private(set) var insetsSize: CGFloat = 0

    public var onTextChange: (String) -> Void = { _ in }
    public var onSelectionChange: (NSRange) -> Void = { _ in }
    public var onWikilinkTapped: ((String) -> Void)? = nil
    public var onWikilinkHovered: ((String?) -> Void)? = nil
    public var wikilinkValidator: ((String) -> Bool)? = nil
    let engine = MarkdownEngine()

    public init(
      text: Binding<String>,
      onTextChange: @escaping (String) -> Void = { _ in },
      onSelectionChange: @escaping (NSRange) -> Void = { _ in }
    ) {
      _text = text
      self.onTextChange = onTextChange
      self.onSelectionChange = onSelectionChange
    }

    public func makeNSView(context: Context) -> SwiftDown {
      let swiftDown = SwiftDown(theme: theme, isEditable: isEditable, insetsSize: insetsSize)
      swiftDown.delegate = context.coordinator
      swiftDown.setupTextView()
      swiftDown.text = text
      
      // Configure wikilink callbacks
      swiftDown.onWikilinkTapped = onWikilinkTapped
      swiftDown.onWikilinkHovered = onWikilinkHovered
      swiftDown.wikilinkValidator = wikilinkValidator
      
      return swiftDown
    }

    public func updateNSView(_ nsView: SwiftDown, context: Context) {
      context.coordinator.cancellable?.cancel()
      context.coordinator.cancellable = Timer
        .publish(every: debounceTime, on: .current, in: .default)
        .autoconnect()
        .first()
        .sink { _ in
          let selectedRanges = nsView.selectedRanges
          nsView.text = text
          nsView.applyStyles()
          nsView.selectedRanges = selectedRanges
        }
    }

    public func makeCoordinator() -> Coordinator {
      Coordinator(self)
    }
  }

  // MARK: - SwiftDownEditor Coordinator macOS
  extension SwiftDownEditor {
    // MARK: - Coordinator
    public class Coordinator: NSObject, NSTextViewDelegate {
      var parent: SwiftDownEditor
      var cancellable: Cancellable?
      init(_ parent: SwiftDownEditor) {
        self.parent = parent
      }

      public func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else {
          return
        }

        self.parent.text = textView.string
      }

      public func textViewDidChangeSelection(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else {
          return
        }
        self.parent.onSelectionChange(textView.selectedRange())
      }
    }
  }
#endif

// MARK: - Common Modifiers
extension SwiftDownEditor {
  public func insetsSize(_ size: CGFloat) -> Self {
    var editor = self
    editor.insetsSize = size
    return editor
  }

  public func theme(_ theme: Theme) -> Self {
    var editor = self
    editor.theme = theme
    return editor
  }

  public func isEditable(_ isEditable: Bool) -> Self {
    var editor = self
    editor.isEditable = isEditable
    return editor
  }

  public func debounceTime(_ debounceTime: Double) -> Self {
     var editor = self
     editor.debounceTime = debounceTime
     return editor
   }
  
  // MARK: - Wikilink Modifiers
  
  /// Sets the callback to be called when a wikilink is tapped
  /// - Parameter callback: A closure that receives the wikilink title
  /// - Returns: A configured SwiftDownEditor instance
  public func onWikilinkTapped(_ callback: @escaping (String) -> Void) -> Self {
    var editor = self
    editor.onWikilinkTapped = callback
    return editor
  }
  
  /// Sets the callback to be called when a wikilink is hovered (macOS only)
  /// - Parameter callback: A closure that receives the wikilink title, or nil when hover ends
  /// - Returns: A configured SwiftDownEditor instance
  public func onWikilinkHovered(_ callback: @escaping (String?) -> Void) -> Self {
    var editor = self
    editor.onWikilinkHovered = callback
    return editor
  }
  
  /// Sets a validator function to check if wikilinks are valid
  /// - Parameter validator: A closure that returns true if the wikilink title is valid
  /// - Returns: A configured SwiftDownEditor instance
  public func wikilinkValidator(_ validator: @escaping (String) -> Bool) -> Self {
    var editor = self
    editor.wikilinkValidator = validator
    return editor
  }
  
  /// Customizes the visual style of wikilinks
  /// - Parameter style: The WikilinkStyle to apply
  /// - Returns: A configured SwiftDownEditor instance
  public func wikilinkStyle(_ style: WikilinkStyle) -> Self {
    var editor = self
    editor.theme.wikilinkStyle = style
    return editor
  }
  
  /// Returns all wikilinks found in the current text
  /// - Returns: Array of WikilinkMatch objects
  public func getWikilinks() -> [WikilinkMatch] {
    return engine.getWikilinks(from: text)
  }
  
  /// Validates all wikilinks in the current text using the configured validator
  /// - Returns: Dictionary mapping wikilink titles to their validation status, or nil if no validator is set
  public func validateWikilinks() -> [String: Bool]? {
    guard let validator = wikilinkValidator else { return nil }
    return engine.validateWikilinks(in: text, using: validator)
  }
}
