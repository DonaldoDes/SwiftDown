//
//  SwiftDownHighlighter.swift
//
//
//  Created by Quentin Eude on 28/12/2022.
//

#if os(iOS)
import UIKit

class SwiftDownHighlighter {
  weak var textView: UITextView?

  /// - param textView: The text view which should be observed and highlighted.
  init(textView: UITextView?) {
    self.textView = textView
    // Do not call applyStyles during initialization to prevent crashes
    // Let it be called naturally when the text view is ready
  }

  public func applyStyles() {
    guard let textView = self.textView,
          let customTextStorage = textView.textStorage as? Storage else { return }
    
    // Additional safety checks to prevent crashes
    guard customTextStorage.length > 0 else { return }
    guard !customTextStorage.string.isEmpty else { return }
    
    // Ensure we're on the main thread for UI operations
    guard Thread.isMainThread else {
      DispatchQueue.main.async { [weak self] in
        self?.applyStyles()
      }
      return
    }

    customTextStorage.beginEditing()
    customTextStorage.applyStyles()
    customTextStorage.endEditing()
  }
}

#else
import AppKit

class SwiftDownHighlighter {
  let textView: NSTextView

  /// - param textView: The text view which should be observed and highlighted.
  init(textView: NSTextView) {
    self.textView = textView
    // Do not call applyStyles during initialization to prevent crashes
    // Let it be called naturally when the text view is ready
  }

  public func applyStyles() {
    guard let customTextStorage = self.textView.textStorage as? Storage else { return }
    
    // Additional safety checks to prevent crashes
    guard customTextStorage.length > 0 else { return }
    guard !customTextStorage.string.isEmpty else { return }
    
    // Ensure we're on the main thread for UI operations
    guard Thread.isMainThread else {
      DispatchQueue.main.async { [weak self] in
        self?.applyStyles()
      }
      return
    }

    customTextStorage.beginEditing()
    customTextStorage.applyStyles()
    customTextStorage.endEditing()
  }
}

#endif
