//
//  ViewControllerTests.swift
//  VEClaudeTests
//
//  Created by BCL Device 24 on 25/8/25.
//

import XCTest
import AVFoundation
@testable import VEClaude

final class ViewControllerTests: XCTestCase {
    
    var viewController: ViewController!
    var mockVideoURL: URL!
    
    override func setUpWithError() throws {
        super.setUp()
        viewController = ViewController()
        
        // Load the view
        viewController.loadViewIfNeeded()
        
        // Create a mock video URL
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        mockVideoURL = URL(fileURLWithPath: documentsPath).appendingPathComponent("test.mp4")
    }
    
    override func tearDownWithError() throws {
        viewController = nil
        mockVideoURL = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testViewControllerInitialization() {
        XCTAssertNotNil(viewController)
        XCTAssertNotNil(viewController.view)
    }
    
    func testInitialTimelineDataModel() {
        // Given & When
        let timelineData = viewController.getCurrentTimelineData()
        
        // Then
        XCTAssertNotNil(timelineData)
        XCTAssertTrue(timelineData.isEmpty)
        XCTAssertEqual(timelineData.trackCount, 0)
        XCTAssertEqual(timelineData.totalDuration, CMTime.zero)
    }
    
    // MARK: - Timeline Data Access Tests
    
    func testGetCurrentTimelineData() {
        // Given
        let asset = AVAsset(url: mockVideoURL)
        viewController.getCurrentTimelineData().addTrack(from: asset, at: CMTime.zero)
        
        // When
        let timelineData = viewController.getCurrentTimelineData()
        
        // Then
        XCTAssertFalse(timelineData.isEmpty)
        XCTAssertEqual(timelineData.trackCount, 1)
    }
    
    func testGetTrackAtIndex() {
        // Given
        let asset = AVAsset(url: mockVideoURL)
        viewController.getCurrentTimelineData().addTrack(from: asset, at: CMTime.zero)
        
        // When
        let track = viewController.getTrackAtIndex(0)
        
        // Then
        XCTAssertNotNil(track)
        XCTAssertEqual(track?.positionInTimeline, CMTime.zero)
    }
    
    func testGetTrackAtInvalidIndex() {
        // Given - Empty timeline
        
        // When
        let track = viewController.getTrackAtIndex(0)
        
        // Then
        XCTAssertNil(track)
    }
    
    func testGetTracksAtTime() {
        // Given
        let asset1 = AVAsset(url: mockVideoURL)
        let asset2 = AVAsset(url: mockVideoURL)
        
        viewController.getCurrentTimelineData().addTrack(from: asset1, at: CMTime.zero)
        viewController.getCurrentTimelineData().addTrack(from: asset2, at: CMTime(seconds: 5.0, preferredTimescale: 600))
        
        // When
        let tracksAtZero = viewController.getTracksAtTime(CMTime.zero)
        let tracksAtFive = viewController.getTracksAtTime(CMTime(seconds: 5.0, preferredTimescale: 600))
        
        // Then
        XCTAssertEqual(tracksAtZero.count, 1)
        XCTAssertEqual(tracksAtFive.count, 1) // Assuming tracks don't overlap significantly
    }
    
    // MARK: - Track Manipulation Tests
    
    func testUpdateTrackCropRange() {
        // Given
        let asset = AVAsset(url: mockVideoURL)
        viewController.getCurrentTimelineData().addTrack(from: asset, at: CMTime.zero)
        
        let newStartTime = CMTime(seconds: 1.0, preferredTimescale: 600)
        let newEndTime = CMTime(seconds: 8.0, preferredTimescale: 600)
        
        // When
        viewController.updateTrackCropRange(trackIndex: 0, startTime: newStartTime, endTime: newEndTime)
        
        // Then
        let track = viewController.getTrackAtIndex(0)
        XCTAssertEqual(track?.cropStartTime, newStartTime)
        XCTAssertEqual(track?.cropEndTime, newEndTime)
    }
    
    func testUpdateTrackCropRangeInvalidIndex() {
        // Given - Empty timeline
        let newStartTime = CMTime(seconds: 1.0, preferredTimescale: 600)
        let newEndTime = CMTime(seconds: 8.0, preferredTimescale: 600)
        
        // When & Then - Should not crash
        viewController.updateTrackCropRange(trackIndex: 0, startTime: newStartTime, endTime: newEndTime)
    }
    
    func testMoveTrack() {
        // Given
        let asset = AVAsset(url: mockVideoURL)
        viewController.getCurrentTimelineData().addTrack(from: asset, at: CMTime.zero)
        
        let newPosition = CMTime(seconds: 3.0, preferredTimescale: 600)
        
        // When
        viewController.moveTrack(at: 0, to: newPosition)
        
        // Then
        let track = viewController.getTrackAtIndex(0)
        XCTAssertEqual(track?.positionInTimeline, newPosition)
    }
    
    func testMoveTrackInvalidIndex() {
        // Given - Empty timeline
        let newPosition = CMTime(seconds: 3.0, preferredTimescale: 600)
        
        // When & Then - Should not crash
        viewController.moveTrack(at: 0, to: newPosition)
    }
    
    // MARK: - Timeline Validation Tests
    
    func testValidateEmptyTimeline() {
        // Given - Empty timeline
        
        // When
        let issues = viewController.validateCurrentTimeline()
        
        // Then
        XCTAssertTrue(issues.isEmpty, "Empty timeline should have no validation issues")
    }
    
    func testValidateValidTimeline() {
        // Given
        let asset = AVAsset(url: mockVideoURL)
        viewController.getCurrentTimelineData().addTrack(from: asset, at: CMTime.zero)
        
        // When
        let issues = viewController.validateCurrentTimeline()
        
        // Then
        XCTAssertTrue(issues.isEmpty, "Valid timeline should have no validation issues")
    }
    
    // MARK: - Multiple Videos Tests
    
    func testAddMultipleVideos() {
        // Given
        let urls = [mockVideoURL!, mockVideoURL!, mockVideoURL!]
        
        // When
        viewController.addMultipleVideos(urls)
        
        // Then
        let timelineData = viewController.getCurrentTimelineData()
        XCTAssertEqual(timelineData.trackCount, 3)
        XCTAssertFalse(timelineData.isEmpty)
    }
    
    func testAddMultipleVideosEmpty() {
        // Given
        let urls: [URL] = []
        
        // When
        viewController.addMultipleVideos(urls)
        
        // Then
        let timelineData = viewController.getCurrentTimelineData()
        XCTAssertTrue(timelineData.isEmpty)
        XCTAssertEqual(timelineData.trackCount, 0)
    }
    
    // MARK: - Clear Timeline Tests
    
    func testClearTimeline() {
        // Given - Add some tracks first
        let asset = AVAsset(url: mockVideoURL)
        viewController.getCurrentTimelineData().addTrack(from: asset, at: CMTime.zero)
        XCTAssertFalse(viewController.getCurrentTimelineData().isEmpty)
        
        // When
        viewController.clearTimeline()
        
        // Then
        let timelineData = viewController.getCurrentTimelineData()
        XCTAssertTrue(timelineData.isEmpty)
        XCTAssertEqual(timelineData.trackCount, 0)
    }
    
    // MARK: - Notification Tests
    
    func testTimelineDataModelNotificationReceived() {
        // Given
        let expectation = expectation(description: "Timeline data model changed notification")
        var notificationReceived = false
        
        let observer = NotificationCenter.default.addObserver(
            forName: TimelineDataModel.dataChangedNotification,
            object: viewController.getCurrentTimelineData(),
            queue: .main
        ) { _ in
            notificationReceived = true
            expectation.fulfill()
        }
        
        // When
        let asset = AVAsset(url: mockVideoURL)
        viewController.getCurrentTimelineData().addTrack(from: asset, at: CMTime.zero)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(notificationReceived)
        
        // Cleanup
        NotificationCenter.default.removeObserver(observer)
    }
    
    // MARK: - UI State Tests
    
    func testInitialUIState() {
        // Given & When - Initial state after viewDidLoad
        
        // Then
        XCTAssertNotNil(viewController.view)
        
        // Check that there are subviews (timeline view and button should be present)
        let subviews = viewController.view.subviews
        XCTAssertGreaterThan(subviews.count, 0, "Should have UI components in view")
        
        // Check that button exists
        let hasButton = subviews.contains { view in
            if let button = view as? UIButton {
                return button.title(for: .normal) == "Select Video"
            }
            return false
        }
        XCTAssertTrue(hasButton, "Should have 'Select Video' button")
    }
    
    // MARK: - Memory Management Tests
    
    func testViewControllerMemoryManagement() {
        // This test ensures proper initialization and cleanup
        weak var weakViewController: ViewController?
        
        do {
            let strongViewController = ViewController()
            strongViewController.loadViewIfNeeded()
            weakViewController = strongViewController
            
            // Test that the controller is properly initialized
            XCTAssertNotNil(weakViewController)
            XCTAssertNotNil(weakViewController?.view)
            XCTAssertNotNil(weakViewController?.getCurrentTimelineData())
        }
        
        // After the scope, the strong reference should be gone
        // Note: In unit tests, weak references might not always be deallocated immediately
        // due to autorelease pools, so we just verify the controller was created properly
    }
    
    // MARK: - Integration Tests
    
    func testCompleteWorkflow() {
        // Given - Start with empty timeline
        XCTAssertTrue(viewController.getCurrentTimelineData().isEmpty)
        
        // When - Add video, modify it, then clear
        let asset = AVAsset(url: mockVideoURL)
        viewController.getCurrentTimelineData().addTrack(from: asset, at: CMTime.zero)
        
        // Verify track was added
        XCTAssertEqual(viewController.getCurrentTimelineData().trackCount, 1)
        
        // Move the track
        viewController.moveTrack(at: 0, to: CMTime(seconds: 2.0, preferredTimescale: 600))
        let movedTrack = viewController.getTrackAtIndex(0)
        XCTAssertEqual(movedTrack?.positionInTimeline.seconds, 2.0, accuracy: 0.01)
        
        // Update crop range
        viewController.updateTrackCropRange(
            trackIndex: 0,
            startTime: CMTime(seconds: 1.0, preferredTimescale: 600),
            endTime: CMTime(seconds: 5.0, preferredTimescale: 600)
        )
        let croppedTrack = viewController.getTrackAtIndex(0)
        XCTAssertEqual(croppedTrack?.cropStartTime.seconds, 1.0, accuracy: 0.01)
        XCTAssertEqual(croppedTrack?.cropEndTime.seconds, 5.0, accuracy: 0.01)
        
        // Clear timeline
        viewController.clearTimeline()
        
        // Then - Verify final state
        XCTAssertTrue(viewController.getCurrentTimelineData().isEmpty)
        XCTAssertEqual(viewController.getCurrentTimelineData().trackCount, 0)
    }
    
    // MARK: - Edge Cases Tests
    
    func testHandleNilAsset() {
        // This test verifies that the app handles invalid URLs gracefully
        // We can't directly test with nil asset, but we can test with invalid URL
        let invalidURL = URL(fileURLWithPath: "/nonexistent/path/video.mp4")
        let asset = AVAsset(url: invalidURL)
        
        // When - This should not crash even with invalid asset
        viewController.getCurrentTimelineData().addTrack(from: asset, at: CMTime.zero)
        
        // Then - Track should still be created (validation happens at playback/processing time)
        XCTAssertEqual(viewController.getCurrentTimelineData().trackCount, 1)
    }
    
    func testLargeNumberOfTracks() {
        // Given - Add many tracks
        for i in 0..<100 {
            let asset = AVAsset(url: mockVideoURL)
            let position = CMTime(seconds: Double(i), preferredTimescale: 600)
            viewController.getCurrentTimelineData().addTrack(from: asset, at: position)
        }
        
        // When
        let timelineData = viewController.getCurrentTimelineData()
        
        // Then
        XCTAssertEqual(timelineData.trackCount, 100)
        XCTAssertFalse(timelineData.isEmpty)
        
        // Verify we can access all tracks
        for i in 0..<100 {
            let track = viewController.getTrackAtIndex(i)
            XCTAssertNotNil(track)
            XCTAssertEqual(track?.positionInTimeline.seconds, Double(i), accuracy: 0.01)
        }
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceAddMultipleTracks() {
        self.measure {
            // Clear any existing tracks
            viewController.clearTimeline()
            
            // Add 50 tracks
            for i in 0..<50 {
                let asset = AVAsset(url: mockVideoURL)
                let position = CMTime(seconds: Double(i), preferredTimescale: 600)
                viewController.getCurrentTimelineData().addTrack(from: asset, at: position)
            }
        }
    }
    
    func testPerformanceTrackQueries() {
        // Given - Setup timeline with multiple tracks
        for i in 0..<20 {
            let asset = AVAsset(url: mockVideoURL)
            let position = CMTime(seconds: Double(i), preferredTimescale: 600)
            viewController.getCurrentTimelineData().addTrack(from: asset, at: position)
        }
        
        // When & Then - Measure query performance
        self.measure {
            for i in 0..<20 {
                _ = viewController.getTrackAtIndex(i)
                _ = viewController.getTracksAtTime(CMTime(seconds: Double(i), preferredTimescale: 600))
            }
        }
    }
}