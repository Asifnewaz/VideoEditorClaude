//
//  RangeContentViewTests.swift
//  VEClaudeTests
//
//  Created by BCL Device 24 on 25/8/25.
//

import XCTest
import AVFoundation
@testable import VEClaude

final class RangeContentViewTests: XCTestCase {
    
    var rangeContentView: RangeContentView!
    
    override func setUpWithError() throws {
        super.setUp()
        rangeContentView = RangeContentView(frame: CGRect(x: 0, y: 0, width: 300, height: 44))
    }
    
    override func tearDownWithError() throws {
        rangeContentView = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testRangeContentViewInitialization() {
        XCTAssertNotNil(rangeContentView)
        XCTAssertEqual(rangeContentView.startTime, CMTime.zero)
        XCTAssertEqual(rangeContentView.endTime, CMTime.zero)
        XCTAssertFalse(rangeContentView.supportUnlimitTime)
        XCTAssertEqual(rangeContentView.widthPerSecond, 10)
        XCTAssertEqual(rangeContentView.preloadCount, 0)
        XCTAssertTrue(rangeContentView.clipsToBounds)
    }
    
    func testInitWithCoder() {
        // Test that init with coder also works (for Interface Builder)
        let data = try! NSKeyedArchiver.archivedData(withRootObject: rangeContentView!, requiringSecureCoding: false)
        let unarchiver = try! NSKeyedUnarchiver(forReadingFrom: data)
        let decodedView = RangeContentView(coder: unarchiver)
        
        XCTAssertNotNil(decodedView)
    }
    
    // MARK: - Time Property Tests
    
    func testStartTimeDidSet() {
        // Given
        let newStartTime = CMTime(seconds: 2.0, preferredTimescale: 600)
        
        // When
        rangeContentView.startTime = newStartTime
        
        // Then
        XCTAssertEqual(rangeContentView.startTime, newStartTime)
    }
    
    func testEndTimeDidSet() {
        // Given
        let newEndTime = CMTime(seconds: 10.0, preferredTimescale: 600)
        
        // When
        rangeContentView.endTime = newEndTime
        
        // Then
        XCTAssertEqual(rangeContentView.endTime, newEndTime)
    }
    
    // MARK: - Duration Properties Tests
    
    func testMinDuration() {
        XCTAssertEqual(rangeContentView.minDuration, CMTime(seconds: 1.0))
        
        // Test setting new min duration
        let newMinDuration = CMTime(seconds: 0.5, preferredTimescale: 600)
        rangeContentView.minDuration = newMinDuration
        XCTAssertEqual(rangeContentView.minDuration, newMinDuration)
    }
    
    func testMaxDuration() {
        XCTAssertEqual(rangeContentView.maxDuration, CMTime.indefinite)
        
        // Test setting new max duration
        let newMaxDuration = CMTime(seconds: 30.0, preferredTimescale: 600)
        rangeContentView.maxDuration = newMaxDuration
        XCTAssertEqual(rangeContentView.maxDuration, newMaxDuration)
    }
    
    // MARK: - Content Width Tests
    
    func testContentWidth() {
        // Given
        rangeContentView.startTime = CMTime.zero
        rangeContentView.endTime = CMTime(seconds: 10.0, preferredTimescale: 600)
        rangeContentView.leftInsetDuration = CMTime.zero
        rangeContentView.rightInsetDuration = CMTime.zero
        rangeContentView.widthPerSecond = 10
        
        // When
        let contentWidth = rangeContentView.contentWidth
        
        // Then
        XCTAssertEqual(contentWidth, 100.0) // 10 seconds * 10 points per second
    }
    
    func testContentWidthWithInsets() {
        // Given
        rangeContentView.startTime = CMTime(seconds: 1.0, preferredTimescale: 600)
        rangeContentView.endTime = CMTime(seconds: 11.0, preferredTimescale: 600)
        rangeContentView.leftInsetDuration = CMTime(seconds: 0.5, preferredTimescale: 600)
        rangeContentView.rightInsetDuration = CMTime(seconds: 0.5, preferredTimescale: 600)
        rangeContentView.widthPerSecond = 20
        
        // When
        let contentWidth = rangeContentView.contentWidth
        
        // Then
        // Duration: 11 - 1 = 10 seconds
        // After insets: 10 - 0.5 - 0.5 = 9 seconds
        // Width: 9 seconds * 20 points per second = 180 points
        XCTAssertEqual(contentWidth, 180.0)
    }
    
    // MARK: - Boundary Detection Tests
    
    func testReachEndWithUnlimitTime() {
        // Given
        rangeContentView.supportUnlimitTime = true
        rangeContentView.endTime = CMTime(seconds: 100.0, preferredTimescale: 600)
        rangeContentView.maxDuration = CMTime(seconds: 50.0, preferredTimescale: 600)
        
        // When & Then
        XCTAssertFalse(rangeContentView.reachEnd())
    }
    
    func testReachEndWithoutUnlimitTime() {
        // Given
        rangeContentView.supportUnlimitTime = false
        rangeContentView.maxDuration = CMTime(seconds: 10.0, preferredTimescale: 600)
        
        // Case 1: End time reaches max duration
        rangeContentView.endTime = CMTime(seconds: 10.0, preferredTimescale: 600)
        XCTAssertTrue(rangeContentView.reachEnd())
        
        // Case 2: End time is before max duration
        rangeContentView.endTime = CMTime(seconds: 8.0, preferredTimescale: 600)
        XCTAssertFalse(rangeContentView.reachEnd())
    }
    
    func testReachHeadWithUnlimitTime() {
        // Given
        rangeContentView.supportUnlimitTime = true
        rangeContentView.startTime = CMTime.zero
        
        // When & Then
        XCTAssertFalse(rangeContentView.reachHead())
    }
    
    func testReachHeadWithoutUnlimitTime() {
        // Given
        rangeContentView.supportUnlimitTime = false
        
        // Case 1: Start time at zero
        rangeContentView.startTime = CMTime.zero
        XCTAssertTrue(rangeContentView.reachHead())
        
        // Case 2: Start time after zero
        rangeContentView.startTime = CMTime(seconds: 2.0, preferredTimescale: 600)
        XCTAssertFalse(rangeContentView.reachHead())
    }
    
    // MARK: - Expand Methods Tests
    
    func testExpandLeftWithUnlimitTime() {
        // Given
        rangeContentView.supportUnlimitTime = true
        rangeContentView.startTime = CMTime(seconds: 5.0, preferredTimescale: 600)
        rangeContentView.endTime = CMTime(seconds: 15.0, preferredTimescale: 600)
        rangeContentView.minDuration = CMTime(seconds: 1.0, preferredTimescale: 600)
        rangeContentView.widthPerSecond = 10
        
        // When - Expand left by 20 points (2 seconds)
        rangeContentView.expand(contentWidth: 20, left: true)
        
        // Then - Start time should decrease by 2 seconds
        XCTAssertEqual(rangeContentView.startTime.seconds, 3.0, accuracy: 0.01)
        XCTAssertEqual(rangeContentView.endTime.seconds, 15.0, accuracy: 0.01)
    }
    
    func testExpandRightWithUnlimitTime() {
        // Given
        rangeContentView.supportUnlimitTime = true
        rangeContentView.startTime = CMTime(seconds: 5.0, preferredTimescale: 600)
        rangeContentView.endTime = CMTime(seconds: 15.0, preferredTimescale: 600)
        rangeContentView.minDuration = CMTime(seconds: 1.0, preferredTimescale: 600)
        rangeContentView.widthPerSecond = 10
        
        // When - Expand right by 30 points (3 seconds)
        rangeContentView.expand(contentWidth: 30, left: false)
        
        // Then - End time should increase by 3 seconds
        XCTAssertEqual(rangeContentView.startTime.seconds, 5.0, accuracy: 0.01)
        XCTAssertEqual(rangeContentView.endTime.seconds, 18.0, accuracy: 0.01)
    }
    
    func testExpandLeftWithLimits() {
        // Given
        rangeContentView.supportUnlimitTime = false
        rangeContentView.startTime = CMTime(seconds: 2.0, preferredTimescale: 600)
        rangeContentView.endTime = CMTime(seconds: 8.0, preferredTimescale: 600)
        rangeContentView.minDuration = CMTime(seconds: 1.0, preferredTimescale: 600)
        rangeContentView.widthPerSecond = 10
        
        // When - Expand left by 30 points (3 seconds), but limited by zero
        rangeContentView.expand(contentWidth: 30, left: true)
        
        // Then - Start time should not go below zero
        XCTAssertEqual(rangeContentView.startTime.seconds, 0.0, accuracy: 0.01)
        XCTAssertEqual(rangeContentView.endTime.seconds, 8.0, accuracy: 0.01)
    }
    
    func testExpandRightWithLimits() {
        // Given
        rangeContentView.supportUnlimitTime = false
        rangeContentView.maxDuration = CMTime(seconds: 10.0, preferredTimescale: 600)
        rangeContentView.startTime = CMTime(seconds: 2.0, preferredTimescale: 600)
        rangeContentView.endTime = CMTime(seconds: 8.0, preferredTimescale: 600)
        rangeContentView.widthPerSecond = 10
        
        // When - Expand right by 30 points (3 seconds), but limited by max duration
        rangeContentView.expand(contentWidth: 30, left: false)
        
        // Then - End time should not exceed max duration
        XCTAssertEqual(rangeContentView.startTime.seconds, 2.0, accuracy: 0.01)
        XCTAssertEqual(rangeContentView.endTime.seconds, 10.0, accuracy: 0.01)
    }
    
    func testExpandRespectingMinDuration() {
        // Given
        rangeContentView.supportUnlimitTime = false
        rangeContentView.startTime = CMTime(seconds: 5.0, preferredTimescale: 600)
        rangeContentView.endTime = CMTime(seconds: 7.0, preferredTimescale: 600)
        rangeContentView.minDuration = CMTime(seconds: 3.0, preferredTimescale: 600)
        rangeContentView.widthPerSecond = 10
        
        // When - Try to expand left beyond min duration
        rangeContentView.expand(contentWidth: 30, left: true)
        
        // Then - Should respect min duration
        let actualDuration = rangeContentView.endTime.seconds - rangeContentView.startTime.seconds
        XCTAssertGreaterThanOrEqual(actualDuration, 3.0)
    }
    
    // MARK: - End Expand Tests
    
    func testEndExpandWithUnlimitTime() {
        // Given
        rangeContentView.supportUnlimitTime = true
        rangeContentView.startTime = CMTime(seconds: 5.0, preferredTimescale: 600)
        rangeContentView.endTime = CMTime(seconds: 15.0, preferredTimescale: 600)
        
        // When
        rangeContentView.endExpand()
        
        // Then - Should reset start time to zero and adjust end time
        XCTAssertEqual(rangeContentView.startTime, CMTime.zero)
        XCTAssertEqual(rangeContentView.endTime.seconds, 10.0, accuracy: 0.01) // 15 - 5 = 10
    }
    
    func testEndExpandWithoutUnlimitTime() {
        // Given
        rangeContentView.supportUnlimitTime = false
        rangeContentView.startTime = CMTime(seconds: 5.0, preferredTimescale: 600)
        rangeContentView.endTime = CMTime(seconds: 15.0, preferredTimescale: 600)
        
        // When
        rangeContentView.endExpand()
        
        // Then - Should not change anything
        XCTAssertEqual(rangeContentView.startTime.seconds, 5.0, accuracy: 0.01)
        XCTAssertEqual(rangeContentView.endTime.seconds, 15.0, accuracy: 0.01)
    }
    
    // MARK: - Width Per Second Tests
    
    func testWidthPerSecondProperty() {
        // Given & When
        rangeContentView.widthPerSecond = 15
        
        // Then
        XCTAssertEqual(rangeContentView.widthPerSecond, 15)
    }
    
    func testContentWidthWithDifferentWidthPerSecond() {
        // Given
        rangeContentView.startTime = CMTime.zero
        rangeContentView.endTime = CMTime(seconds: 5.0, preferredTimescale: 600)
        rangeContentView.leftInsetDuration = CMTime.zero
        rangeContentView.rightInsetDuration = CMTime.zero
        
        // Test with different widthPerSecond values
        rangeContentView.widthPerSecond = 20
        XCTAssertEqual(rangeContentView.contentWidth, 100.0) // 5 * 20
        
        rangeContentView.widthPerSecond = 5
        XCTAssertEqual(rangeContentView.contentWidth, 25.0) // 5 * 5
    }
    
    // MARK: - Preload Count Tests
    
    func testPreloadCountProperty() {
        // Given & When
        rangeContentView.preloadCount = 5
        
        // Then
        XCTAssertEqual(rangeContentView.preloadCount, 5)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceContentWidthCalculation() {
        // Given
        rangeContentView.startTime = CMTime.zero
        rangeContentView.endTime = CMTime(seconds: 100.0, preferredTimescale: 600)
        rangeContentView.leftInsetDuration = CMTime(seconds: 1.0, preferredTimescale: 600)
        rangeContentView.rightInsetDuration = CMTime(seconds: 1.0, preferredTimescale: 600)
        
        // When & Then
        self.measure {
            for _ in 0..<1000 {
                _ = rangeContentView.contentWidth
            }
        }
    }
    
    func testPerformanceBoundaryDetection() {
        // Given
        rangeContentView.supportUnlimitTime = false
        rangeContentView.maxDuration = CMTime(seconds: 10.0, preferredTimescale: 600)
        rangeContentView.endTime = CMTime(seconds: 9.5, preferredTimescale: 600)
        rangeContentView.startTime = CMTime(seconds: 0.5, preferredTimescale: 600)
        
        // When & Then
        self.measure {
            for _ in 0..<1000 {
                _ = rangeContentView.reachEnd()
                _ = rangeContentView.reachHead()
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testZeroDuration() {
        // Given
        rangeContentView.startTime = CMTime(seconds: 5.0, preferredTimescale: 600)
        rangeContentView.endTime = CMTime(seconds: 5.0, preferredTimescale: 600)
        rangeContentView.leftInsetDuration = CMTime.zero
        rangeContentView.rightInsetDuration = CMTime.zero
        
        // When & Then
        XCTAssertEqual(rangeContentView.contentWidth, 0.0)
    }
    
    func testNegativeDuration() {
        // Given - End time before start time
        rangeContentView.startTime = CMTime(seconds: 10.0, preferredTimescale: 600)
        rangeContentView.endTime = CMTime(seconds: 5.0, preferredTimescale: 600)
        rangeContentView.leftInsetDuration = CMTime.zero
        rangeContentView.rightInsetDuration = CMTime.zero
        
        // When & Then - Should handle negative duration gracefully
        XCTAssertEqual(rangeContentView.contentWidth, -50.0) // -5 seconds * 10 = -50
    }
    
    func testLargeInsetDurations() {
        // Given - Insets larger than total duration
        rangeContentView.startTime = CMTime.zero
        rangeContentView.endTime = CMTime(seconds: 5.0, preferredTimescale: 600)
        rangeContentView.leftInsetDuration = CMTime(seconds: 3.0, preferredTimescale: 600)
        rangeContentView.rightInsetDuration = CMTime(seconds: 3.0, preferredTimescale: 600)
        
        // When & Then - Should result in negative content width
        XCTAssertEqual(rangeContentView.contentWidth, -10.0) // (5 - 3 - 3) * 10 = -10
    }
}