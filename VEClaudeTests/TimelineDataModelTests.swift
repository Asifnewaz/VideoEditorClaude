//
//  TimelineDataModelTests.swift
//  VEClaudeTests
//
//  Created by BCL Device 24 on 25/8/25.
//

import XCTest
import AVFoundation
@testable import VEClaude

final class TimelineDataModelTests: XCTestCase {
    
    var timelineDataModel: TimelineDataModel!
    var mockAsset: AVAsset!
    var mockVideoTrack: AVAssetTrack!
    
    override func setUpWithError() throws {
        super.setUp()
        timelineDataModel = TimelineDataModel()
        
        // Create a mock video URL for testing
        let bundle = Bundle(for: type(of: self))
        if let videoURL = bundle.url(forResource: "test_video", withExtension: "mp4") {
            mockAsset = AVAsset(url: videoURL)
        } else {
            // Fallback: create a mock asset with known properties
            mockAsset = createMockAsset()
        }
    }
    
    override func tearDownWithError() throws {
        timelineDataModel = nil
        mockAsset = nil
        mockVideoTrack = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createMockAsset() -> AVAsset {
        // Create a simple test video URL (you can also use a test video file)
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let videoURL = URL(fileURLWithPath: documentsPath).appendingPathComponent("test.mp4")
        return AVAsset(url: videoURL)
    }
    
    private func createMockVideoTrackInfo() -> VideoTrackInfo {
        // Use the test helper method from VideoTrackInfo
        return VideoTrackInfo.createMockTrackInfo(asset: mockAsset)
    }
    
    // MARK: - Timeline Data Model Tests
    
    func testTimelineDataModelInitialization() {
        XCTAssertNotNil(timelineDataModel)
        XCTAssertEqual(timelineDataModel.trackCount, 0)
        XCTAssertTrue(timelineDataModel.isEmpty)
        XCTAssertEqual(timelineDataModel.totalDuration, CMTime.zero)
    }
    
    func testAddTrackFromAsset() {
        // Given
        let initialTrackCount = timelineDataModel.trackCount
        
        // When
        timelineDataModel.addTrack(from: mockAsset, at: CMTime.zero)
        
        // Then
        XCTAssertEqual(timelineDataModel.trackCount, initialTrackCount + 1)
        XCTAssertFalse(timelineDataModel.isEmpty)
        XCTAssertGreaterThan(timelineDataModel.totalDuration, CMTime.zero)
    }
    
    func testAddTrackObject() {
        // Given
        let trackInfo = createMockVideoTrackInfo()
        let track = TimelineTrack(trackInfo: trackInfo, positionInTimeline: CMTime.zero)
        
        // When
        timelineDataModel.addTrack(track)
        
        // Then
        XCTAssertEqual(timelineDataModel.trackCount, 1)
        XCTAssertFalse(timelineDataModel.isEmpty)
        XCTAssertEqual(timelineDataModel.totalDuration, track.croppedDuration)
    }
    
    func testRemoveTrackById() {
        // Given
        let trackInfo = createMockVideoTrackInfo()
        let track = TimelineTrack(trackInfo: trackInfo, positionInTimeline: CMTime.zero)
        timelineDataModel.addTrack(track)
        let trackId = track.id
        
        // When
        timelineDataModel.removeTrack(withId: trackId)
        
        // Then
        XCTAssertEqual(timelineDataModel.trackCount, 0)
        XCTAssertTrue(timelineDataModel.isEmpty)
        XCTAssertNil(timelineDataModel.getTrack(withId: trackId))
    }
    
    func testRemoveTrackByIndex() {
        // Given
        let trackInfo = createMockVideoTrackInfo()
        let track = TimelineTrack(trackInfo: trackInfo, positionInTimeline: CMTime.zero)
        timelineDataModel.addTrack(track)
        
        // When
        timelineDataModel.removeTrack(at: 0)
        
        // Then
        XCTAssertEqual(timelineDataModel.trackCount, 0)
        XCTAssertTrue(timelineDataModel.isEmpty)
        XCTAssertNil(timelineDataModel.getTrack(at: 0))
    }
    
    func testGetTrackAtIndex() {
        // Given
        let trackInfo = createMockVideoTrackInfo()
        let track = TimelineTrack(trackInfo: trackInfo, positionInTimeline: CMTime.zero)
        timelineDataModel.addTrack(track)
        
        // When
        let retrievedTrack = timelineDataModel.getTrack(at: 0)
        
        // Then
        XCTAssertNotNil(retrievedTrack)
        XCTAssertEqual(retrievedTrack?.id, track.id)
    }
    
    func testGetTrackById() {
        // Given
        let trackInfo = createMockVideoTrackInfo()
        let track = TimelineTrack(trackInfo: trackInfo, positionInTimeline: CMTime.zero)
        timelineDataModel.addTrack(track)
        let trackId = track.id
        
        // When
        let retrievedTrack = timelineDataModel.getTrack(withId: trackId)
        
        // Then
        XCTAssertNotNil(retrievedTrack)
        XCTAssertEqual(retrievedTrack?.id, trackId)
    }
    
    func testTotalDurationCalculation() {
        // Given
        let trackInfo1 = createMockVideoTrackInfo()
        let track1 = TimelineTrack(trackInfo: trackInfo1, positionInTimeline: CMTime.zero)
        
        let trackInfo2 = createMockVideoTrackInfo()
        let position2 = CMTime(seconds: 5.0, preferredTimescale: 600)
        let track2 = TimelineTrack(trackInfo: trackInfo2, positionInTimeline: position2)
        
        // When
        timelineDataModel.addTrack(track1)
        timelineDataModel.addTrack(track2)
        
        // Then
        let expectedDuration = CMTimeAdd(position2, track2.croppedDuration)
        XCTAssertEqual(timelineDataModel.totalDuration.seconds, expectedDuration.seconds, accuracy: 0.1)
    }
    
    func testMoveTrack() {
        // Given
        let trackInfo = createMockVideoTrackInfo()
        let track = TimelineTrack(trackInfo: trackInfo, positionInTimeline: CMTime.zero)
        timelineDataModel.addTrack(track)
        let newPosition = CMTime(seconds: 3.0, preferredTimescale: 600)
        
        // When
        timelineDataModel.moveTrack(withId: track.id, to: newPosition)
        
        // Then
        let movedTrack = timelineDataModel.getTrack(withId: track.id)
        XCTAssertEqual(movedTrack?.positionInTimeline, newPosition)
    }
    
    func testUpdateTrackCropRange() {
        // Given
        let trackInfo = createMockVideoTrackInfo()
        let track = TimelineTrack(trackInfo: trackInfo, positionInTimeline: CMTime.zero)
        timelineDataModel.addTrack(track)
        let newStartTime = CMTime(seconds: 1.0, preferredTimescale: 600)
        let newEndTime = CMTime(seconds: 8.0, preferredTimescale: 600)
        
        // When
        timelineDataModel.updateTrackCropRange(trackId: track.id, startTime: newStartTime, endTime: newEndTime)
        
        // Then
        let updatedTrack = timelineDataModel.getTrack(withId: track.id)
        XCTAssertEqual(updatedTrack?.cropStartTime, newStartTime)
        XCTAssertEqual(updatedTrack?.cropEndTime, newEndTime)
    }
    
    func testGetTracksAtTime() {
        // Given
        let trackInfo1 = createMockVideoTrackInfo()
        let track1 = TimelineTrack(trackInfo: trackInfo1, positionInTimeline: CMTime.zero)
        
        let trackInfo2 = createMockVideoTrackInfo()
        let position2 = CMTime(seconds: 5.0, preferredTimescale: 600)
        let track2 = TimelineTrack(trackInfo: trackInfo2, positionInTimeline: position2)
        
        timelineDataModel.addTrack(track1)
        timelineDataModel.addTrack(track2)
        
        // When & Then
        let tracksAtTime3 = timelineDataModel.getTracksAtTime(CMTime(seconds: 3.0, preferredTimescale: 600))
        XCTAssertEqual(tracksAtTime3.count, 1)
        XCTAssertEqual(tracksAtTime3.first?.id, track1.id)
        
        let tracksAtTime7 = timelineDataModel.getTracksAtTime(CMTime(seconds: 7.0, preferredTimescale: 600))
        XCTAssertEqual(tracksAtTime7.count, 1)
        XCTAssertEqual(tracksAtTime7.first?.id, track2.id)
    }
    
    func testClearAllTracks() {
        // Given
        let trackInfo = createMockVideoTrackInfo()
        let track = TimelineTrack(trackInfo: trackInfo, positionInTimeline: CMTime.zero)
        timelineDataModel.addTrack(track)
        
        // When
        timelineDataModel.clearAllTracks()
        
        // Then
        XCTAssertEqual(timelineDataModel.trackCount, 0)
        XCTAssertTrue(timelineDataModel.isEmpty)
        XCTAssertEqual(timelineDataModel.totalDuration, CMTime.zero)
    }
    
    func testValidateTimeline() {
        // Given - Valid timeline
        let trackInfo = createMockVideoTrackInfo()
        let track = TimelineTrack(trackInfo: trackInfo, positionInTimeline: CMTime.zero)
        timelineDataModel.addTrack(track)
        
        // When
        let validationIssues = timelineDataModel.validateTimeline()
        
        // Then
        XCTAssertTrue(validationIssues.isEmpty, "Valid timeline should have no issues")
    }
    
    func testValidateTimelineWithInvalidTrack() {
        // Given - Invalid timeline (negative crop start time)
        let trackInfo = createMockVideoTrackInfo()
        let invalidStartTime = CMTime(seconds: -1.0, preferredTimescale: 600)
        let track = TimelineTrack(
            trackInfo: trackInfo,
            cropStartTime: invalidStartTime,
            cropEndTime: CMTime(seconds: 5.0, preferredTimescale: 600),
            positionInTimeline: CMTime.zero
        )
        timelineDataModel.addTrack(track)
        
        // When
        let validationIssues = timelineDataModel.validateTimeline()
        
        // Then
        XCTAssertFalse(validationIssues.isEmpty, "Invalid timeline should have issues")
        XCTAssertTrue(validationIssues.contains { $0.contains("negative crop start time") })
    }
    
    // MARK: - Notification Tests
    
    func testNotificationPostedOnTrackAdd() {
        // Given
        let expectation = expectation(description: "Track add notification")
        var notificationReceived = false
        
        let observer = NotificationCenter.default.addObserver(
            forName: TimelineDataModel.dataChangedNotification,
            object: timelineDataModel,
            queue: .main
        ) { _ in
            notificationReceived = true
            expectation.fulfill()
        }
        
        let trackInfo = createMockVideoTrackInfo()
        let track = TimelineTrack(trackInfo: trackInfo, positionInTimeline: CMTime.zero)
        
        // When
        timelineDataModel.addTrack(track)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(notificationReceived)
        
        // Cleanup
        NotificationCenter.default.removeObserver(observer)
    }
    
    func testNotificationPostedOnTrackRemove() {
        // Given
        let trackInfo = createMockVideoTrackInfo()
        let track = TimelineTrack(trackInfo: trackInfo, positionInTimeline: CMTime.zero)
        timelineDataModel.addTrack(track)
        
        let expectation = expectation(description: "Track remove notification")
        var notificationReceived = false
        
        let observer = NotificationCenter.default.addObserver(
            forName: TimelineDataModel.dataChangedNotification,
            object: timelineDataModel,
            queue: .main
        ) { _ in
            notificationReceived = true
            expectation.fulfill()
        }
        
        // When
        timelineDataModel.removeTrack(withId: track.id)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(notificationReceived)
        
        // Cleanup
        NotificationCenter.default.removeObserver(observer)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceAddMultipleTracks() {
        self.measure {
            // Add 100 tracks
            for i in 0..<100 {
                let trackInfo = createMockVideoTrackInfo()
                let position = CMTime(seconds: Double(i), preferredTimescale: 600)
                let track = TimelineTrack(trackInfo: trackInfo, positionInTimeline: position)
                timelineDataModel.addTrack(track)
            }
            timelineDataModel.clearAllTracks()
        }
    }
    
    func testPerformanceTotalDurationCalculation() {
        // Given - Add multiple tracks
        for i in 0..<50 {
            let trackInfo = createMockVideoTrackInfo()
            let position = CMTime(seconds: Double(i), preferredTimescale: 600)
            let track = TimelineTrack(trackInfo: trackInfo, positionInTimeline: position)
            timelineDataModel.addTrack(track)
        }
        
        // When - Measure total duration calculation
        self.measure {
            _ = timelineDataModel.totalDuration
        }
    }
}