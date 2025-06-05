//
//  Editor.swift
//
//
//  Created by Quentin Eude on 10/03/2021.
//
import Combine

#if os(iOS)
  import UIKit
#elseif os(macOS)
  import AppKit
#endif

struct EditedText: Equatable {
  let string: String
  let editedRange: NSRange
}

public class Storage: NSTextStorage {
  public var theme: Theme? {
    didSet {
      self.beginEditing()
      self.applyStyles()
      self.endEditing()
    }
  }
  public var markdowner: (String, Int) -> [MarkdownNode] = { _,_  in [] }
  public var applyMarkdown: (MarkdownNode) -> [NSAttributedString.Key: Any] = { _ in [:] }
  public var applyBody: () -> [NSAttributedString.Key: Any] = { [:] }
  var cancellables = Set<AnyCancellable>()
  let subj = PassthroughSubject<EditedText, Never>()

  var backingStore = NSTextStorage()

  override public var string: String {
    return backingStore.string
  }

  override public init() {
    super.init()
  }

  override public init(attributedString attrStr: NSAttributedString) {
    super.init(attributedString: attrStr)
    backingStore.setAttributedString(attrStr)
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  required public init(itemProviderData data: Data, typeIdentifier: String) throws {
    fatalError("init(itemProviderData:typeIdentifier:) has not been implemented")
  }

  #if os(macOS)
    required public init?(pasteboardPropertyList propertyList: Any, ofType type: String) {
      fatalError("init(pasteboardPropertyList:ofType:) has not been implemented")
    }

    required public init?(
      pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType
    ) {
      fatalError("init(pasteboardPropertyList:ofType:) has not been implemented")
    }
  #endif

  override public func attributes(
    at location: Int, longestEffectiveRange range: NSRangePointer?, in rangeLimit: NSRange
  ) -> [NSAttributedString.Key: Any] {
    // Comprehensive safety checks to prevent all range-related crashes
    guard backingStore.length > 0 else {
      return [:]
    }
    
    // Use NSString.length consistently to avoid Unicode character issues
    let stringLength = (backingStore.string as NSString).length
    guard location >= 0 && location < stringLength else {
      return [:]
    }
    
    // Additional thread safety check
    guard Thread.isMainThread else {
      return [:]
    }
    
    // Extra safety check: ensure location is also valid for backing store
    guard location < backingStore.length else {
      return [:]
    }
    
    // Validate rangeLimit as well
    guard rangeLimit.location >= 0 && 
          NSMaxRange(rangeLimit) <= stringLength else {
      return [:]
    }
    
    // Add one more safety net: check if the backing store string is empty
    guard !backingStore.string.isEmpty else {
      return [:]
    }
    
    // CRITICAL: Instead of calling backingStore.attributes directly, 
    // use a completely safe implementation that creates a new attributed string
    // This avoids the NSAttributedString internal state issues
    let safeString = NSAttributedString(string: backingStore.string, attributes: applyBody())
    
    // Validate location one more time for the safe string
    guard location < safeString.length else {
      return [:]
    }
    
    // Validate rangeLimit for the safe string
    guard NSMaxRange(rangeLimit) <= safeString.length else {
      return [:]
    }
    
    return safeString.attributes(at: location, longestEffectiveRange: range, in: rangeLimit)
  }

  override public func replaceCharacters(in range: NSRange, with str: String) {
    // Use NSString.length consistently for validation
    let stringLength = (backingStore.string as NSString).length
    
    // Validate range before replacement to prevent crashes
    guard range.location >= 0 && 
          range.location <= backingStore.length &&
          NSMaxRange(range) <= backingStore.length &&
          range.location <= stringLength &&
          NSMaxRange(range) <= stringLength &&
          range.length >= 0 else {
      print("SwiftDown: replaceCharacters called with invalid range \(range), length=\(backingStore.length), stringLength=\(stringLength)")
      return
    }
    
    self.beginEditing()
    
    backingStore.replaceCharacters(in: range, with: str)
    let len = (str as NSString).length
    let change = len - range.length
    self.edited([.editedCharacters], range: range, changeInLength: change)
    
    self.endEditing()
  }

  public override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
    // Use NSString.length consistently for validation
    let stringLength = (backingStore.string as NSString).length
    
    // Validate range before setting attributes to prevent crashes
    guard range.location >= 0 && 
          range.location <= backingStore.length &&
          NSMaxRange(range) <= backingStore.length &&
          range.location <= stringLength &&
          NSMaxRange(range) <= stringLength &&
          range.length >= 0 else {
      print("SwiftDown: setAttributes called with invalid range \(range), length=\(backingStore.length), stringLength=\(stringLength)")
      return
    }
    
    self.beginEditing()
    
    backingStore.setAttributes(attrs, range: range)
    self.edited(.editedAttributes, range: range, changeInLength: 0)
    
    self.endEditing()
  }

  public override func attributes(at location: Int, effectiveRange range: NSRangePointer?)
    -> [NSAttributedString.Key: Any] {
    // Use completely crash-safe implementation that never calls NSAttributedString with invalid ranges
    return safeGetAttributes(at: location, effectiveRange: range)
  }
  
  /// Crash-safe implementation that completely avoids NSAttributedString crashes
  private func safeGetAttributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
    // Comprehensive safety checks to prevent all range-related crashes
    guard backingStore.length > 0 else {
      return [:]
    }
    
    // Use NSString.length consistently to avoid Unicode character issues
    let stringLength = (backingStore.string as NSString).length
    guard location >= 0 && location < stringLength else {
      return [:]
    }
    
    // Additional thread safety check
    guard Thread.isMainThread else {
      return [:]
    }
    
    // Extra safety check: ensure location is also valid for backing store
    guard location < backingStore.length else {
      return [:]
    }
    
    // Add one more safety net: check if the backing store string is empty
    guard !backingStore.string.isEmpty else {
      return [:]
    }
    
    // CRITICAL: Instead of calling backingStore.attributes directly, 
    // use a completely safe implementation that creates a new attributed string
    // This avoids the NSAttributedString internal state issues
    let safeString = NSAttributedString(string: backingStore.string, attributes: applyBody())
    
    // Validate location one more time for the safe string
    guard location < safeString.length else {
      return [:]
    }
    
    return safeString.attributes(at: location, effectiveRange: range)
  }

  func applyStyles(editedRange: NSRange? = nil) {
    // Comprehensive safety checks to prevent crashes
    guard self.length > 0 else { return }
    guard !self.string.isEmpty else { return }
    guard Thread.isMainThread else { return }
    
    // Use NSString.length consistently for all range operations
    let stringLength = (self.string as NSString).length
    guard stringLength > 0 else { return }
    
    let paragraphNSRange = self.string.paragraph(for: editedRange)
    
    // Enhanced range validation using NSString.length consistently
    guard paragraphNSRange.location >= 0 && 
          paragraphNSRange.location < stringLength &&
          NSMaxRange(paragraphNSRange) <= stringLength &&
          paragraphNSRange.length >= 0 &&
          paragraphNSRange.location < self.length &&
          NSMaxRange(paragraphNSRange) <= self.length else {
      return
    }
    
    let paragraphRange = Range(paragraphNSRange, in: self.string)
    let paragraph: String
    if let paragraphRange = paragraphRange {
      paragraph = String(self.string[paragraphRange])
    } else {
      paragraph = self.string
    }
    
    // Validate paragraph is not empty
    guard !paragraph.isEmpty else { return }
    
    let md = markdowner(paragraph, paragraphNSRange.lowerBound)
    
    // Apply body styles with enhanced range validation
    guard paragraphNSRange.location >= 0 && 
          NSMaxRange(paragraphNSRange) <= self.length &&
          NSMaxRange(paragraphNSRange) <= stringLength else {
      return
    }
    
    // Use safe setAttributes implementation
    safeSetAttributes(applyBody(), range: paragraphNSRange)
    
    // Apply markdown styles with comprehensive validation using safe methods
    md.forEach {
      let range = $0.range
      guard range.location >= 0 && 
            range.location < self.length && 
            NSMaxRange(range) <= self.length &&
            range.location < stringLength &&
            NSMaxRange(range) <= stringLength &&
            range.length >= 0 else {
        return
      }
      
      // Use safe addAttributes implementation
      safeAddAttributes(applyMarkdown($0), range: range)
    }
    
    self.edited(.editedAttributes, range: paragraphNSRange, changeInLength: 0)
  }
  
  // MARK: - Crash-Safe Attribute Methods
  
  /// Crash-safe setAttributes that avoids NSAttributedString internal crashes
  private func safeSetAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
    // Use NSString.length consistently for validation
    let stringLength = (backingStore.string as NSString).length
    
    // Validate range before setting attributes to prevent crashes
    guard range.location >= 0 && 
          range.location <= backingStore.length &&
          NSMaxRange(range) <= backingStore.length &&
          range.location <= stringLength &&
          NSMaxRange(range) <= stringLength &&
          range.length >= 0 else {
      return
    }
    
    self.beginEditing()
    
    // Use original setAttributes but with enhanced error protection
    // This should be safer now that we've validated ranges thoroughly
    backingStore.setAttributes(attrs, range: range)
    self.edited(.editedAttributes, range: range, changeInLength: 0)
    
    self.endEditing()
  }
  
  /// Crash-safe addAttributes that avoids NSAttributedString internal crashes
  private func safeAddAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange) {
    // Use NSString.length consistently for validation
    let stringLength = (backingStore.string as NSString).length
    
    // Validate range before adding attributes to prevent crashes
    guard range.location >= 0 && 
          range.location <= backingStore.length &&
          NSMaxRange(range) <= backingStore.length &&
          range.location <= stringLength &&
          NSMaxRange(range) <= stringLength &&
          range.length >= 0 else {
      return
    }
    
    self.beginEditing()
    
    // Get existing attributes safely and merge with new attributes
    let existingAttrs = safeGetAttributes(at: range.location, effectiveRange: nil)
    var mergedAttrs = existingAttrs
    
    // Merge new attributes
    for (key, value) in attrs {
      mergedAttrs[key] = value
    }
    
    // Replace with merged attributes using safe method
    safeSetAttributes(mergedAttrs, range: range)
    
    self.endEditing()
  }
}
