//
//  TimelineTrackTests.swift
//  VEClaudeTests
//
//  Created by BCL Device 24 on 25/8/25.
//

import XCTest
import AVFoundation
@testable import VEClaude

final class TimelineTrackTests: XCTestCase {
    
    var mockVideoTrackInfo: VideoTrackInfo!
    
    override func setUpWithError() throws {
        super.setUp()
        mockVideoTrackInfo = createMockVideoTrackInfo()
    }
    
    override func tearDownWithError() throws {
        mockVideoTrackInfo = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createMockVideoTrackInfo() -> VideoTrackInfo {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let videoURL = URL(fileURLWithPath: documentsPath).appendingPathComponent("test.mp4")
        let mockAsset = AVAsset(url: videoURL)
        
        // Create a mock AVAssetTrack for testing
        // Since we can't create AVAssetTrack directly, we'll create VideoTrackInfo properties manually
        // by extending VideoTrackInfo with a test initializer
        return VideoTrackInfo.createMockTrackInfo(asset: mockAsset)
    }
    
    // MARK: - Initialization Tests
    
    func testTimelineTrackDefaultInitialization() {
        // When
        let track = TimelineTrack(trackInfo: mockVideoTrackInfo)
        
        // Then
        XCTAssertNotNil(track.id)
        XCTAssertEqual(track.positionInTimeline, CMTime.zero)
        XCTAssertEqual(track.cropStartTime, CMTime.zero)
        XCTAssertEqual(track.cropEndTime, mockVideoTrackInfo.originalDuration)
        XCTAssertEqual(track.croppedDuration, mockVideoTrackInfo.originalDuration)
        XCTAssertTrue(track.isValid)
    }
    
    func testTimelineTrackInitializationWithPosition() {
        // Given
        let position = CMTime(seconds: 5.0, preferredTimescale: 600)
        
        // When
        let track = TimelineTrack(trackInfo: mockVideoTrackInfo, positionInTimeline: position)
        
        // Then
        XCTAssertEqual(track.positionInTimeline, position)
        XCTAssertEqual(track.cropStartTime, CMTime.zero)
        XCTAssertEqual(track.cropEndTime, mockVideoTrackInfo.originalDuration)
    }
    
    func testTimelineTrackFullInitialization() {
        // Given
        let cropStartTime = CMTime(seconds: 2.0, preferredTimescale: 600)
        let cropEndTime = CMTime(seconds: 8.0, preferredTimescale: 600)
        let position = CMTime(seconds: 3.0, preferredTimescale: 600)
        
        // When
        let track = TimelineTrack(
            trackInfo: mockVideoTrackInfo,
            cropStartTime: cropStartTime,
            cropEndTime: cropEndTime,
            positionInTimeline: position
        )
        
        // Then
        XCTAssertEqual(track.cropStartTime, cropStartTime)
        XCTAssertEqual(track.cropEndTime, cropEndTime)
        XCTAssertEqual(track.positionInTimeline, position)
        XCTAssertEqual(track.croppedDuration.seconds, 6.0, accuracy: 0.01)
    }
    
    // MARK: - Computed Properties Tests
    
    func testCroppedDuration() {
        // Given
        let cropStartTime = CMTime(seconds: 1.0, preferredTimescale: 600)
        let cropEndTime = CMTime(seconds: 7.0, preferredTimescale: 600)
        let track = TimelineTrack(
            trackInfo: mockVideoTrackInfo,
            cropStartTime: cropStartTime,
            cropEndTime: cropEndTime,
            positionInTimeline: CMTime.zero
        )
        
        // When
        let duration = track.croppedDuration
        
        // Then
        XCTAssertEqual(duration.seconds, 6.0, accuracy: 0.01)
    }
    
    func testEndTimeInTimeline() {
        // Given
        let cropStartTime = CMTime(seconds: 1.0, preferredTimescale: 600)
        let cropEndTime = CMTime(seconds: 6.0, preferredTimescale: 600)
        let position = CMTime(seconds: 3.0, preferredTimescale: 600)
        let track = TimelineTrack(
            trackInfo: mockVideoTrackInfo,
            cropStartTime: cropStartTime,
            cropEndTime: cropEndTime,
            positionInTimeline: position
        )
        
        // When
        let endTime = track.endTimeInTimeline
        
        // Then
        // Position (3s) + Cropped Duration (5s) = 8s
        XCTAssertEqual(endTime.seconds, 8.0, accuracy: 0.01)
    }
    
    func testIsValidWithValidTrack() {
        // Given
        let track = TimelineTrack(trackInfo: mockVideoTrackInfo)
        
        // When & Then
        XCTAssertTrue(track.isValid)
    }
    
    func testIsValidWithInvalidCropTimes() {
        // Given - End time before start time
        let cropStartTime = CMTime(seconds: 8.0, preferredTimescale: 600)
        let cropEndTime = CMTime(seconds: 2.0, preferredTimescale: 600)
        let track = TimelineTrack(
            trackInfo: mockVideoTrackInfo,
            cropStartTime: cropStartTime,
            cropEndTime: cropEndTime,
            positionInTimeline: CMTime.zero
        )
        
        // When & Then
        XCTAssertFalse(track.isValid)
    }
    
    func testIsValidWithInvalidTime() {
        // Given - Invalid time
        let track = TimelineTrack(
            trackInfo: mockVideoTrackInfo,
            cropStartTime: CMTime.invalid,
            cropEndTime: CMTime(seconds: 5.0, preferredTimescale: 600),
            positionInTimeline: CMTime.zero
        )
        
        // When & Then
        XCTAssertFalse(track.isValid)
    }
    
    // MARK: - Update Methods Tests
    
    func testUpdateCropRangeValid() {
        // Given
        let track = TimelineTrack(trackInfo: mockVideoTrackInfo)
        let newStartTime = CMTime(seconds: 2.0, preferredTimescale: 600)
        let newEndTime = CMTime(seconds: 8.0, preferredTimescale: 600)
        
        // When
        track.updateCropRange(startTime: newStartTime, endTime: newEndTime)
        
        // Then
        XCTAssertEqual(track.cropStartTime, newStartTime)
        XCTAssertEqual(track.cropEndTime, newEndTime)
        XCTAssertEqual(track.croppedDuration.seconds, 6.0, accuracy: 0.01)
    }
    
    func testUpdateCropRangeInvalidEndBeforeStart() {
        // Given
        let track = TimelineTrack(trackInfo: mockVideoTrackInfo)
        let originalStartTime = track.cropStartTime
        let originalEndTime = track.cropEndTime
        
        let invalidStartTime = CMTime(seconds: 8.0, preferredTimescale: 600)
        let invalidEndTime = CMTime(seconds: 2.0, preferredTimescale: 600)
        
        // When
        track.updateCropRange(startTime: invalidStartTime, endTime: invalidEndTime)
        
        // Then - Should not update with invalid range
        XCTAssertEqual(track.cropStartTime, originalStartTime)
        XCTAssertEqual(track.cropEndTime, originalEndTime)
    }
    
    func testUpdateCropRangeInvalidNegativeStartTime() {
        // Given
        let track = TimelineTrack(trackInfo: mockVideoTrackInfo)
        let originalStartTime = track.cropStartTime
        let originalEndTime = track.cropEndTime
        
        let invalidStartTime = CMTime(seconds: -1.0, preferredTimescale: 600)
        let validEndTime = CMTime(seconds: 5.0, preferredTimescale: 600)
        
        // When
        track.updateCropRange(startTime: invalidStartTime, endTime: validEndTime)
        
        // Then - Should not update with negative start time
        XCTAssertEqual(track.cropStartTime, originalStartTime)
        XCTAssertEqual(track.cropEndTime, originalEndTime)
    }
    
    func testUpdateCropRangeInvalidEndTimeBeyondDuration() {
        // Given
        let track = TimelineTrack(trackInfo: mockVideoTrackInfo)
        let originalStartTime = track.cropStartTime
        let originalEndTime = track.cropEndTime
        
        let validStartTime = CMTime(seconds: 2.0, preferredTimescale: 600)
        let invalidEndTime = CMTime(seconds: 15.0, preferredTimescale: 600) // Beyond 10s duration
        
        // When
        track.updateCropRange(startTime: validStartTime, endTime: invalidEndTime)
        
        // Then - Should not update with end time beyond duration
        XCTAssertEqual(track.cropStartTime, originalStartTime)
        XCTAssertEqual(track.cropEndTime, originalEndTime)
    }
    
    func testMoveToPositionValid() {
        // Given
        let track = TimelineTrack(trackInfo: mockVideoTrackInfo)
        let newPosition = CMTime(seconds: 5.0, preferredTimescale: 600)
        
        // When
        track.moveToPosition(newPosition)
        
        // Then
        XCTAssertEqual(track.positionInTimeline, newPosition)
    }
    
    func testMoveToPositionInvalidNegative() {
        // Given
        let track = TimelineTrack(trackInfo: mockVideoTrackInfo)
        let originalPosition = track.positionInTimeline
        let invalidPosition = CMTime(seconds: -2.0, preferredTimescale: 600)
        
        // When
        track.moveToPosition(invalidPosition)
        
        // Then - Should not update with negative position
        XCTAssertEqual(track.positionInTimeline, originalPosition)
    }
    
    func testMoveToPositionInvalidTime() {
        // Given
        let track = TimelineTrack(trackInfo: mockVideoTrackInfo)
        let originalPosition = track.positionInTimeline
        
        // When
        track.moveToPosition(CMTime.invalid)
        
        // Then - Should not update with invalid time
        XCTAssertEqual(track.positionInTimeline, originalPosition)
    }
    
    // MARK: - Edge Cases Tests
    
    func testZeroDurationCrop() {
        // Given - Start and end time are the same
        let sameTime = CMTime(seconds: 5.0, preferredTimescale: 600)
        let track = TimelineTrack(
            trackInfo: mockVideoTrackInfo,
            cropStartTime: sameTime,
            cropEndTime: sameTime,
            positionInTimeline: CMTime.zero
        )
        
        // When & Then
        XCTAssertEqual(track.croppedDuration, CMTime.zero)
        XCTAssertFalse(track.isValid) // Zero duration should be invalid
    }
    
    func testFullDurationCrop() {
        // Given - Crop the entire duration
        let track = TimelineTrack(
            trackInfo: mockVideoTrackInfo,
            cropStartTime: CMTime.zero,
            cropEndTime: mockVideoTrackInfo.originalDuration,
            positionInTimeline: CMTime.zero
        )
        
        // When & Then
        XCTAssertEqual(track.croppedDuration, mockVideoTrackInfo.originalDuration)
        XCTAssertTrue(track.isValid)
    }
    
    func testVerySmallCropDuration() {
        // Given - Very small crop (1 frame at 30fps = ~0.033 seconds)
        let cropStartTime = CMTime(seconds: 5.0, preferredTimescale: 600)
        let cropEndTime = CMTime(seconds: 5.033, preferredTimescale: 600)
        let track = TimelineTrack(
            trackInfo: mockVideoTrackInfo,
            cropStartTime: cropStartTime,
            cropEndTime: cropEndTime,
            positionInTimeline: CMTime.zero
        )
        
        // When & Then
        XCTAssertEqual(track.croppedDuration.seconds, 0.033, accuracy: 0.001)
        XCTAssertTrue(track.isValid)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceCroppedDurationCalculation() {
        // Given
        let track = TimelineTrack(trackInfo: mockVideoTrackInfo)
        
        // When & Then
        self.measure {
            for _ in 0..<1000 {
                _ = track.croppedDuration
            }
        }
    }
    
    func testPerformanceEndTimeInTimelineCalculation() {
        // Given
        let track = TimelineTrack(trackInfo: mockVideoTrackInfo)
        
        // When & Then
        self.measure {
            for _ in 0..<1000 {
                _ = track.endTimeInTimeline
            }
        }
    }
    
    func testPerformanceIsValidCalculation() {
        // Given
        let track = TimelineTrack(trackInfo: mockVideoTrackInfo)
        
        // When & Then
        self.measure {
            for _ in 0..<1000 {
                _ = track.isValid
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testTrackUpdateSequence() {
        // Given
        let track = TimelineTrack(trackInfo: mockVideoTrackInfo)
        
        // When - Perform a sequence of operations
        track.moveToPosition(CMTime(seconds: 2.0, preferredTimescale: 600))
        track.updateCropRange(
            startTime: CMTime(seconds: 1.0, preferredTimescale: 600),
            endTime: CMTime(seconds: 8.0, preferredTimescale: 600)
        )
        track.moveToPosition(CMTime(seconds: 5.0, preferredTimescale: 600))
        
        // Then
        XCTAssertEqual(track.positionInTimeline.seconds, 5.0, accuracy: 0.01)
        XCTAssertEqual(track.cropStartTime.seconds, 1.0, accuracy: 0.01)
        XCTAssertEqual(track.cropEndTime.seconds, 8.0, accuracy: 0.01)
        XCTAssertEqual(track.croppedDuration.seconds, 7.0, accuracy: 0.01)
        XCTAssertEqual(track.endTimeInTimeline.seconds, 12.0, accuracy: 0.01) // 5 + 7
        XCTAssertTrue(track.isValid)
    }
}