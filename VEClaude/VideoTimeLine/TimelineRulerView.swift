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
    }
    
    private func updateTimeLabels() {
        // Remove all existing time labels
        clearTimeLabels()
        
        guard totalDuration > 0 else { return }
        
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
    }
    
    private func addTimeLabel(timeValue: Double, position: Int, isFinal: Bool = false) {
        let timeLabel = UILabel()
        timeLabel.text = String(format: "%.1f", timeValue)
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .medium)
        timeLabel.textColor = .black
        timeLabel.textAlignment = .center
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(timeLabel)
        timeLabels.append(timeLabel)
        
        // Position the time label
        let xPosition: CGFloat
        if isFinal {
            xPosition = totalDuration * widthPerSecond
        } else {
            xPosition = CGFloat(position) * widthPerSecond
        }
        
        NSLayoutConstraint.activate([
            timeLabel.centerXAnchor.constraint(equalTo: leadingAnchor, constant: xPosition),
            timeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            timeLabel.widthAnchor.constraint(equalToConstant: 30)
        ])
        
        print("Added time label \(timeValue) at x position: \(xPosition)")
    }
    
    private func clearTimeLabels() {
        timeLabels.forEach { $0.removeFromSuperview() }
        timeLabels.removeAll()
    }
    
    // MARK: - Public Methods
    
    func updateDuration(_ duration: CGFloat) {
        totalDuration = duration
    }
    
    func updateWidthPerSecond(_ width: CGFloat) {
        widthPerSecond = width
    }
    
    func updateContentOffset(_ offset: CGFloat) {
        // Not needed in simple label approach
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