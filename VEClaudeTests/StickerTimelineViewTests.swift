//
//  StickerTimelineViewTests.swift
//  VEClaudeTests
//
//  Created by Claude on 25/8/25.
//

import XCTest
import AVFoundation
@testable import VEClaude

final class StickerTimelineViewTests: XCTestCase {
    
    var timelineView: TimeLineView!
    
    override func setUpWithError() throws {
        super.setUp()
        timelineView = TimeLineView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
    }
    
    override func tearDownWithError() throws {
        timelineView = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testStickerTimelineViewInitialization() {
        XCTAssertNotNil(timelineView)
        XCTAssertNotNil(timelineView.scrollView)
        XCTAssertNotNil(timelineView.contentView)
        XCTAssertNotNil(timelineView.stickerContentView)
        XCTAssertEqual(timelineView.widthPerSecond, 60)
    }
    
    func testStickerTimelineViewHasNoDefaultStickerInitially() {
        // Stickers are added when timeline duration is set
        XCTAssertEqual(timelineView.stickerViews.count, 0)
    }
    
    // MARK: - Duration Tests
    
    func testNoAutomaticStickerAdditionOnVideoLoad() {
        // Given
        let trackItems: [AssetTrackItem] = []
        
        // When - simulate loading video timeline
        timelineView.reload(with: trackItems)
        
        // Then - no automatic stickers should be added
        // Note: Stickers are only added when user explicitly requests them
        XCTAssertEqual(timelineView.stickerViews.count, 0) // No automatic stickers
    }
    
    func testStickerIndependentTrimming() {
        // Given - Add a sticker that extends beyond typical video duration
        let stickerView = StickerRangeView()
        let startTime = CMTime(seconds: 5.0, preferredTimescale: 600) // Beyond typical video
        let duration = CMTime(seconds: 10.0, preferredTimescale: 600) // Long duration
        
        // When
        timelineView.addStickerView(stickerView, at: startTime, duration: duration)
        
        // Then - Verify sticker can exist independently
        XCTAssertEqual(timelineView.stickerViews.count, 1)
        XCTAssertEqual(stickerView.superview, timelineView.stickerContentView)
        XCTAssertEqual(stickerView.contentView.startTime, startTime)
        XCTAssertEqual(stickerView.contentView.endTime, startTime + duration)
    }
    
    // MARK: - Sticker Management Tests
    
    func testAddStickerView() {
        // Given
        let initialCount = timelineView.stickerViews.count
        let stickerView = StickerRangeView()
        let startTime = CMTime(seconds: 2.0, preferredTimescale: 600)
        let duration = CMTime(seconds: 4.0, preferredTimescale: 600)
        
        // When
        timelineView.addStickerView(stickerView, at: startTime, duration: duration)
        
        // Then
        XCTAssertEqual(timelineView.stickerViews.count, initialCount + 1)
        XCTAssertTrue(timelineView.stickerViews.contains(stickerView))
        XCTAssertEqual(stickerView.contentView.startTime, startTime)
        XCTAssertEqual(stickerView.contentView.endTime - stickerView.contentView.startTime, duration)
        XCTAssertEqual(stickerView.superview, timelineView.stickerContentView)
    }
    
    func testRemoveStickerView() {
        // Given - Add a sticker first
        let stickerView = StickerRangeView()
        timelineView.addStickerView(stickerView, at: CMTime.zero, duration: CMTime(seconds: 2.0, preferredTimescale: 600))
        let initialCount = timelineView.stickerViews.count
        
        // When
        timelineView.removeStickerView(stickerView)
        
        // Then
        XCTAssertEqual(timelineView.stickerViews.count, initialCount - 1)
        XCTAssertFalse(timelineView.stickerViews.contains(stickerView))
        XCTAssertNil(stickerView.superview)
    }
    
    func testRemoveAllStickerViews() {
        // Given - Add multiple stickers
        let sticker1 = StickerRangeView()
        let sticker2 = StickerRangeView()
        timelineView.addStickerView(sticker1, at: CMTime.zero, duration: CMTime(seconds: 2.0, preferredTimescale: 600))
        timelineView.addStickerView(sticker2, at: CMTime(seconds: 3.0, preferredTimescale: 600), duration: CMTime(seconds: 2.0, preferredTimescale: 600))
        
        // When
        timelineView.removeAllStickerViews()
        
        // Then
        XCTAssertEqual(timelineView.stickerViews.count, 0)
        XCTAssertNil(sticker1.superview)
        XCTAssertNil(sticker2.superview)
    }
    
    // MARK: - Layout Tests
    
    func testLayoutUsesSharedScrollView() {
        // Given
        timelineView.frame = CGRect(x: 0, y: 0, width: 400, height: 200)
        
        // When
        timelineView.layoutSubviews()
        
        // Then - Verify sticker content view is positioned correctly within shared scrollview
        let expectedInset = timelineView.bounds.width * 0.5 - timelineView.videoRangeViewEarWidth
        XCTAssertEqual(timelineView.scrollView.contentInset.left, expectedInset)
        XCTAssertEqual(timelineView.scrollView.contentInset.right, expectedInset)
    }
    
    // MARK: - Integration Tests
    
    func testStickerTimelineIntegrationWithTimeLineView() {
        // Given
        let timeline = TimeLineView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        
        // When - Access integrated sticker content view
        let stickerContentView = timeline.stickerContentView
        
        // Then
        XCTAssertNotNil(stickerContentView)
        XCTAssertEqual(stickerContentView?.superview, timeline.contentView)
    }
    
    func testAddStickerThroughTimeLineView() {
        // Given
        let timeline = TimeLineView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        let initialCount = timeline.stickerViews.count
        let startTime = CMTime(seconds: 1.0, preferredTimescale: 600)
        let duration = CMTime(seconds: 3.0, preferredTimescale: 600)
        
        // When
        timeline.addSticker(at: startTime, duration: duration)
        
        // Then
        XCTAssertEqual(timeline.stickerViews.count, initialCount + 1)
        
        let addedSticker = timeline.stickerViews.last
        XCTAssertNotNil(addedSticker)
        XCTAssertEqual(addedSticker?.contentView.startTime, startTime)
        XCTAssertEqual(addedSticker?.contentView.endTime, startTime + duration)
    }
    
    // Commented out since maxExpandEnabled property was removed
    /*
    func testMaxExpandConfiguration() {
        // Given
        let timeline = TimeLineView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        
        // Then - Default should be false
        XCTAssertFalse(timeline.maxExpandEnabled)
        
        // When - Enable max expand
        timeline.setMaxExpandEnabled(true)
        
        // Then
        XCTAssertTrue(timeline.maxExpandEnabled)
        
        // When - Disable max expand
        timeline.setMaxExpandEnabled(false)
        
        // Then
        XCTAssertFalse(timeline.maxExpandEnabled)
    }
    */
    
    func testAddFullWidthSticker() {
        // Given - Timeline with no videos (should use minimum duration)
        let timeline = TimeLineView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        let initialCount = timeline.stickerViews.count
        
        // When - Add full width sticker
        timeline.addFullWidthSticker()
        
        // Then - Sticker should be added with minimum duration
        XCTAssertEqual(timeline.stickerViews.count, initialCount + 1)
        
        let addedSticker = timeline.stickerViews.last
        XCTAssertNotNil(addedSticker)
        XCTAssertEqual(addedSticker?.contentView.startTime, CMTime.zero)
        XCTAssertEqual(addedSticker?.contentView.endTime.seconds, 3.0, accuracy: 0.01) // Minimum 3 seconds
        
        // Verify that sticker width includes ear width for proper alignment
        // Note: Actual width verification would require accessing view frame after layout
    }
}

// MARK: - StickerRangeView Tests

final class StickerRangeViewTests: XCTestCase {
    
    var stickerRangeView: StickerRangeView!
    
    override func setUpWithError() throws {
        super.setUp()
        stickerRangeView = StickerRangeView(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
    }
    
    override func tearDownWithError() throws {
        stickerRangeView = nil
        super.tearDown()
    }
    
    func testStickerRangeViewInitialization() {
        XCTAssertNotNil(stickerRangeView)
        XCTAssertEqual(stickerRangeView.contentView.startTime, CMTime.zero)
        XCTAssertEqual(stickerRangeView.contentView.endTime, CMTime(seconds: 3.0, preferredTimescale: 600)) // Default duration from StickerContentView
    }
    
    func testSetupAsDefault() {
        // When
        stickerRangeView.setupAsDefault()
        
        // Then
        // We can't easily test the visual changes, but we can verify the method doesn't crash
        XCTAssertNotNil(stickerRangeView)
    }
    
    func testSetSelected() {
        // When - This should not crash
        stickerRangeView.setSelected(true)
        stickerRangeView.setSelected(false)
        
        // Then
        XCTAssertNotNil(stickerRangeView)
    }
}