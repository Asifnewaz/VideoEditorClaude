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
            setNeedsDisplay()
        }
    }
    
    var totalDuration: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var contentOffset: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var rulerHeight: CGFloat = 20
    var majorTickInterval: Int = 1 // Major tick every 1 second
    var minorTickInterval: CGFloat = 0.5 // Minor tick every 0.5 seconds
    
    // Colors
    var majorTickColor: UIColor = .white
    var minorTickColor: UIColor = UIColor.white.withAlphaComponent(0.6)
    var textColor: UIColor = .white
    var rulerBackgroundColor: UIColor = UIColor.black.withAlphaComponent(0.3)
    
    // Font
    var timeFont: UIFont = UIFont.systemFont(ofSize: 10, weight: .medium)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupRuler()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupRuler()
    }
    
    private func setupRuler() {
        self.backgroundColor = backgroundColor
        self.isUserInteractionEnabled = false
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Clear the context
        context.clear(rect)
        
        // Draw ruler background
        context.setFillColor(rulerBackgroundColor.cgColor)
        context.fill(rect)
        
        // Calculate visible time range based on content width
        let contentWidth = max(totalDuration * widthPerSecond, rect.width)
        
        drawRulerTicks(in: context, rect: rect, contentWidth: contentWidth)
        drawTimeLabels(in: context, rect: rect, contentWidth: contentWidth)
    }
    
    private func drawRulerTicks(in context: CGContext, rect: CGRect, contentWidth: CGFloat) {
        let maxSeconds = Int(ceil(totalDuration))
        
        // Draw major ticks (every second) - starting from content offset
        context.setStrokeColor(majorTickColor.cgColor)
        context.setLineWidth(1.0)
        
        for second in 0...maxSeconds {
            let x = contentOffset + (CGFloat(second) * widthPerSecond)
            if x >= contentOffset && x <= (contentOffset + contentWidth) {
                // Major tick - full height
                context.move(to: CGPoint(x: x, y: rect.height * 0.3))
                context.addLine(to: CGPoint(x: x, y: rect.height))
                context.strokePath()
            }
        }
        
        // Draw minor ticks (every 0.5 seconds) - starting from content offset
        context.setStrokeColor(minorTickColor.cgColor)
        context.setLineWidth(0.5)
        
        var currentTime: CGFloat = minorTickInterval
        while currentTime <= totalDuration {
            let x = contentOffset + (currentTime * widthPerSecond)
            
            // Skip if this would overlap with a major tick and ensure it's within bounds
            if fmod(currentTime, 1.0) != 0 && x >= contentOffset && x <= (contentOffset + contentWidth) {
                // Minor tick - half height
                context.move(to: CGPoint(x: x, y: rect.height * 0.6))
                context.addLine(to: CGPoint(x: x, y: rect.height))
                context.strokePath()
            }
            
            currentTime += minorTickInterval
        }
    }
    
    private func drawTimeLabels(in context: CGContext, rect: CGRect, contentWidth: CGFloat) {
        let maxSeconds = Int(ceil(totalDuration))
        
        // Text attributes
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: timeFont,
            .foregroundColor: textColor
        ]
        
        // Draw time labels at each second mark, starting from content offset
        for second in stride(from: 0, through: maxSeconds, by: majorTickInterval) {
            let x = contentOffset + (CGFloat(second) * widthPerSecond)
            
            if x >= contentOffset && x <= (contentOffset + contentWidth) {
                let timeString = formatTime(seconds: second)
                let attributedString = NSAttributedString(string: timeString, attributes: textAttributes)
                
                let textSize = attributedString.size()
                let textRect = CGRect(
                    x: x - textSize.width / 2,
                    y: 2,
                    width: textSize.width,
                    height: textSize.height
                )
                
                // Only draw if text fits within visible bounds
                if textRect.origin.x >= 0 && textRect.maxX <= rect.width {
                    attributedString.draw(in: textRect)
                }
            }
        }
        
        // Draw final duration at the end of content
        if totalDuration > 0 {
            let finalX = contentOffset + (totalDuration * widthPerSecond)
            if finalX >= contentOffset && finalX <= (contentOffset + contentWidth) {
                let finalTimeString = formatTime(seconds: Int(ceil(totalDuration)))
                let attributedString = NSAttributedString(string: finalTimeString, attributes: textAttributes)
                
                let textSize = attributedString.size()
                let textRect = CGRect(
                    x: finalX - textSize.width / 2,
                    y: 2,
                    width: textSize.width,
                    height: textSize.height
                )
                
                // Only draw if text fits within visible bounds
                if textRect.origin.x >= 0 && textRect.maxX <= rect.width {
                    attributedString.draw(in: textRect)
                }
            }
        }
    }
    
    private func formatTime(seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return String(format: "%d:%02d", minutes, remainingSeconds)
        }
    }
    
    // MARK: - Public Methods
    
    func updateDuration(_ duration: CGFloat) {
        totalDuration = duration
        setNeedsDisplay()
    }
    
    func updateWidthPerSecond(_ width: CGFloat) {
        widthPerSecond = width
        setNeedsDisplay()
    }
    
    func updateContentOffset(_ offset: CGFloat) {
        contentOffset = offset
        setNeedsDisplay()
    }
    
    func updateTheme(majorTick: UIColor = .white,
                    minorTick: UIColor? = nil,
                    text: UIColor = .white,
                    background: UIColor = UIColor.black.withAlphaComponent(0.3)) {
        majorTickColor = majorTick
        minorTickColor = minorTick ?? majorTick.withAlphaComponent(0.6)
        textColor = text
        rulerBackgroundColor = background
        setNeedsDisplay()
    }
}
