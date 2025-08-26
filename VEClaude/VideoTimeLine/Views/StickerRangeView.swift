//
//  StickerRangeView.swift
//  VEClaude
//
//  Created by Claude on 25/8/25.
//

import UIKit
import AVFoundation

class StickerRangeView: VideoRangeView {
    
    // StickerRangeView-specific properties
    private var stickerContentView: StickerContentView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStickerSpecificContent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupStickerSpecificContent()
    }
    
    private func setupStickerSpecificContent() {
        // Replace the default video content view with sticker content
        let stickerContent = StickerContentView()
        stickerContent.setupAsDefault()
        loadContentView(stickerContent)
        stickerContentView = stickerContent
    }
    
    
    
    func setupAsDefault() {
        stickerContentView.setupAsDefault()
    }
    
    override func reloadUI() {
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }
    
}

// MARK: - StickerContentView (similar to RangeContentView but for stickers)

class StickerContentView: RangeContentView {
    
    private var iconImageView: UIImageView!
    private var titleLabel: UILabel!
    private var containerView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStickerContent()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStickerContent()
    }
    
    private func setupStickerContent() {
        backgroundColor = .clear
        
        containerView = UIView()
        containerView.backgroundColor = .systemOrange.withAlphaComponent(0.7)
        containerView.layer.cornerRadius = 6
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemOrange.cgColor
        addSubview(containerView)
        
        iconImageView = UIImageView()
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .white
        containerView.addSubview(iconImageView)
        
        titleLabel = UILabel()
        titleLabel.text = "Sticker"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 10, weight: .medium)
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)
        
        setupStickerConstraints()
        
        // Set default values for RangeContentView
        startTime = CMTime.zero
        endTime = CMTime(seconds: 3.0, preferredTimescale: 600)
        widthPerSecond = 60
    }
    
    private func setupStickerConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2)
        ])
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -6),
            iconImageView.widthAnchor.constraint(equalToConstant: 18),
            iconImageView.heightAnchor.constraint(equalToConstant: 18)
        ])
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -4)
        ])
    }
    
    func setupAsDefault() {
        if let stickerImage = UIImage(systemName: "star.fill") {
            iconImageView.image = stickerImage
        }
        titleLabel.text = "Sticker"
    }
    
    override var contentWidth: CGFloat {
        return CGFloat((endTime - startTime).seconds) * widthPerSecond
    }
    
    // Override expand method to respect timeline constraints
    override func expand(contentWidth: CGFloat, left: Bool) {
        // Get the timeline view for duration constraints
        var parentTimelineView: TimeLineView?
        var currentView = superview
        while currentView != nil {
            if let timelineView = currentView as? TimeLineView {
                parentTimelineView = timelineView
                break
            }
            currentView = currentView?.superview
        }
        
        guard let timelineView = parentTimelineView else {
            // Fallback to default behavior if we can't find timeline
            super.expand(contentWidth: contentWidth, left: left)
            return
        }
        
        // If max expand is disabled, check against video duration constraints
        // Note: maxExpandEnabled property removed, defaulting to constrained behavior
        if true { // Always constrain to video duration
            // Calculate video timeline duration for constraint checking
            var videoTimelineDuration: CGFloat = 0
            timelineView.rangeViews.enumerated().forEach { (index, view) in
                let contentWidth = view.contentView.contentWidth
                let contentDuration = contentWidth / timelineView.widthPerSecond
                videoTimelineDuration += contentDuration
            }
            
            // Fallback to trackItems if no rangeViews
            if videoTimelineDuration == 0 {
                timelineView.trackItems.forEach { trackItem in
                    videoTimelineDuration += CGFloat(trackItem.duration.seconds)
                }
            }
            
            // Calculate new proposed end time
            let currentDuration = CGFloat((endTime - startTime).seconds)
            let proposedChange = contentWidth / widthPerSecond
            let newDuration = currentDuration + proposedChange
            let startTimeSeconds = CGFloat(startTime.seconds)
            let proposedEndTime = startTimeSeconds + newDuration
            
            // Constrain to video timeline duration if expanding beyond it
            if proposedEndTime > videoTimelineDuration {
                let maxAllowedDuration = videoTimelineDuration - startTimeSeconds
                let constrainedWidth = maxAllowedDuration * widthPerSecond - currentDuration * widthPerSecond
                super.expand(contentWidth: constrainedWidth, left: left)
                return
            }
        }
        
        // If max expand enabled or within bounds, use default behavior
        super.expand(contentWidth: contentWidth, left: left)
    }
}
