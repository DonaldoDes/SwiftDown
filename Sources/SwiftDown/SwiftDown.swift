//
//  SwiftDown.swift
//
//
//  Created by Quentin Eude on 16/03/2021.
//

#if os(iOS)
  import UIKit

  // MARK: - SwiftDown iOS
  public class SwiftDown: UITextView, UITextViewDelegate {
    var storage: Storage = Storage()
    var highlighter: SwiftDownHighlighter?
    var hasKeyboardToolbar: Bool = true
    var onWikilinkTapped: ((String) -> Void)?
    var onWikilinkHovered: ((String?) -> Void)?
    var wikilinkValidator: ((String) -> Bool)?

    convenience init(frame: CGRect, theme: Theme) {
      self.init(frame: frame, textContainer: nil)
      self.storage.theme = theme
      self.backgroundColor = theme.backgroundColor
      self.tintColor = theme.tintColor
      self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      if hasKeyboardToolbar {
        self.addKeyboardToolbar()
      }
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
      let layoutManager = NSLayoutManager()
      let containerSize = CGSize(width: frame.size.width, height: frame.size.height)
      let container = NSTextContainer(size: containerSize)
      container.widthTracksTextView = true

      layoutManager.addTextContainer(container)
      storage.addLayoutManager(layoutManager)
      super.init(frame: frame, textContainer: container)
      self.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
      let layoutManager = NSLayoutManager()
      let containerSize = CGSize(width: frame.size.width, height: CGFloat.greatestFiniteMagnitude)
      let container = NSTextContainer(size: containerSize)
      container.widthTracksTextView = true
      layoutManager.addTextContainer(container)
      storage.addLayoutManager(layoutManager)
      self.delegate = self
    }

    public override func willMove(toSuperview newSuperview: UIView?) {
      self.highlighter = SwiftDownHighlighter(textView: self)
    }
    
    // MARK: - Wikilink Touch Handling
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      guard let touch = touches.first else {
        super.touchesBegan(touches, with: event)
        return
      }
      
      let location = touch.location(in: self)
      if let tappedWikilink = getWikilinkAt(location: location) {
        // Handle wikilink tap
        onWikilinkTapped?(tappedWikilink)
      } else {
        super.touchesBegan(touches, with: event)
      }
    }
    
    private func getWikilinkAt(location: CGPoint) -> String? {
      // Convert touch location to character position
      let characterIndex = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
      
      // Use the MarkdownEngine to get wikilinks and check if tap is within any
      let engine = MarkdownEngine()
      let wikilinks = engine.getWikilinks(from: text)
      
      for wikilink in wikilinks {
        if NSLocationInRange(characterIndex, wikilink.range) {
          return wikilink.title
        }
      }
      
      return nil
    }
  }
#else
  import AppKit

  // MARK: - CustomTextView
  class CustomTextView: NSTextView {
    var storage: Storage = Storage()
    var onWikilinkTapped: ((String) -> Void)?
    var onWikilinkHovered: ((String?) -> Void)?
    var wikilinkValidator: ((String) -> Bool)?

    convenience init(frame: CGRect, theme: Theme) {
      self.init(frame: frame, textContainer: nil)
      self.storage.theme = theme
      self.backgroundColor = theme.backgroundColor
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
      let layoutManager = NSLayoutManager()
      let containerSize = CGSize(width: frame.size.width, height: CGFloat.greatestFiniteMagnitude)
      let container = NSTextContainer(size: containerSize)
      container.widthTracksTextView = true

      layoutManager.addTextContainer(container)
      storage.addLayoutManager(layoutManager)
      super.init(frame: frame, textContainer: container)
      
      // Enable mouse tracking for hover effects
      addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeInKeyWindow, .mouseMoved, .mouseEnteredAndExited], owner: self, userInfo: nil))
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Wikilink Mouse Handling
    
    override func mouseDown(with event: NSEvent) {
      let location = convert(event.locationInWindow, from: nil)
      
      if let tappedWikilink = getWikilinkAt(location: location) {
        onWikilinkTapped?(tappedWikilink)
      } else {
        super.mouseDown(with: event)
      }
    }
    
    override func mouseMoved(with event: NSEvent) {
      let location = convert(event.locationInWindow, from: nil)
      
      if let hoveredWikilink = getWikilinkAt(location: location) {
        // Show pointer cursor and call hover callback
        NSCursor.pointingHand.set()
        onWikilinkHovered?(hoveredWikilink)
      } else {
        // Reset cursor and call hover end callback
        NSCursor.iBeam.set()
        onWikilinkHovered?(nil)
      }
      
      super.mouseMoved(with: event)
    }
    
    override func mouseExited(with event: NSEvent) {
      // Reset cursor when mouse exits
      NSCursor.iBeam.set()
      onWikilinkHovered?(nil)
      super.mouseExited(with: event)
    }
    
    private func getWikilinkAt(location: CGPoint) -> String? {
      // Convert mouse location to character position
      guard let textContainer = textContainer,
            let layoutManager = layoutManager else { return nil }
      
      let characterIndex = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
      
      // Use the MarkdownEngine to get wikilinks
      let engine = MarkdownEngine()
      let wikilinks = engine.getWikilinks(from: string)
      
      for wikilink in wikilinks {
        if NSLocationInRange(characterIndex, wikilink.range) {
          return wikilink.title
        }
      }
      
      return nil
    }
    
    override func updateTrackingAreas() {
      super.updateTrackingAreas()
      
      // Remove existing tracking areas and add new one with current bounds
      for trackingArea in trackingAreas {
        removeTrackingArea(trackingArea)
      }
      
      addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeInKeyWindow, .mouseMoved, .mouseEnteredAndExited], owner: self, userInfo: nil))
    }
  }

  // MARK: - SwiftDown macOS
  class TransparentBackgroundScroller: NSScroller {
    override func draw(_ dirtyRect: NSRect) {
      self.drawKnob()
    }
  }

  public class SwiftDown: NSView {
    var theme: Theme
    private var isEditable: Bool
    private var insetsSize: CGFloat
    var onWikilinkTapped: ((String) -> Void)?
    var onWikilinkHovered: ((String?) -> Void)?
    var wikilinkValidator: ((String) -> Bool)?

    weak var delegate: NSTextViewDelegate? {
      didSet {
        textView.delegate = delegate
      }
    }

    let engine = MarkdownEngine()
    var highlighter: SwiftDownHighlighter?

    var text: String {
      didSet {
        textView.string = text
      }
    }

    var selectedRanges: [NSValue] {
      get {
        textView.selectedRanges
      }
      set(value) {
        textView.selectedRanges = value
      }
    }

    // MARK: - ScrollView setup
    private lazy var scrollView: NSScrollView = {
      let scrollView = NSScrollView()
      scrollView.drawsBackground = true
      scrollView.borderType = .noBorder
      scrollView.hasVerticalScroller = true
      scrollView.hasHorizontalRuler = false
      scrollView.autoresizingMask = [.width, .height]
      scrollView.translatesAutoresizingMaskIntoConstraints = false
      scrollView.autohidesScrollers = true
      scrollView.borderType = .noBorder
      scrollView.verticalScroller = TransparentBackgroundScroller()
      return scrollView
    }()

    // MARK: - TextView setup
    private lazy var textView: NSTextView = {
      let contentSize = scrollView.contentSize
      let textView = CustomTextView(frame: scrollView.frame, theme: theme)
      textView.delegate = self.delegate
      textView.string = text
      textView.storage.markdowner = { self.engine.render($0, offset: $1) }
      textView.storage.applyMarkdown = { m in Theme.applyMarkdown(markdown: m, with: self.theme) }
      textView.storage.applyBody = { Theme.applyBody(with: self.theme) }
      textView.storage.theme = theme
      textView.autoresizingMask = .width
      textView.drawsBackground = true
      textView.isEditable = self.isEditable
      textView.isHorizontallyResizable = false
      textView.isVerticallyResizable = true
      textView.maxSize = NSSize(
        width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
      textView.minSize = NSSize(width: 0, height: contentSize.height)
      textView.textContainerInset = NSSize(width: self.insetsSize, height: self.insetsSize)
      textView.allowsUndo = true
      textView.allowsDocumentBackgroundColorChange = true
      textView.backgroundColor = theme.backgroundColor
      textView.insertionPointColor = theme.cursorColor
      textView.textColor = theme.tintColor
      return textView
    }()

    init(
      theme: Theme, isEditable: Bool, insetsSize: CGFloat = 0
    ) {
      self.isEditable = isEditable
      self.text = ""
      self.theme = theme
      self.insetsSize = insetsSize

      super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillDraw() {
      super.viewWillDraw()

      setupScrollViewConstraints()
      setupTextView()
    }

    func setupScrollViewConstraints() {
      scrollView.translatesAutoresizingMaskIntoConstraints = false

      addSubview(scrollView)

      NSLayoutConstraint.activate([
        scrollView.topAnchor.constraint(equalTo: topAnchor),
        scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
        scrollView.leadingAnchor.constraint(equalTo: leadingAnchor)
      ])
    }

    func setupTextView() {
      scrollView.documentView = textView
      
      // Only create highlighter if text view is in a safe state
      if textView.textStorage != nil && 
         textView.layoutManager != nil && 
         !textView.string.isEmpty {
        highlighter = SwiftDownHighlighter(textView: textView)
      }
      
      // Wire up wikilink callbacks to the text view
      if let customTextView = textView as? CustomTextView {
        customTextView.onWikilinkTapped = onWikilinkTapped
        customTextView.onWikilinkHovered = onWikilinkHovered
        customTextView.wikilinkValidator = wikilinkValidator
      }
    }

    func applyStyles() {
      // Only apply styles if highlighter was successfully created
      highlighter?.applyStyles()
    }
  }
#endif
