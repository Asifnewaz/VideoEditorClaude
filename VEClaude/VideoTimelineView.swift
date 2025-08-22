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

// MARK: - Video Thumbnail Container
class VideoThumbnailContainer: UIView {
    private var thumbnailViews: [UIImageView] = []
    private var contentView: UIView!
    private var stackView: UIStackView!
    let videoIndex: Int
    let videoURL: URL
    
    init(videoIndex: Int, videoURL: URL) {
        self.videoIndex = videoIndex
        self.videoURL = videoURL
        super.init(frame: .zero)
        setupContainer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupContainer() {
        backgroundColor = .clear
        clipsToBounds = true // Enable clipping for cropping effect
        
        // Create content view that will hold all thumbnails
        contentView = UIView()
        contentView.backgroundColor = .clear
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        
        // Content view fills the container initially, but won't be resized during clipping
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
            // Note: No trailing constraint - width will be set programmatically
        ])
        
        // Stack view for thumbnails goes inside content view
        stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 0
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func addThumbnail(_ imageView: UIImageView) {
        thumbnailViews.append(imageView)
        stackView.addArrangedSubview(imageView)
        
        // Update content view width to fit all thumbnails
        let totalWidth = CGFloat(thumbnailViews.count * 60)
        let currentHeight = max(frame.height, 60) // Use 60px as minimum height
        contentView.frame = CGRect(x: contentView.frame.origin.x, y: 0, width: totalWidth, height: currentHeight)
    }
    
    func getThumbnailViews() -> [UIImageView] {
        return thumbnailViews
    }
    
    func getThumbnailCount() -> Int {
        return thumbnailViews.count
    }
    
    func getContentView() -> UIView {
        return contentView
    }
    
    func updateContentViewSize() {
        let totalWidth = CGFloat(thumbnailViews.count * 60)
        contentView.frame = CGRect(x: contentView.frame.origin.x, y: 0, width: totalWidth, height: frame.height)
    }
}

// MARK: - Video Selection View
class VideoSelectionView: UIView {
    private var selectionOverlay: UIView!
    private var leftEar: UIView!
    private var rightEar: UIView!
    
    weak var delegate: VideoTimelineView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSelectionView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSelectionView()
    }
    
    private func setupSelectionView() {
        backgroundColor = .clear
        isHidden = true
        
        // Selection overlay
        selectionOverlay = UIView()
        selectionOverlay.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
        selectionOverlay.layer.borderColor = UIColor.systemBlue.cgColor
        selectionOverlay.layer.borderWidth = 2
        selectionOverlay.layer.cornerRadius = 0
        selectionOverlay.translatesAutoresizingMaskIntoConstraints = false
        addSubview(selectionOverlay)
        
        // Left ear handle
        leftEar = UIView()
        leftEar.backgroundColor = UIColor.systemBlue
        leftEar.layer.cornerRadius = 4
        leftEar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        leftEar.isUserInteractionEnabled = true
        leftEar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftEar)
        
        // Right ear handle
        rightEar = UIView()
        rightEar.backgroundColor = UIColor.systemBlue
        rightEar.layer.cornerRadius = 4
        rightEar.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        rightEar.isUserInteractionEnabled = true
        rightEar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rightEar)
        
        // Add pan gestures
        let leftEarPanGesture = UIPanGestureRecognizer(target: self, action: #selector(leftEarPanned(_:)))
        leftEar.addGestureRecognizer(leftEarPanGesture)
        
        let rightEarPanGesture = UIPanGestureRecognizer(target: self, action: #selector(rightEarPanned(_:)))
        rightEar.addGestureRecognizer(rightEarPanGesture)
    }
    
    func updateSelection(frame: CGRect) {
        self.frame = frame
        updateInternalLayout()
        isHidden = false
    }
    
    private func updateInternalLayout() {
        // Position selection overlay to fill the frame
        selectionOverlay.frame = CGRect(x: 20, y: 0, width: frame.width - 40, height: frame.height)
        
        // Position ears
        leftEar.frame = CGRect(x: 0, y: 0, width: 20, height: frame.height)
        rightEar.frame = CGRect(x: frame.width - 20, y: 0, width: 20, height: frame.height)
    }
    
    func updateFrame(_ newFrame: CGRect) {
        self.frame = newFrame
        updateInternalLayout()
    }
    
    func hideSelection() {
        isHidden = true
    }
    
    func getLeftEarPosition() -> CGFloat {
        return frame.origin.x + leftEar.frame.origin.x + leftEar.frame.width
    }
    
    func getRightEarPosition() -> CGFloat {
        return frame.origin.x + rightEar.frame.origin.x
    }
    
    @objc private func leftEarPanned(_ gesture: UIPanGestureRecognizer) {
        delegate?.handleLeftEarPan(gesture, selectionView: self)
    }
    
    @objc private func rightEarPanned(_ gesture: UIPanGestureRecognizer) {
        delegate?.handleRightEarPan(gesture, selectionView: self)
    }
}

class VideoTimelineView: UIView {
    
    // MARK: - Properties
    private var scrollView: UIScrollView!
    private var timeContainer: UIView!
    private var thumbnailContainer: UIView!
    private var videoContainers: [VideoThumbnailContainer] = []
    private var selectionView: VideoSelectionView!
    private var stackViewWidthConstraint: NSLayoutConstraint!
    private var timeContainerWidthConstraint: NSLayoutConstraint!
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
        
        // Original video properties (never change)
        var originalThumbnailCount: Int = 0
        var originalWidth: CGFloat = 0
        var originalStartPosition: CGFloat = 0
        
        // Current cropping state
        var leftCropAmount: CGFloat = 0  // How much cropped from left
        var rightCropAmount: CGFloat = 0 // How much cropped from right
        
        init(url: URL) {
            self.url = url
        }
        
        func setOriginalDimensions(thumbnailCount: Int, startPosition: CGFloat) {
            self.originalThumbnailCount = thumbnailCount
            self.originalWidth = CGFloat(thumbnailCount * 60)
            self.originalStartPosition = startPosition
            print("SetOriginalDimensions - thumbnailCount: \(thumbnailCount), originalWidth: \(originalWidth), startPosition: \(startPosition)")
        }
        
        func getCurrentWidth() -> CGFloat {
            return originalWidth - leftCropAmount - rightCropAmount
        }
        
        func getCurrentStartPosition() -> CGFloat {
            return originalStartPosition + leftCropAmount
        }
        
        
        func getMaxLeftCrop() -> CGFloat {
            return originalWidth - 60 // Leave at least 1 thumbnail (60px)
        }
        
        func getMaxRightCrop() -> CGFloat {
            return originalWidth - 60 // Leave at least 1 thumbnail (60px)
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
        
        // Thumbnail container (below time container) - holds all video containers
        thumbnailContainer = UIView()
        thumbnailContainer.backgroundColor = .clear
        thumbnailContainer.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(thumbnailContainer)
        
        // Selection view (overlay with ears)
        selectionView = VideoSelectionView()
        selectionView.delegate = self
        selectionView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(selectionView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            
            // Time container constraints (top area)
            timeContainer.topAnchor.constraint(equalTo: scrollView.topAnchor),
            timeContainer.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            timeContainer.heightAnchor.constraint(equalToConstant: 20),
            
            // Thumbnail container constraints (below time container)
            thumbnailContainer.topAnchor.constraint(equalTo: timeContainer.bottomAnchor, constant: 2),
            thumbnailContainer.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            thumbnailContainer.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            thumbnailContainer.heightAnchor.constraint(equalTo: scrollView.heightAnchor, constant: -22)
        ])
        
        // Initialize width constraints with minimum width
        timeContainerWidthConstraint = timeContainer.widthAnchor.constraint(equalToConstant: 0)
        stackViewWidthConstraint = thumbnailContainer.widthAnchor.constraint(equalToConstant: 0)
        
        timeContainerWidthConstraint.isActive = true
        stackViewWidthConstraint.isActive = true
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
        
        // Calculate start index for this video (after all existing video containers)
        var currentThumbnailCount = 0
        for container in videoContainers {
            currentThumbnailCount += container.getThumbnailCount()
        }
        videoSegment.startIndex = currentThumbnailCount
        
        // Create video container
        let videoContainer = VideoThumbnailContainer(videoIndex: videos.count, videoURL: url)
        videoContainers.append(videoContainer)
        
        videos.append(videoSegment)
        generateThumbnails(for: videos.count - 1)
    }
    
    func clearAllVideos() {
        videos.removeAll()
        videoContainers.forEach { $0.removeFromSuperview() }
        videoContainers.removeAll()
        timeContainer.subviews.forEach { $0.removeFromSuperview() }
        selectedVideoIndex = nil
        updateScrollViewContentSize()
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
        
        // Find which video container this thumbnail belongs to
        for (containerIndex, container) in videoContainers.enumerated() {
            if container.getThumbnailViews().contains(tappedImageView) {
                print("Found tapped thumbnail belongs to video at index: \(containerIndex)")
                
                // Toggle selection: if already selected, deselect; otherwise select
                if selectedVideoIndex == containerIndex {
                    // Deselect the video
                    print("Video \(containerIndex) is already selected, deselecting...")
                    selectedVideoIndex = nil
                    print("Deselected video at index: \(containerIndex), selectedVideoIndex is now: \(selectedVideoIndex?.description ?? "nil")")
                } else {
                    // Select the video
                    print("Selecting video at index: \(containerIndex)")
                    selectedVideoIndex = containerIndex
                    delegate?.videoTimelineView(self, didSelectVideoAt: containerIndex)
                    print("Selected video at index: \(containerIndex)")
                }
                break
            }
        }
    }
    
    private func updateSelectionVisual() {
        print("updateSelectionVisual called with selectedVideoIndex: \(selectedVideoIndex?.description ?? "nil")")
        
        guard let selectedIndex = selectedVideoIndex,
              selectedIndex < videos.count,
              selectedIndex < videoContainers.count else {
            print("Hiding selection view")
            selectionView.hideSelection()
            return
        }
        
        let selectedContainer = videoContainers[selectedIndex]
        let selectedVideo = videos[selectedIndex]
        
        // Calculate the rect for the entire selected video container
        if !selectedVideo.thumbnailViews.isEmpty {
            // Force layout update
            thumbnailContainer.layoutIfNeeded()
            
            // Add container to thumbnail container if not already added
            if selectedContainer.superview == nil {
                thumbnailContainer.addSubview(selectedContainer)
            }
            
            // Use current container frame (which may be cropped) instead of recalculating
            let currentContainerFrame = selectedContainer.frame
            
            // Update selection view frame based on current container dimensions
            let selectionFrame = CGRect(
                x: currentContainerFrame.origin.x - 20, // 20px left ear
                y: 22, // Position below time container (20px height + 2px spacing)
                width: currentContainerFrame.width + 40, // Add 40px for both ears
                height: thumbnailContainer.frame.height
            )
            
            selectionView.updateSelection(frame: selectionFrame)
            
            print("Selection view: x=\(currentContainerFrame.origin.x - 20), width=\(currentContainerFrame.width + 40)")
            print("Container: x=\(currentContainerFrame.origin.x), width=\(currentContainerFrame.width)")
        } else {
            selectionView.hideSelection()
        }
    }
    
    
    private func updateScrollViewContentSize() {
        // Calculate total width from all video containers using their current frames (may be cropped)
        var totalWidth: CGFloat = 0
        for container in videoContainers {
            totalWidth += container.frame.width
        }
        
        // Update scroll view content size to match total thumbnail width
        scrollView.contentSize = CGSize(width: totalWidth, height: scrollView.frame.height)
        
        // Update existing width constraints
        stackViewWidthConstraint.constant = totalWidth
        timeContainerWidthConstraint.constant = totalWidth
        
        print("Updated scrollView contentSize to width: \(totalWidth) for \(videoContainers.count) video containers")
    }
    
    private func updateEffectiveContentSize() {
        // Calculate total width from all video containers (including trimmed ones)
        var totalWidth: CGFloat = 0
        for container in videoContainers {
            totalWidth += container.frame.width
        }
        
        // Update scroll view content size
        scrollView.contentSize = CGSize(width: totalWidth, height: scrollView.frame.height)
        
        // Update width constraints
        stackViewWidthConstraint.constant = totalWidth
        timeContainerWidthConstraint.constant = totalWidth
        
        print("Updated effective contentSize to width: \(totalWidth) based on container frames")
    }
    
    
    private func updateTimeLabelsForTrimming() {
        // Remove all existing time labels
        timeContainer.subviews.forEach { $0.removeFromSuperview() }
        
        var currentTimeOffset: Double = 0.0
        var currentXPosition: CGFloat = 0.0
        
        // Rebuild entire timeline with proper time labels based on container layout
        for (videoIndex, container) in videoContainers.enumerated() {
            let thumbnailCount = container.getThumbnailCount()
            let containerWidth = container.frame.width
            
            if videoIndex == selectedVideoIndex {
                // Handle selected (potentially trimmed) video
                let effectiveThumbnailCount = Int(containerWidth / 60)
                
                // Add time labels for visible portion only
                if effectiveThumbnailCount > 0 {
                    // Add start time label at current position
                    addTimeLabel(timeValue: currentTimeOffset, xPosition: currentXPosition)
                    
                    // Add intermediate time labels
                    for i in 1...effectiveThumbnailCount {
                        let timeValue = currentTimeOffset + (Double(i) * thumbnailTimeInterval)
                        let xPosition = currentXPosition + CGFloat(i * 60)
                        addTimeLabel(timeValue: timeValue, xPosition: xPosition)
                    }
                    
                    // Update offset for next video
                    currentTimeOffset += Double(effectiveThumbnailCount) * thumbnailTimeInterval
                    currentXPosition += containerWidth
                }
            } else {
                // Handle non-selected videos (use current container width, may be trimmed)
                let effectiveThumbnailCount = Int(containerWidth / 60)
                
                if effectiveThumbnailCount > 0 {
                    // Add start time label at current position
                    addTimeLabel(timeValue: currentTimeOffset, xPosition: currentXPosition)
                    
                    // Add time labels based on effective (possibly trimmed) width
                    for i in 1...effectiveThumbnailCount {
                        let timeValue = currentTimeOffset + (Double(i) * thumbnailTimeInterval)
                        let xPosition = currentXPosition + CGFloat(i * 60)
                        addTimeLabel(timeValue: timeValue, xPosition: xPosition)
                    }
                    
                    // Update offset for next video using actual container width
                    currentTimeOffset += Double(effectiveThumbnailCount) * thumbnailTimeInterval
                    currentXPosition += containerWidth
                }
            }
        }
        
        print("Updated full timeline time labels, total duration: \(currentTimeOffset)s, total width: \(currentXPosition)px")
    }
    
    // MARK: - Pan Gesture Handlers
    func handleLeftEarPan(_ gesture: UIPanGestureRecognizer, selectionView: VideoSelectionView) {
        guard let selectedIndex = selectedVideoIndex,
              selectedIndex < videos.count,
              selectedIndex < videoContainers.count else { return }
        
        let translation = gesture.translation(in: scrollView)
        let selectedContainer = videoContainers[selectedIndex]
        
        // Get video segment data model
        let selectedVideoSegment = videos[selectedIndex]
        let originalWidth = selectedVideoSegment.originalWidth
        let originalStartPosition = selectedVideoSegment.originalStartPosition
        
        switch gesture.state {
        case .changed:
            let newLeftEarX = selectionView.frame.origin.x + translation.x
            
            // Constrain left ear movement based on original video position
            let minX = originalStartPosition - 20 // Original left ear position
            let maxX = selectionView.frame.origin.x + selectionView.frame.width - 40 // Minimum content width
            let clampedX = max(minX, min(newLeftEarX, maxX))
            
            // Calculate how much to clip from the left relative to original position
            let clipStartX = max(0, clampedX + 20 - originalStartPosition)
            
            // Update selection view position
            let newWidth = selectionView.frame.width - (clampedX - selectionView.frame.origin.x)
            let newSelectionFrame = CGRect(x: clampedX, y: selectionView.frame.origin.y, width: newWidth, height: selectionView.frame.height)
            selectionView.updateFrame(newSelectionFrame)
            
            // Update crop amount in data model
            let currentRightEarStartX = selectionView.frame.origin.x + newWidth - 20
            let rightCropFromOriginal = max(0, originalStartPosition + originalWidth - currentRightEarStartX)
            
            selectedVideoSegment.leftCropAmount = clipStartX
            selectedVideoSegment.rightCropAmount = rightCropFromOriginal
            
            
            // Update container frame: move start position and reduce width
            // Content view inside stays at original size and position, creating clipping effect
            selectedContainer.frame = CGRect(
                x: originalStartPosition + clipStartX,
                y: selectedContainer.frame.origin.y,
                width: originalWidth - clipStartX - rightCropFromOriginal,
                height: selectedContainer.frame.height
            )
            
            // Move content view to compensate for container position change
            // This keeps thumbnails in their original absolute positions
            let contentView = selectedContainer.getContentView()
            contentView.frame = CGRect(
                x: -clipStartX,  // Negative offset to compensate for container movement
                y: 0,
                width: originalWidth,  // Keep original content width
                height: selectedContainer.frame.height
            )
            
            gesture.setTranslation(.zero, in: scrollView)
            
            // Update time labels and reposition subsequent videos
            updateTimeLabelsForTrimming()
            repositionVideoContainersAfterTrimming(selectedIndex: selectedIndex)
            
        case .ended:
            updateEffectiveContentSize()
            
        default:
            break
        }
    }
    
    func handleRightEarPan(_ gesture: UIPanGestureRecognizer, selectionView: VideoSelectionView) {
        guard let selectedIndex = selectedVideoIndex,
              selectedIndex < videos.count,
              selectedIndex < videoContainers.count else { return }
        
        let translation = gesture.translation(in: scrollView)
        let selectedContainer = videoContainers[selectedIndex]
        
        // Get video segment data model
        let selectedVideoSegment = videos[selectedIndex]
        let originalWidth = selectedVideoSegment.originalWidth
        let originalStartPosition = selectedVideoSegment.originalStartPosition
        
        print("RightEar Debug - originalWidth: \(originalWidth), originalStartPosition: \(originalStartPosition)")
        print("RightEar Debug - current selection width: \(selectionView.frame.width), translation: \(translation.x)")
        
        switch gesture.state {
        case .changed:
            let currentRightX = selectionView.frame.origin.x + selectionView.frame.width
            let newRightX = currentRightX + translation.x
            
            // Calculate maximum allowed position based on original video content
            let originalContainerEndX = originalStartPosition + originalWidth
            
            // Calculate boundaries based on original video content and current left ear position
            let currentLeftEarEndX = selectionView.frame.origin.x + 20 // Where content actually starts
            let minRightEarX = currentLeftEarEndX + 60 + 20 // Minimum 1 second content + right ear width
            
            // Always limit expansion to original duration - no video can exceed its original length
            let maxRightEarX = originalContainerEndX + 20 // Maximum at original video end, never beyond
            
            print("RightEar Debug - currentRightX: \(currentRightX), newRightX: \(newRightX)")
            print("RightEar Debug - minRightEarX: \(minRightEarX), maxRightEarX: \(maxRightEarX)")
            
            // Only constrain if the user is actually trying to go beyond boundaries
            let clampedRightX: CGFloat
            if newRightX < minRightEarX {
                clampedRightX = minRightEarX
                print("RightEar Debug - Constrained to minimum")
            } else if newRightX > maxRightEarX {
                clampedRightX = maxRightEarX
                print("RightEar Debug - Constrained to maximum")
            } else {
                clampedRightX = newRightX
                print("RightEar Debug - No constraint applied")
            }
            
            // Calculate new selection width
            let requestedSelectionWidth = clampedRightX - selectionView.frame.origin.x
            
            // Ensure selection view cannot exceed original video boundaries (including ears)
            let maxAllowedSelectionWidth = originalWidth + 40 // Original content + 40px for ears
            let constrainedSelectionWidth = min(requestedSelectionWidth, maxAllowedSelectionWidth)
            
            print("RightEar Debug - requestedSelectionWidth: \(requestedSelectionWidth), maxAllowedSelectionWidth: \(maxAllowedSelectionWidth), constrainedSelectionWidth: \(constrainedSelectionWidth)")
            
            // Update selection view with constrained width
            let newSelectionFrame = CGRect(x: selectionView.frame.origin.x, y: selectionView.frame.origin.y, width: constrainedSelectionWidth, height: selectionView.frame.height)
            selectionView.updateFrame(newSelectionFrame)
            
            // Use the constrained selection width for all subsequent calculations
            let newSelectionWidth = constrainedSelectionWidth
            
            // Calculate container clipping from right: reduce width only
            // Thumbnails inside stay in their original positions but get clipped
            let requestedContentWidth = newSelectionWidth - 40 // Account for 20px ears on each side
            let effectiveContentWidth = min(requestedContentWidth, originalWidth) // Never exceed original width
            let clippedWidth = effectiveContentWidth
            
            print("RightEar Debug - requestedContentWidth: \(requestedContentWidth), originalWidth: \(originalWidth), effectiveContentWidth: \(effectiveContentWidth)")
            
            // Update crop amount in data model
            let leftCropFromOriginal = max(0, currentLeftEarEndX - originalStartPosition)
            let rightCropFromOriginal = max(0, originalWidth - (effectiveContentWidth + leftCropFromOriginal))
            
            selectedVideoSegment.leftCropAmount = leftCropFromOriginal
            selectedVideoSegment.rightCropAmount = rightCropFromOriginal
            
            
            // Update container frame: reduce width only (no position change)
            // Content view inside stays at original size, creating clipping effect
            selectedContainer.frame = CGRect(
                x: selectedContainer.frame.origin.x, // Keep current x position
                y: selectedContainer.frame.origin.y,
                width: clippedWidth,
                height: selectedContainer.frame.height
            )
            
            print("RightEar Debug - Updated container width to: \(clippedWidth) for video \(selectedIndex)")
            
            // Content view stays at original position and size for right clipping
            // No need to move content view as container position didn't change
            let contentView = selectedContainer.getContentView()
            contentView.frame = CGRect(
                x: contentView.frame.origin.x, // Keep current x position
                y: 0,
                width: originalWidth, // Keep original content width
                height: selectedContainer.frame.height
            )
            
            gesture.setTranslation(.zero, in: scrollView)
            
            // Update time labels and reposition subsequent videos
            updateTimeLabelsForTrimming()
            repositionVideoContainersAfterTrimming(selectedIndex: selectedIndex)
            
        case .ended:
            updateEffectiveContentSize()
            
        default:
            break
        }
    }
    
    private func repositionVideoContainersAfterTrimming(selectedIndex: Int) {
        var currentX: CGFloat = 0
        
        for (index, container) in videoContainers.enumerated() {
            if index < selectedIndex {
                // Keep original position for containers before selected
                currentX = container.frame.origin.x + container.frame.width
            } else if index == selectedIndex {
                // Selected container already positioned, get its end
                currentX = container.frame.origin.x + container.frame.width
            } else {
                // Reposition containers after selected
                container.frame = CGRect(
                    x: currentX,
                    y: container.frame.origin.y,
                    width: container.frame.width,
                    height: container.frame.height
                )
                currentX += container.frame.width
            }
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
        guard videoIndex < videoContainers.count else { return }
        
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
        
        // Add to video container instead of main stack view
        let videoContainer = videoContainers[videoIndex]
        videoContainer.addThumbnail(imageView)
        
        // Add corresponding time labels (at thumbnail boundaries)
        addTimeLabelForThumbnail()
        
        // Add to video's thumbnail array
        if videoIndex < videos.count {
            videos[videoIndex].thumbnailViews.append(imageView)
            
            // Update container positioning only for the current video being added
            updateSingleVideoContainerPosition(videoIndex: videoIndex)
            
            // Update selection visual if this video is selected
            if selectedVideoIndex == videoIndex {
                DispatchQueue.main.async {
                    self.updateSelectionVisual()
                }
            }
        }
        
        // Update scroll view content size
        updateScrollViewContentSize()
    }
    
    private func updateVideoContainerPositions() {
        var currentX: CGFloat = 0
        
        // Calculate appropriate height (60px for thumbnails)
        let containerHeight: CGFloat = max(thumbnailContainer.frame.height, 60)
        
        for (index, container) in videoContainers.enumerated() {
            let containerWidth = CGFloat(container.getThumbnailCount() * 60)
            
            container.frame = CGRect(
                x: currentX,
                y: 0,
                width: containerWidth,
                height: containerHeight
            )
            
            // Update content view to match container size initially
            let contentView = container.getContentView()
            contentView.frame = CGRect(
                x: 0,
                y: 0,
                width: containerWidth,
                height: containerHeight
            )
            
            // Add container to thumbnail container if not already added
            if container.superview == nil {
                thumbnailContainer.addSubview(container)
            }
            
            // Update video start index
            videos[index].startIndex = Int(currentX / 60)
            
            currentX += container.frame.width
        }
    }
    
    private func updateSingleVideoContainerPosition(videoIndex: Int) {
        guard videoIndex < videoContainers.count else { return }
        
        let container = videoContainers[videoIndex]
        let containerHeight: CGFloat = max(thumbnailContainer.frame.height, 60)
        
        // Calculate position based on previous containers
        var currentX: CGFloat = 0
        for i in 0..<videoIndex {
            currentX += videoContainers[i].frame.width
        }
        
        let containerWidth = CGFloat(container.getThumbnailCount() * 60)
        
        // Update container frame to accommodate new thumbnails
        container.frame = CGRect(
            x: currentX,
            y: 0,
            width: containerWidth,
            height: containerHeight
        )
        
        // Update content view to match container size
        let contentView = container.getContentView()
        contentView.frame = CGRect(
            x: contentView.frame.origin.x, // Preserve x position (may be adjusted for cropping)
            y: 0,
            width: containerWidth,
            height: containerHeight
        )
        
        // Add container to thumbnail container if not already added
        if container.superview == nil {
            thumbnailContainer.addSubview(container)
        }
        
        // Update video start index
        videos[videoIndex].startIndex = Int(currentX / 60)
        
        // Update original dimensions continuously as thumbnails are added
        videos[videoIndex].setOriginalDimensions(
            thumbnailCount: container.getThumbnailCount(),
            startPosition: currentX
        )
    }
    
    private func addTimeLabelForThumbnail() {
        // Calculate total thumbnail count from all containers
        var currentThumbnailCount = 0
        for container in videoContainers {
            currentThumbnailCount += container.getThumbnailCount()
        }
        
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
