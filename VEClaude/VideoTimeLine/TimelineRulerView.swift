//
//  TimelineRulerView.swift
//  VEClaude
//
//  Created by BCL Device 24 on 24/8/25.
//

import UIKit
import AVFoundation

class TimelineRulerView: UIView {
    
    // MARK: - Properties
    var widthPerSecond: CGFloat = 60 {
        didSet {
            updateTimeLabels()
        }
    }
    
    var totalDuration: CGFloat = 0 {
        didSet {
            updateTimeLabels()
        }
    }
    
    private var timeLabels: [UILabel] = []
    
    var contentStartOffset: CGFloat = 24 {
        didSet {
            updateTimeLabels()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupRuler()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupRuler()
    }
    
    private func setupRuler() {
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = false
        
        // Force create a test label to see if basic functionality works
        createTestLabel()
        
        // Test with a fixed duration to verify updateTimeLabels works
        print("🔴 Testing with fixed duration of 5.0 seconds")
        totalDuration = 5.0
        updateTimeLabels()
    }
    
    private func createTestLabel() {
        let testLabel = UILabel()
        testLabel.text = "TEST"
        testLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .medium)
        testLabel.textColor = .red
        testLabel.backgroundColor = UIColor.yellow.withAlphaComponent(0.8)
        testLabel.textAlignment = .center
        testLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(testLabel)
        
        NSLayoutConstraint.activate([
            testLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            testLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            testLabel.widthAnchor.constraint(equalToConstant: 40),
            testLabel.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        print("🔴 Created test label at position 10")
    }
    
    private func updateTimeLabels() {
        // Remove all existing time labels
        clearTimeLabels()
        
        guard totalDuration > 0 else { 
            print("No duration set for ruler view")
            return 
        }
        
        print("Updating time labels for duration: \(totalDuration)")
        
        let numberOfLabels = Int(ceil(totalDuration)) + 1 // Include 0 and final duration
        
        for i in 0..<numberOfLabels {
            let timeValue = Double(i)
            if timeValue <= Double(totalDuration) {
                addTimeLabel(timeValue: timeValue, position: i)
            }
        }
        
        // Add final duration label if it's not a whole number
        if totalDuration != floor(totalDuration) {
            addTimeLabel(timeValue: Double(totalDuration), position: Int(totalDuration), isFinal: true)
        }
        
        print("Added \(timeLabels.count) time labels")
    }
    
    private func addTimeLabel(timeValue: Double, position: Int, isFinal: Bool = false) {
        let timeLabel = UILabel()
        timeLabel.text = String(format: "%.1f", timeValue)
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .medium)
        timeLabel.textColor = .black
        timeLabel.backgroundColor = UIColor.white.withAlphaComponent(0.8) // Add background for visibility
        timeLabel.textAlignment = .center
        timeLabel.layer.cornerRadius = 2
        timeLabel.clipsToBounds = true
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(timeLabel)
        timeLabels.append(timeLabel)
        
        // Position the time label starting from content offset (thumbnail position)
        let xPosition: CGFloat
        if isFinal {
            xPosition = contentStartOffset + (totalDuration * widthPerSecond)
        } else {
            xPosition = contentStartOffset + (CGFloat(position) * widthPerSecond)
        }
        
        NSLayoutConstraint.activate([
            timeLabel.centerXAnchor.constraint(equalTo: leadingAnchor, constant: xPosition),
            timeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            timeLabel.widthAnchor.constraint(equalToConstant: 30),
            timeLabel.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        print("Added time label \(timeValue) at x position: \(xPosition)")
    }
    
    private func clearTimeLabels() {
        timeLabels.forEach { $0.removeFromSuperview() }
        timeLabels.removeAll()
    }
    
    // MARK: - Public Methods
    
    func updateDuration(_ duration: CGFloat) {
        print("🔵 TimelineRulerView.updateDuration called with: \(duration)")
        totalDuration = duration
        print("🔵 TimelineRulerView.updateDuration set totalDuration to: \(totalDuration)")
        
        // Force call updateTimeLabels to ensure it's executed
        print("🔵 Manually calling updateTimeLabels from updateDuration")
        updateTimeLabels()
    }
    
    func updateWidthPerSecond(_ width: CGFloat) {
        print("🔵 TimelineRulerView.updateWidthPerSecond called with: \(width)")
        widthPerSecond = width
        
        // Force call updateTimeLabels to ensure it's executed
        print("🔵 Manually calling updateTimeLabels from updateWidthPerSecond")
        updateTimeLabels()
    }
    
    func forceRefresh() {
        print("🔵 forceRefresh called - duration: \(totalDuration), width: \(widthPerSecond)")
        updateTimeLabels()
    }
    
    func updateContentOffset(_ offset: CGFloat) {
        print("🔵 TimelineRulerView.updateContentOffset called with: \(offset)")
        contentStartOffset = offset
    }
    
    func updateTheme(majorTick: UIColor = .white,
                    minorTick: UIColor? = nil,
                    text: UIColor = .black,
                    background: UIColor = UIColor.black.withAlphaComponent(0.3)) {
        // Update text color for all labels
        timeLabels.forEach { $0.textColor = text }
        self.backgroundColor = background
    }
}