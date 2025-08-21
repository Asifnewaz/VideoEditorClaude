//
//  VideoTimelineView.swift
//  VEClaude
//
//  Created by BCL Device 24 on 21/8/25.
//

import UIKit
import AVFoundation

protocol VideoTimelineViewDelegate: AnyObject {
    func videoTimelineView(_ timelineView: VideoTimelineView, didSelectVideoAt index: Int)
}

class VideoTimelineView: UIView {
    
    // MARK: - Properties
    private var scrollView: UIScrollView!
    private var timeContainer: UIView!
    private var timeStackView: UIStackView!
    private var stackView: UIStackView!
    private var selectionOverlay: UIView!
    private var leftEar: UIView!
    private var rightEar: UIView!
    private var videos: [VideoSegment] = []
    private var selectedVideoIndex: Int? {
        didSet {
            updateSelectionVisual()
        }
    }
    
    weak var delegate: VideoTimelineViewDelegate?
    
    var timelineHeight: CGFloat = 100 {
        didSet {
            updateHeight()
        }
    }
    
    var thumbnailTimeInterval: Double = 1.0 {
        didSet {
            reloadAllVideos()
        }
    }
    
    // MARK: - Video Segment Structure
    private class VideoSegment {
        let url: URL
        var thumbnailViews: [UIImageView] = []
        var startIndex: Int = 0
        var endIndex: Int = 0
        var isSelected: Bool = false
        
        init(url: URL) {
            self.url = url
        }
    }
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .systemGray6
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray4.cgColor
        
        scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        
        // Time container (above thumbnails)
        timeContainer = UIView()
        timeContainer.backgroundColor = .clear
        timeContainer.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(timeContainer)
        
        // Time labels will be positioned absolutely within timeContainer
        // No need for stack view since we're positioning at specific locations
        
        // Thumbnail stack view (below time container)
        stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 0
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        
        // Selection overlay
        selectionOverlay = UIView()
        selectionOverlay.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
        selectionOverlay.layer.borderColor = UIColor.systemBlue.cgColor
        selectionOverlay.layer.borderWidth = 2
        selectionOverlay.layer.cornerRadius = 0
        selectionOverlay.isHidden = true
        selectionOverlay.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(selectionOverlay)
        
        // Left ear handle
        leftEar = UIView()
        leftEar.backgroundColor = UIColor.systemBlue
        leftEar.layer.cornerRadius = 4
        leftEar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner] // Left top and bottom corners only
        leftEar.isHidden = true
        leftEar.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(leftEar)
        
        // Right ear handle
        rightEar = UIView()
        rightEar.backgroundColor = UIColor.systemBlue
        rightEar.layer.cornerRadius = 4
        rightEar.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner] // Right top and bottom corners only
        rightEar.isHidden = true
        rightEar.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(rightEar)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            
            // Time container constraints (top area)
            timeContainer.topAnchor.constraint(equalTo: scrollView.topAnchor),
            timeContainer.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            timeContainer.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            timeContainer.heightAnchor.constraint(equalToConstant: 20),
            
            
            // Thumbnail stack view constraints (below time container)
            stackView.topAnchor.constraint(equalTo: timeContainer.bottomAnchor, constant: 2),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor, constant: -22)
        ])
    }
    
    private func updateHeight() {
        if let heightConstraint = constraints.first(where: { $0.firstAttribute == .height }) {
            heightConstraint.constant = timelineHeight
        } else {
            heightAnchor.constraint(equalToConstant: timelineHeight).isActive = true
        }
    }
    
    // MARK: - Public Methods
    func addVideo(from url: URL) {
        let videoSegment = VideoSegment(url: url)
        
        // Calculate start index for this video (after all existing thumbnails)
        let currentThumbnailCount = stackView.arrangedSubviews.count
        videoSegment.startIndex = currentThumbnailCount
        
        videos.append(videoSegment)
        generateThumbnails(for: videos.count - 1)
    }
    
    func clearAllVideos() {
        videos.removeAll()
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        timeContainer.subviews.forEach { $0.removeFromSuperview() }
        selectedVideoIndex = nil
    }
    
    private func reloadAllVideos() {
        for (index, _) in videos.enumerated() {
            generateThumbnails(for: index)
        }
    }
    
    @objc private func thumbnailTapped(_ gesture: UITapGestureRecognizer) {
        guard let tappedImageView = gesture.view as? UIImageView else { 
            print("Tap gesture view is not UIImageView")
            return 
        }
        
        print("Thumbnail tapped, current selectedVideoIndex: \(selectedVideoIndex?.description ?? "nil")")
        
        // Find which video this thumbnail belongs to
        for (videoIndex, video) in videos.enumerated() {
            if video.thumbnailViews.contains(tappedImageView) {
                print("Found tapped thumbnail belongs to video at index: \(videoIndex)")
                
                // Toggle selection: if already selected, deselect; otherwise select
                if selectedVideoIndex == videoIndex {
                    // Deselect the video
                    print("Video \(videoIndex) is already selected, deselecting...")
                    selectedVideoIndex = nil
                    print("Deselected video at index: \(videoIndex), selectedVideoIndex is now: \(selectedVideoIndex?.description ?? "nil")")
                } else {
                    // Select the video
                    print("Selecting video at index: \(videoIndex)")
                    selectedVideoIndex = videoIndex
                    delegate?.videoTimelineView(self, didSelectVideoAt: videoIndex)
                    print("Selected video at index: \(videoIndex)")
                }
                break
            }
        }
    }
    
    private func updateSelectionVisual() {
        print("updateSelectionVisual called with selectedVideoIndex: \(selectedVideoIndex?.description ?? "nil")")
        
        guard let selectedIndex = selectedVideoIndex,
              selectedIndex < videos.count else {
            print("Hiding selection overlay and ears")
            selectionOverlay.isHidden = true
            leftEar.isHidden = true
            rightEar.isHidden = true
            return
        }
        
        let selectedVideo = videos[selectedIndex]
        
        // Calculate the rect for the entire selected video
        if !selectedVideo.thumbnailViews.isEmpty {
            // Force layout update
            stackView.layoutIfNeeded()
            
            let firstThumbnail = selectedVideo.thumbnailViews.first!
            let lastThumbnail = selectedVideo.thumbnailViews.last!
            
            // Calculate total width: number of thumbnails × 60px each
            let thumbnailCount = selectedVideo.thumbnailViews.count
            let totalWidth = CGFloat(thumbnailCount * 60)
            
            // Get start position from first thumbnail
            let startX = CGFloat(selectedVideo.startIndex * 60)
            let endX = startX + totalWidth
            
            // Update overlay frame (position relative to thumbnail stack view)
            selectionOverlay.frame = CGRect(
                x: startX,
                y: 22, // Position below time container (20px height + 2px spacing)
                width: totalWidth,
                height: stackView.frame.height
            )
            
            // Position left ear (20px wide, attached to left side of video)
            leftEar.frame = CGRect(
                x: startX - 20, // Position 20px to the left of video start
                y: 22, // Same y position as selection overlay
                width: 20,
                height: stackView.frame.height
            )
            
            // Position right ear (20px wide, attached to right side of video)
            rightEar.frame = CGRect(
                x: endX, // Position right after video end
                y: 22, // Same y position as selection overlay
                width: 20,
                height: stackView.frame.height
            )
            
            selectionOverlay.isHidden = false
            leftEar.isHidden = false
            rightEar.isHidden = false
            
            print("Selection overlay: x=\(startX), width=\(totalWidth), thumbnails=\(thumbnailCount)")
            print("Left ear at x=\(startX - 20), Right ear at x=\(endX)")
        } else {
            selectionOverlay.isHidden = true
            leftEar.isHidden = true
            rightEar.isHidden = true
        }
    }
    
    // MARK: - Thumbnail Generation
    private func generateThumbnails(for videoIndex: Int) {
        guard videoIndex < videos.count else { return }
        
        let video = videos[videoIndex]
        let asset = AVAsset(url: video.url)
        let duration = asset.duration
        let durationInSeconds = CMTimeGetSeconds(duration)
        
        guard durationInSeconds > 0 else { return }
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceAfter = .zero
        imageGenerator.requestedTimeToleranceBefore = .zero
        
        let thumbnailWidth: CGFloat = 60 // Fixed width of 60px
        let thumbnailHeight: CGFloat = 60 // Fixed height of 60px
        imageGenerator.maximumSize = CGSize(width: thumbnailWidth * 2, height: thumbnailHeight * 2)
        
        // Calculate exact number of thumbnails based on duration and interval
        let numberOfThumbnails = Int(ceil(durationInSeconds / thumbnailTimeInterval))
        
        var times: [NSValue] = []
        for i in 0..<numberOfThumbnails {
            let timeInSeconds = Double(i) * thumbnailTimeInterval
            // Ensure we don't exceed video duration
            let clampedTime = min(timeInSeconds, durationInSeconds - 0.1)
            let time = CMTime(seconds: clampedTime, preferredTimescale: 600)
            times.append(NSValue(time: time))
        }
        
        print("Generating \(numberOfThumbnails) thumbnails for video \(videoIndex + 1), duration: \(durationInSeconds)")
        
        // Update end index for this video
        video.endIndex = video.startIndex + numberOfThumbnails - 1
        
        imageGenerator.generateCGImagesAsynchronously(forTimes: times) { [weak self] (requestedTime, cgImage, actualTime, result, error) in
            DispatchQueue.main.async {
                guard let self = self, videoIndex < self.videos.count else { return }
                
                if let cgImage = cgImage {
                    let image = UIImage(cgImage: cgImage)
                    self.addThumbnailToMainTimeline(image: image, videoIndex: videoIndex)
                } else {
                    print("Failed to generate thumbnail at time: \(CMTimeGetSeconds(requestedTime)), error: \(String(describing: error))")
                    let placeholderImage = self.createPlaceholderImage()
                    self.addThumbnailToMainTimeline(image: placeholderImage, videoIndex: videoIndex)
                }
            }
        }
    }
    
    private func addThumbnailToMainTimeline(image: UIImage, videoIndex: Int) {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 0
        imageView.backgroundColor = .systemGray5
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        
        // Ensure each thumbnail is exactly 60px wide and 60px tall
        let thumbnailWidth: CGFloat = 60
        let thumbnailHeight: CGFloat = 60
        imageView.widthAnchor.constraint(equalToConstant: thumbnailWidth).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: thumbnailHeight).isActive = true
        
        // Add tap gesture to thumbnail
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(thumbnailTapped(_:)))
        imageView.addGestureRecognizer(tapGesture)
        
        // Add to main timeline stack view
        stackView.addArrangedSubview(imageView)
        
        // Add corresponding time labels (at thumbnail boundaries)
        addTimeLabelForThumbnail()
        
        // Add to video's thumbnail array
        if videoIndex < videos.count {
            videos[videoIndex].thumbnailViews.append(imageView)
            
            // Update selection visual if this video is selected
            if selectedVideoIndex == videoIndex {
                DispatchQueue.main.async {
                    self.updateSelectionVisual()
                }
            }
        }
    }
    
    private func addTimeLabelForThumbnail() {
        let currentThumbnailCount = stackView.arrangedSubviews.count
        
        // If this is the first thumbnail, add the starting time label (0.0)
        if currentThumbnailCount == 1 {
            addTimeLabel(timeValue: 0.0, xPosition: 0)
        }
        
        // Add the ending time label for this thumbnail
        let endTimeValue = Double(currentThumbnailCount) * thumbnailTimeInterval
        let xPosition = CGFloat(currentThumbnailCount * 60) // 60px per thumbnail
        addTimeLabel(timeValue: endTimeValue, xPosition: xPosition)
    }
    
    private func addTimeLabel(timeValue: Double, xPosition: CGFloat) {
        let timeLabel = UILabel()
        timeLabel.text = String(format: "%.1f", timeValue)
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .medium)
        timeLabel.textColor = .black
        timeLabel.textAlignment = .center
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to time container
        timeContainer.addSubview(timeLabel)
        
        // Position the time label at the boundary
        NSLayoutConstraint.activate([
            timeLabel.centerXAnchor.constraint(equalTo: timeContainer.leadingAnchor, constant: xPosition),
            timeLabel.centerYAnchor.constraint(equalTo: timeContainer.centerYAnchor),
            timeLabel.widthAnchor.constraint(equalToConstant: 30)
        ])
        
        print("Added time label \(timeValue) at x position: \(xPosition)")
    }
    
    private func createPlaceholderImage() -> UIImage {
        let size = CGSize(width: 60, height: 60)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.systemGray4.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        
        // Add a play icon or text
        let playIcon = "▶"
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.systemGray2,
            .font: UIFont.systemFont(ofSize: timelineHeight * 0.3)
        ]
        let textSize = playIcon.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        playIcon.draw(in: textRect, withAttributes: attributes)
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}