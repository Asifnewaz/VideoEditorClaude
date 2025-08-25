//
//  CMTimeExtensionTests.swift
//  VEClaudeTests
//
//  Created by BCL Device 24 on 25/8/25.
//

import XCTest
import AVFoundation
@testable import VEClaude

final class CMTimeExtensionTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testInitWithValueAndIntTimescale() {
        // When
        let time = CMTime(value: 1200, 600)
        
        // Then
        XCTAssertEqual(time.value, 1200)
        XCTAssertEqual(time.timescale, 600)
        XCTAssertEqual(time.safeSeconds, 2.0, accuracy: 0.001)
    }
    
    func testInitWithValueAndInt32Timescale() {
        // When
        let time = CMTime(value: 1800, Int32(600))
        
        // Then
        XCTAssertEqual(time.value, 1800)
        XCTAssertEqual(time.timescale, 600)
        XCTAssertEqual(time.safeSeconds, 3.0, accuracy: 0.001)
    }
    
    func testInitWithFloat64Seconds() {
        // When
        let time = CMTime(seconds: 5.5, preferredTimeScale: 600)
        
        // Then
        XCTAssertEqual(time.safeSeconds, 5.5, accuracy: 0.001)
        XCTAssertEqual(time.timescale, 600)
    }
    
    func testInitWithFloatSeconds() {
        // When
        let time = CMTime(seconds: Float(2.5), preferredTimeScale: 600)
        
        // Then
        XCTAssertEqual(time.safeSeconds, 2.5, accuracy: 0.001)
        XCTAssertEqual(time.timescale, 600)
    }
    
    func testInitWithDefaultTimescale() {
        // When
        let time = CMTime(seconds: 1.0)
        
        // Then
        XCTAssertEqual(time.safeSeconds, 1.0, accuracy: 0.001)
        XCTAssertEqual(time.timescale, 600) // Default timescale
    }
    
    // MARK: - cb_time Method Tests
    
    func testCbTimeConversion() {
        // Given
        let originalTime = CMTime(seconds: 3.0, preferredTimescale: 1000)
        
        // When
        let convertedTime = originalTime.cb_time(preferredTimeScale: 600)
        
        // Then
        XCTAssertEqual(convertedTime.safeSeconds, originalTime.safeSeconds, accuracy: 0.001)
        XCTAssertEqual(convertedTime.timescale, 600)
    }
    
    func testCbTimeWithDefaultTimescale() {
        // Given
        let originalTime = CMTime(seconds: 2.5, preferredTimescale: 1000)
        
        // When
        let convertedTime = originalTime.cb_time()
        
        // Then
        XCTAssertEqual(convertedTime.safeSeconds, originalTime.safeSeconds, accuracy: 0.001)
        XCTAssertEqual(convertedTime.timescale, 600)
    }
    
    // MARK: - Addition Tests
    
    func testAdditionAssignmentOperator() {
        // Given
        var time1 = CMTime(seconds: 2.0)
        let time2 = CMTime(seconds: 3.0)
        
        // When
        let result = time1 += time2
        
        // Then
        XCTAssertEqual(time1.safeSeconds, 5.0, accuracy: 0.001)
        XCTAssertEqual(result.safeSeconds, 5.0, accuracy: 0.001)
    }
    
    // MARK: - Subtraction Tests
    
    func testSubtractionAssignmentOperator() {
        // Given
        var time1 = CMTime(seconds: 5.0)
        let time2 = CMTime(seconds: 2.0)
        
        // When
        let result = time1 -= time2
        
        // Then
        XCTAssertEqual(time1.safeSeconds, 3.0, accuracy: 0.001)
        XCTAssertEqual(result.safeSeconds, 3.0, accuracy: 0.001)
    }
    
    // MARK: - Multiplication Tests
    
    func testMultiplicationByInt32() {
        // Given
        let time = CMTime(seconds: 2.5)
        let multiplier: Int32 = 3
        
        // When
        let result = time * multiplier
        
        // Then
        XCTAssertEqual(result.safeSeconds, 7.5, accuracy: 0.001)
    }
    
    func testMultiplicationByInt32Commutative() {
        // Given
        let time = CMTime(seconds: 2.0)
        let multiplier: Int32 = 4
        
        // When
        let result1 = time * multiplier
        let result2 = multiplier * time
        
        // Then
        XCTAssertEqual(result1.safeSeconds, result2.safeSeconds, accuracy: 0.001)
        XCTAssertEqual(result1.safeSeconds, 8.0, accuracy: 0.001)
    }
    
    func testMultiplicationByFloat64() {
        // Given
        let time = CMTime(seconds: 3.0)
        let multiplier: Float64 = 2.5
        
        // When
        let result = time * multiplier
        
        // Then
        XCTAssertEqual(result.safeSeconds, 7.5, accuracy: 0.001)
    }
    
    func testMultiplicationByFloat() {
        // Given
        let time = CMTime(seconds: 4.0)
        let multiplier: Float = 1.5
        
        // When
        let result = time * multiplier
        
        // Then
        XCTAssertEqual(result.safeSeconds, 6.0, accuracy: 0.001)
    }
    
    func testMultiplicationAssignmentInt32() {
        // Given
        var time = CMTime(seconds: 2.0)
        let multiplier: Int32 = 3
        
        // When
        let result = time *= multiplier
        
        // Then
        XCTAssertEqual(time.safeSeconds, 6.0, accuracy: 0.001)
        XCTAssertEqual(result.safeSeconds, 6.0, accuracy: 0.001)
    }
    
    func testMultiplicationAssignmentFloat64() {
        // Given
        var time = CMTime(seconds: 2.0)
        let multiplier: Float64 = 2.5
        
        // When
        let result = time *= multiplier
        
        // Then
        XCTAssertEqual(time.safeSeconds, 5.0, accuracy: 0.001)
        XCTAssertEqual(result.safeSeconds, 5.0, accuracy: 0.001)
    }
    
    func testMultiplicationAssignmentFloat() {
        // Given
        var time = CMTime(seconds: 3.0)
        let multiplier: Float = 2.0
        
        // When
        let result = time *= multiplier
        
        // Then
        XCTAssertEqual(time.safeSeconds, 6.0, accuracy: 0.001)
        XCTAssertEqual(result.safeSeconds, 6.0, accuracy: 0.001)
    }
    
    // MARK: - Division Tests
    
    func testDivisionByInt32() {
        // Given
        let time = CMTime(seconds: 6.0)
        let divisor: Int32 = 2
        
        // When
        let result = time / divisor
        
        // Then
        XCTAssertEqual(result.safeSeconds, 3.0, accuracy: 0.001)
    }
    
    func testDivisionAssignment() {
        // Given
        var time = CMTime(seconds: 9.0)
        let divisor: Int32 = 3
        
        // When
        let result = time /= divisor
        
        // Then
        XCTAssertEqual(time.safeSeconds, 3.0, accuracy: 0.001)
        XCTAssertEqual(result.safeSeconds, 3.0, accuracy: 0.001)
    }
    
    // MARK: - Conversion Properties Tests
    
    func testFloatProperty() {
        // Given
        let time = CMTime(seconds: 2.5)
        
        // When
        let floatValue = time.f
        
        // Then
        XCTAssertEqual(floatValue, 2.5, accuracy: 0.001)
    }
    
    func testFloat64Property() {
        // Given
        let time = CMTime(seconds: 3.75)
        
        // When
        let doubleValue = time.f64
        
        // Then
        XCTAssertEqual(doubleValue, 3.75, accuracy: 0.001)
    }
    
    // MARK: - Equality Comparison Tests
    
    func testEqualityWithFloat64() {
        // Given
        let time = CMTime(seconds: 2.5)
        let seconds: Float64 = 2.5
        
        // When & Then
        XCTAssertTrue(time == seconds)
        XCTAssertTrue(seconds == time)
    }
    
    func testEqualityWithFloat() {
        // Given
        let time = CMTime(seconds: 3.0)
        let seconds: Float = 3.0
        
        // When & Then
        XCTAssertTrue(time == seconds)
        XCTAssertTrue(seconds == time)
    }
    
    func testInequalityWithFloat64() {
        // Given
        let time = CMTime(seconds: 2.5)
        let seconds: Float64 = 3.0
        
        // When & Then
        XCTAssertTrue(time != seconds)
        XCTAssertTrue(seconds != time)
    }
    
    func testInequalityWithFloat() {
        // Given
        let time = CMTime(seconds: 2.0)
        let seconds: Float = 3.0
        
        // When & Then
        XCTAssertTrue(time != seconds)
        XCTAssertTrue(seconds != time)
    }
    
    // MARK: - Less Than Comparison Tests
    
    func testLessThanWithFloat64() {
        // Given
        let time = CMTime(seconds: 2.0)
        let seconds: Float64 = 3.0
        
        // When & Then
        XCTAssertTrue(time < seconds)
        XCTAssertFalse(seconds < time)
    }
    
    func testLessThanWithFloat() {
        // Given
        let time = CMTime(seconds: 1.5)
        let seconds: Float = 2.0
        
        // When & Then
        XCTAssertTrue(time < seconds)
        XCTAssertFalse(seconds < time)
    }
    
    func testLessThanOrEqualWithFloat64() {
        // Given
        let time1 = CMTime(seconds: 2.0)
        let time2 = CMTime(seconds: 3.0)
        let seconds: Float64 = 2.0
        let greaterSeconds: Float64 = 3.0
        
        // When & Then
        XCTAssertTrue(time1 <= seconds) // Equal case
        XCTAssertTrue(time1 <= greaterSeconds) // Less than case
        XCTAssertFalse(time2 <= seconds) // Greater than case
    }
    
    func testLessThanOrEqualWithFloat() {
        // Given
        let time1 = CMTime(seconds: 1.5)
        let time2 = CMTime(seconds: 2.5)
        let seconds: Float = 1.5
        let greaterSeconds: Float = 2.0
        
        // When & Then
        XCTAssertTrue(time1 <= seconds) // Equal case
        XCTAssertTrue(time1 <= greaterSeconds) // Less than case
        XCTAssertFalse(time2 <= seconds) // Greater than case
    }
    
    // MARK: - Greater Than Comparison Tests
    
    func testGreaterThanWithFloat64() {
        // Given
        let time = CMTime(seconds: 3.0)
        let seconds: Float64 = 2.0
        
        // When & Then
        XCTAssertTrue(time > seconds)
        XCTAssertFalse(seconds > time)
    }
    
    func testGreaterThanWithFloat() {
        // Given
        let time = CMTime(seconds: 2.5)
        let seconds: Float = 1.5
        
        // When & Then
        XCTAssertTrue(time > seconds)
        XCTAssertFalse(seconds > time)
    }
    
    func testGreaterThanOrEqualWithFloat64() {
        // Given
        let time1 = CMTime(seconds: 3.0)
        let time2 = CMTime(seconds: 2.0)
        let seconds: Float64 = 3.0
        let lesserSeconds: Float64 = 2.0
        
        // When & Then
        XCTAssertTrue(time1 >= seconds) // Equal case
        XCTAssertTrue(time1 >= lesserSeconds) // Greater than case
        XCTAssertFalse(time2 >= seconds) // Less than case
    }
    
    func testGreaterThanOrEqualWithFloat() {
        // Given
        let time1 = CMTime(seconds: 2.0)
        let time2 = CMTime(seconds: 1.0)
        let seconds: Float = 2.0
        let lesserSeconds: Float = 1.5
        
        // When & Then
        XCTAssertTrue(time1 >= seconds) // Equal case
        XCTAssertTrue(time1 >= lesserSeconds) // Greater than case
        XCTAssertFalse(time2 >= seconds) // Less than case
    }
    
    // MARK: - Edge Cases Tests
    
    func testZeroTime() {
        // Given
        let time = CMTime.zero
        
        // When & Then
        XCTAssertEqual(time.f, 0.0, accuracy: 0.001)
        XCTAssertEqual(time.f64, 0.0, accuracy: 0.001)
        XCTAssertTrue(time == 0.0)
        XCTAssertTrue(time <= 0.0)
        XCTAssertTrue(time >= 0.0)
    }
    
    func testInvalidTime() {
        // Given
        let time = CMTime.invalid
        
        // When & Then
        XCTAssertTrue(time.f.isNaN || time.f.isInfinite)
        XCTAssertTrue(time.f64.isNaN || time.f64.isInfinite)
    }
    
    func testIndefiniteTime() {
        // Given
        let time = CMTime.indefinite
        
        // When & Then
        XCTAssertTrue(time.f.isInfinite)
        XCTAssertTrue(time.f64.isInfinite)
    }
    
    func testNegativeTime() {
        // Given
        let time = CMTime(seconds: -2.5)
        
        // When & Then
        XCTAssertEqual(time.f, -2.5, accuracy: 0.001)
        XCTAssertEqual(time.f64, -2.5, accuracy: 0.001)
        XCTAssertTrue(time < 0.0)
        XCTAssertTrue(time != 0.0)
    }
    
    func testVerySmallTime() {
        // Given
        let time = CMTime(seconds: 0.001)
        
        // When & Then
        XCTAssertEqual(time.f, 0.001, accuracy: 0.0001)
        XCTAssertEqual(time.f64, 0.001, accuracy: 0.0001)
        XCTAssertTrue(time > 0.0)
        XCTAssertTrue(time < 1.0)
    }
    
    func testVeryLargeTime() {
        // Given
        let time = CMTime(seconds: 1000000.0)
        
        // When & Then
        XCTAssertEqual(time.f, 1000000.0, accuracy: 1.0)
        XCTAssertEqual(time.f64, 1000000.0, accuracy: 1.0)
        XCTAssertTrue(time > 999999.0)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceArithmeticOperations() {
        // Given
        let time1 = CMTime(seconds: 2.0)
        let time2 = CMTime(seconds: 3.0)
        let multiplier: Int32 = 2
        
        // When & Then
        self.measure {
            var result = time1
            for _ in 0..<1000 {
                result += time2
                result *= multiplier
                result /= multiplier
                result -= time2
            }
        }
    }
    
    func testPerformanceComparisonOperations() {
        // Given
        let time = CMTime(seconds: 2.5)
        let seconds: Float64 = 2.0
        
        // When & Then
        self.measure {
            for _ in 0..<1000 {
                _ = time > seconds
                _ = time < seconds
                _ = time == seconds
                _ = time >= seconds
                _ = time <= seconds
            }
        }
    }
    
    func testPerformanceConversionOperations() {
        // Given
        let time = CMTime(seconds: 123.456)
        
        // When & Then
        self.measure {
            for _ in 0..<1000 {
                _ = time.f
                _ = time.f64
                _ = time.cb_time()
            }
        }
    }
}