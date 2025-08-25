//
//  VEClaudeTests.swift
//  VEClaudeTests
//
//  Created by BCL Device 24 on 21/8/25.
//

import XCTest
import AVFoundation
@testable import VEClaude

final class VEClaudeTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: - Basic App Tests

    func testAppLaunch() throws {
        // Test that the app can launch without crashing
        let viewController = ViewController()
        viewController.loadViewIfNeeded()
        
        XCTAssertNotNil(viewController.view)
        XCTAssertNotNil(viewController.getCurrentTimelineData())
    }
    
    func testTimelineDataModelIntegration() throws {
        // Test the integration between major components
        let viewController = ViewController()
        let timelineDataModel = TimelineDataModel()
        
        // Create a mock asset
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let videoURL = URL(fileURLWithPath: documentsPath).appendingPathComponent("test.mp4")
        let mockAsset = AVAsset(url: videoURL)
        
        // Test that components work together
        timelineDataModel.addTrack(from: mockAsset, at: CMTime.zero)
        
        XCTAssertEqual(timelineDataModel.trackCount, 1)
        XCTAssertFalse(timelineDataModel.isEmpty)
        XCTAssertGreaterThan(timelineDataModel.totalDuration, CMTime.zero)
    }
    
    func testRangeContentViewBasicFunctionality() throws {
        // Test basic range content view functionality
        let rangeView = RangeContentView(frame: CGRect(x: 0, y: 0, width: 300, height: 44))
        
        XCTAssertEqual(rangeView.startTime, CMTime.zero)
        XCTAssertEqual(rangeView.endTime, CMTime.zero)
        XCTAssertEqual(rangeView.widthPerSecond, 10)
        XCTAssertTrue(rangeView.clipsToBounds)
    }
    
    func testCMTimeExtensionBasicOperations() throws {
        // Test basic CMTime extension functionality
        let time1 = CMTime(seconds: 2.0)
        let time2 = CMTime(seconds: 3.0)
        
        XCTAssertEqual(time1.seconds, 2.0, accuracy: 0.001)
        XCTAssertEqual(time2.seconds, 3.0, accuracy: 0.001)
        
        // Test arithmetic
        var result = time1
        result += time2
        XCTAssertEqual(result.seconds, 5.0, accuracy: 0.001)
        
        // Test comparisons
        XCTAssertTrue(time1 < time2)
        XCTAssertTrue(time1 == 2.0)
        XCTAssertTrue(time2 > 2.5)
    }

    // MARK: - Performance Tests

    func testPerformanceTimelineOperations() throws {
        // This is a performance test for timeline operations
        let timelineDataModel = TimelineDataModel()
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let videoURL = URL(fileURLWithPath: documentsPath).appendingPathComponent("test.mp4")
        let mockAsset = AVAsset(url: videoURL)
        
        self.measure {
            // Add tracks
            for i in 0..<10 {
                let position = CMTime(seconds: Double(i), preferredTimescale: 600)
                timelineDataModel.addTrack(from: mockAsset, at: position)
            }
            
            // Query operations
            _ = timelineDataModel.totalDuration
            _ = timelineDataModel.trackCount
            
            // Clean up
            timelineDataModel.clearAllTracks()
        }
    }
    
    func testPerformanceRangeContentViewCalculations() throws {
        let rangeView = RangeContentView(frame: CGRect(x: 0, y: 0, width: 300, height: 44))
        rangeView.startTime = CMTime.zero
        rangeView.endTime = CMTime(seconds: 100.0, preferredTimescale: 600)
        rangeView.widthPerSecond = 10
        
        self.measure {
            for _ in 0..<100 {
                _ = rangeView.contentWidth
                _ = rangeView.reachEnd()
                _ = rangeView.reachHead()
            }
        }
    }

}
