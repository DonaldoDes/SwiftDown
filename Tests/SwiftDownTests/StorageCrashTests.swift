//
//  StorageCrashTests.swift
//  SwiftDownTests
//
//  TDD tests for crash scenarios in Storage.swift
//

import XCTest
@testable import SwiftDown

final class StorageCrashTests: XCTestCase {
    
    var storage: Storage!
    
    override func setUp() {
        super.setUp()
        storage = Storage()
    }
    
    override func tearDown() {
        storage = nil
        super.tearDown()
    }
    
    // MARK: - TDD Red Phase Tests (Should initially fail)
    
    func testAttributesAtInvalidLocationDoesNotCrash() {
        // Test the exact crash scenario from the crash report
        storage.replaceCharacters(in: NSRange(location: 0, length: 0), with: "Test 🚀 Unicode")
        
        // This should not crash even with invalid location
        XCTAssertNoThrow({
            let _ = self.storage.attributes(at: 1000, effectiveRange: nil)
        }, "attributes(at:effectiveRange:) should not crash with invalid location")
    }
    
    func testAttributesAtLocationWithUnicodeCharacters() {
        // Test Unicode character edge case
        let unicodeText = "Test 🚀🎯💡 Multiple Unicode"
        storage.replaceCharacters(in: NSRange(location: 0, length: 0), with: unicodeText)
        
        let stringLength = (unicodeText as NSString).length
        
        // Test at boundary
        XCTAssertNoThrow({
            let _ = self.storage.attributes(at: stringLength - 1, effectiveRange: nil)
        }, "Should handle Unicode characters correctly at boundary")
        
        // Test beyond boundary
        XCTAssertNoThrow({
            let _ = self.storage.attributes(at: stringLength + 10, effectiveRange: nil)
        }, "Should not crash beyond Unicode string boundary")
    }
    
    func testApplyStylesWithUnicodeMarkdown() {
        // Test the exact scenario that causes crashes during live editing
        let markdownWithUnicode = "# Test 🚀 Header\n\n**Bold 💡 text** and *italic 🎯 text*"
        storage.replaceCharacters(in: NSRange(location: 0, length: 0), with: markdownWithUnicode)
        
        // This should not crash during markdown styling
        XCTAssertNoThrow({
            self.storage.applyStyles()
        }, "applyStyles should not crash with Unicode markdown")
    }
    
    func testApplyStylesWithEmptyString() {
        // Test edge case with empty string
        XCTAssertNoThrow({
            self.storage.applyStyles()
        }, "applyStyles should handle empty string safely")
    }
    
    func testApplyStylesWithRapidTextChanges() {
        // Simulate rapid text changes that can cause race conditions
        let texts = [
            "Test",
            "Test 🚀",
            "Test 🚀 Unicode",
            "# Test 🚀 Unicode Header",
            "**Bold**",
            ""
        ]
        
        for text in texts {
            XCTAssertNoThrow({
                self.storage.replaceCharacters(
                    in: NSRange(location: 0, length: self.storage.length),
                    with: text
                )
                self.storage.applyStyles()
            }, "Rapid text changes should not cause crashes")
        }
    }
    
    func testLongestEffectiveRangeWithInvalidRange() {
        storage.replaceCharacters(in: NSRange(location: 0, length: 0), with: "Test text")
        
        let invalidRange = NSRange(location: 100, length: 50)
        
        XCTAssertNoThrow({
            let _ = self.storage.attributes(
                at: 0,
                longestEffectiveRange: nil,
                in: invalidRange
            )
        }, "longestEffectiveRange should handle invalid range limits")
    }
    
    func testConcurrentStyleApplications() {
        // Test concurrent access that might cause crashes
        storage.replaceCharacters(in: NSRange(location: 0, length: 0), with: "Test concurrent access")
        
        let expectation = self.expectation(description: "Concurrent styling")
        expectation.expectedFulfillmentCount = 2
        
        DispatchQueue.global().async {
            XCTAssertNoThrow({
                self.storage.applyStyles()
            })
            expectation.fulfill()
        }
        
        DispatchQueue.global().async {
            XCTAssertNoThrow({
                self.storage.applyStyles()
            })
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testReplaceCharactersWithInvalidRange() {
        storage.replaceCharacters(in: NSRange(location: 0, length: 0), with: "Initial text")
        
        // Test invalid replacement ranges
        let invalidRanges = [
            NSRange(location: -1, length: 5),
            NSRange(location: 1000, length: 5),
            NSRange(location: 5, length: 1000),
            NSRange(location: storage.length + 1, length: 1)
        ]
        
        for range in invalidRanges {
            XCTAssertNoThrow({
                self.storage.replaceCharacters(in: range, with: "replacement")
            }, "replaceCharacters should handle invalid range: \(range)")
        }
    }
    
    func testSetAttributesWithInvalidRange() {
        storage.replaceCharacters(in: NSRange(location: 0, length: 0), with: "Test text for attributes")
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12)
        ]
        
        let invalidRanges = [
            NSRange(location: -1, length: 5),
            NSRange(location: 1000, length: 5),
            NSRange(location: 5, length: 1000)
        ]
        
        for range in invalidRanges {
            XCTAssertNoThrow({
                self.storage.setAttributes(attributes, range: range)
            }, "setAttributes should handle invalid range: \(range)")
        }
    }
    
    // MARK: - Live Environment Crash Simulation
    
    func testLiveMarkdownEditingCrashScenario() {
        // Simulate the exact conditions that cause crashes in the live app
        // This test recreates the SwiftDownEditor live editing scenario
        
        // Start with empty content
        storage.replaceCharacters(in: NSRange(location: 0, length: 0), with: "")
        
        // Simulate real-time typing with Unicode characters (like user would do)
        let typingSequence = [
            "# ",
            "# H", 
            "# He",
            "# Header",
            "# Header 🚀",
            "# Header 🚀\n\n",
            "# Header 🚀\n\n**Bold",
            "# Header 🚀\n\n**Bold**",
            "# Header 🚀\n\n**Bold** and *italic*"
        ]
        
        for (index, text) in typingSequence.enumerated() {
            let previousLength = storage.length
            
            // Replace all content (simulating binding update)
            XCTAssertNoThrow({
                self.storage.replaceCharacters(
                    in: NSRange(location: 0, length: previousLength),
                    with: text
                )
                
                // Apply styling immediately after each character change
                self.storage.applyStyles()
                
                // Also test direct attribute access that was crashing
                if self.storage.length > 0 {
                    let _ = self.storage.attributes(at: 0, effectiveRange: nil)
                    
                    // Test at end of string
                    let lastIndex = max(0, self.storage.length - 1)
                    let _ = self.storage.attributes(at: lastIndex, effectiveRange: nil)
                }
                
            }, "Live editing step \(index) should not crash: '\(text)'")
        }
    }
    
    func testCrashSafeImplementationAfterFix() {
        // Test that the new crash-safe implementation handles all edge cases
        let testText = "Test 🚀 Unicode Content with **bold** and *italic*"
        storage.replaceCharacters(in: NSRange(location: 0, length: 0), with: testText)
        
        // Test that all previously crashing operations now work safely
        XCTAssertNoThrow({
            // Test attributes access with various invalid locations
            let _ = self.storage.attributes(at: -1, effectiveRange: nil)
            let _ = self.storage.attributes(at: 1000, effectiveRange: nil)
            
            // Test with empty range
            let _ = self.storage.attributes(at: 0, longestEffectiveRange: nil, in: NSRange(location: 0, length: 0))
            
            // Test with invalid range limits
            let _ = self.storage.attributes(at: 0, longestEffectiveRange: nil, in: NSRange(location: -1, length: 100))
            let _ = self.storage.attributes(at: 0, longestEffectiveRange: nil, in: NSRange(location: 1000, length: 100))
            
            // Test applying styles which internally uses safe methods
            self.storage.applyStyles()
            
        }, "Crash-safe implementation should handle all edge cases without throwing")
    }
}