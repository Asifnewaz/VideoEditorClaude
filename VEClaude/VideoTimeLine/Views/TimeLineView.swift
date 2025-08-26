//
//  TimeLineView.swift
//  VideoCat
//
//  Created by Vito on 13/11/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import AVFoundation

// Associated object key for storing width constraint reference
private var stickerWidthConstraintKey: UInt8 = 0

class TimeLineView: UIView {

    private(set) var scrollView: UIScrollView!
    private(set) var contentView: UIView!
    fileprivate(set) var videoListContentView: UIView!
    private(set) var stickerContentView: UIView!
    private(set) var centerLineView: UIView!
    private(set) var totalTimeLabel: UILabel!
    private(set) var rulerView: TimelineRulerView!
    private(set) var scrollContentHeightConstraint: NSLayoutConstraint!
    
    private(set) var rangeViews: [VideoRangeView] = []
    private(set) var stickerViews: [VideoRangeView] = [] // Sticker VideoRangeViews
    private(set) var trackItems: [AssetTrackItem] = []
    
    var rangeViewsIndex: Int {
        var index = 0
        let center = centerLineView.center
        for (i, view) in rangeViews.enumerated() {
            let rect = view.superview!.convert(view.frame, to: centerLineView.superview!)
            if rect.contains(center) {
                index = i
                break
            }
        }
        
        return index
    }
    var videoRangeViewEarWidth: CGFloat = 24
    var widthPerSecond: CGFloat = 60
    var renderSize: CGSize = {
        let width = UIScreen.main.bounds.width * UIScreen.main.scale
        let height: CGFloat = round(width * 0.5625)
        return CGSize.init(width: width, height: height)
    }()
    
    @objc dynamic var isScrolling: Bool = false
    var isFocusMode: Bool = false {
        didSet {
            if !isFocusMode {
                resignVideoRangeView()
            }
        }
    }
    var activeNextClipHandler: (() -> Bool)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        // Initialize ruler view at top of parent view
        rulerView = TimelineRulerView()
        rulerView.widthPerSecond = widthPerSecond
        //rulerView.contentStartOffset = videoRangeViewEarWidth // Start from thumbnail position, not ear
        rulerView.backgroundColor = .systemGray5
        addSubview(rulerView)
        
        scrollView = UIScrollView()
        addSubview(scrollView)
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.contentSize = CGSize(width: 0, height: bounds.height)
        scrollView.delegate = self
        scrollView.backgroundColor = .clear
        
        // Hide scroll indicators
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        
        contentView = UIView()
        contentView.backgroundColor = .clear
        scrollView.addSubview(contentView)
        
        videoListContentView = UIView()
        videoListContentView.backgroundColor = .clear
        contentView.addSubview(videoListContentView)
        
        centerLineView = UIView()
        addSubview(centerLineView)
        centerLineView.isUserInteractionEnabled = false
        centerLineView.backgroundColor = UIColor.orange
        
        totalTimeLabel = UILabel()
        addSubview(totalTimeLabel)
        totalTimeLabel.textColor = UIColor.white
        totalTimeLabel.font = UIFont.systemFont(ofSize: 16)
        
        // Initialize sticker content view
        stickerContentView = UIView()
        stickerContentView.backgroundColor = .clear
        contentView.addSubview(stickerContentView)
        
        // Ruler view constraints (at the top of parent view)
        rulerView.translatesAutoresizingMaskIntoConstraints = false
        rulerView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        rulerView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: videoRangeViewEarWidth).isActive = true
        rulerView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -videoRangeViewEarWidth).isActive = true
        rulerView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        // ScrollView constraints (below ruler)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.topAnchor.constraint(equalTo: rulerView.bottomAnchor).isActive = true
        scrollView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        scrollView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -60).isActive = true
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor).isActive = true
        contentView.leftAnchor.constraint(equalTo: scrollView.leftAnchor).isActive = true
        contentView.rightAnchor.constraint(equalTo: scrollView.rightAnchor).isActive = true
        scrollContentHeightConstraint = contentView.heightAnchor.constraint(equalToConstant: 115) // 50 for video + 15 spacing + 50 for sticker
        scrollContentHeightConstraint.isActive = true
        
        // Video list content view constraints (top part of content view)
        videoListContentView.translatesAutoresizingMaskIntoConstraints = false
        videoListContentView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        videoListContentView.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        videoListContentView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        videoListContentView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        // Sticker content view constraints (15px below video content)
        stickerContentView.translatesAutoresizingMaskIntoConstraints = false
        stickerContentView.topAnchor.constraint(equalTo: videoListContentView.bottomAnchor, constant: 15).isActive = true
        stickerContentView.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        stickerContentView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        stickerContentView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        centerLineView.translatesAutoresizingMaskIntoConstraints = false
        centerLineView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        centerLineView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        centerLineView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -60).isActive = true
        centerLineView.widthAnchor.constraint(equalToConstant: 1).isActive = true
        
        totalTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        let timeLabelRightConstraint = totalTimeLabel.rightAnchor.constraint(equalTo: rightAnchor)
        timeLabelRightConstraint.constant = -15
        timeLabelRightConstraint.isActive = true
        let timeLabelBottomConstraint = totalTimeLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        timeLabelBottomConstraint.constant = -10
        timeLabelBottomConstraint.isActive = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapLineViewAction(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let inset = bounds.width * 0.5 - videoRangeViewEarWidth
        scrollView.contentInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
    }
    
    // MARK: - Actions
    
    @objc private func tapContentAction(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended {
            if let view = recognizer.view as? VideoRangeView, !view.isEditActive {
                view.superview?.bringSubviewToFront(view)
                view.isEditActive = true
                
                // Check if this is a sticker or video view and deactivate the other type
                if stickerViews.contains(view) {
                    // This is a sticker - deactivate other stickers and all videos
                    stickerViews.filter({ $0 != view && $0.isEditActive }).forEach({ $0.isEditActive = false })
                    rangeViews.filter({ $0.isEditActive }).forEach({ $0.isEditActive = false })
                } else {
                    // This is a video - deactivate other videos and all stickers
                    rangeViews.filter({ $0 != view && $0.isEditActive }).forEach({ $0.isEditActive = false })
                    stickerViews.filter({ $0.isEditActive }).forEach({ $0.isEditActive = false })
                }
            }
        }
    }
    
    @objc private func tapLineViewAction(_ recognizer: UITapGestureRecognizer) {
        let point = recognizer.location(in: recognizer.view)
        var tapOnRangeView = false
        
        // Check video range views
        for view in rangeViews {
            let rect = view.superview!.convert(view.frame, to: self)
            if rect.contains(point) {
                tapOnRangeView = true
                break
            }
        }
        
        // Check sticker range views
        if !tapOnRangeView {
            for view in stickerViews {
                let rect = view.superview!.convert(view.frame, to: self)
                if rect.contains(point) {
                    tapOnRangeView = true
                    break
                }
            }
        }
        
        if !tapOnRangeView {
            resignVideoRangeView()
            resignStickerViews()
        }
    }
    
    // MARK: - Data
    
    private let loadImageQueue: DispatchQueue = DispatchQueue(label: "com.videocat.loadimage")
    func reload(with trackItems: [AssetTrackItem]) {
        self.trackItems = trackItems
        removeAllRangeViews()
        for (index, trackItem) in trackItems.enumerated() {
            appendVideoRangeView(configuration: { (rangeView) in
                let contentView = VideoRangeContentView()
                if trackItem.assetType == .image {
                    contentView.supportUnlimitTime = true
                }
                let timeRange = trackItem.resourceTargetTimeRange
                contentView.loadImageQueue = loadImageQueue
                if let imageGenerator = trackItem.generateFullRangeImageGenerator(size: renderSize) {
                    contentView.imageGenerator = ImageGenerator.createFrom(imageGenerator)
                }
                contentView.startTime = timeRange.start
                contentView.endTime = timeRange.end
                
                
                rangeView.loadContentView(contentView)
                
                rangeView.reloadUI()
            })
        }
        
        rangeViews.enumerated().forEach { (offset, view) in
            view.leftPaddingViewConstraint.constant = 2
            view.rightPaddingViewConstraint.constant = 2
            if offset == 0 {
                view.leftPaddingViewConstraint.constant = 0
            } else if offset == rangeViews.count - 1 {
                view.rightPaddingViewConstraint.constant = 0
            }
        }
        
        // Update ruler after loading videos
        print("🟢 About to call timeDidChanged after loading videos")
        timeDidChanged()
        
        // Also try forcing a ruler refresh
        print("🟢 Also calling rulerView.forceRefresh")
        rulerView.forceRefresh()
        
        // Call again after layout to ensure frame sizes are available
        DispatchQueue.main.async { [weak self] in
            print("🟢 Delayed call to timeDidChanged after layout")
            self?.timeDidChanged()
            
            // Update sticker max durations after videos are loaded
            self?.updateStickerMaxDurations()
        }
    }
    
    func resignVideoRangeView() {
        rangeViews.filter({ $0.isEditActive }).forEach({ $0.isEditActive = false })
    }
    
    func appendVideoRangeView(configuration: (VideoRangeView) -> Void, at index: Int = Int.max) {
        // Added to the current point in time, closest.
        let videoRangeView = VideoRangeView()
        configuration(videoRangeView)
        videoRangeView.contentView.widthPerSecond = widthPerSecond
        videoRangeView.contentInset = UIEdgeInsets(top: 2, left: videoRangeViewEarWidth, bottom: 2, right: videoRangeViewEarWidth)
        videoRangeView.delegate = self
        videoRangeView.isEditActive = false
        let tapContentGesture = UITapGestureRecognizer(target: self, action: #selector(tapContentAction(_:)))
        videoRangeView.addGestureRecognizer(tapContentGesture)
        videoListContentView.insertSubview(videoRangeView, at: 0)
        
        videoRangeView.translatesAutoresizingMaskIntoConstraints = false
        videoRangeView.topAnchor.constraint(equalTo: videoListContentView.topAnchor).isActive = true
        videoRangeView.bottomAnchor.constraint(equalTo: videoListContentView.bottomAnchor).isActive = true
        if rangeViews.count == 0 {
            rangeViews.append(videoRangeView)
            videoRangeView.leftConstraint = videoRangeView.leftAnchor.constraint(equalTo: videoListContentView.leftAnchor)
            videoRangeView.leftConstraint?.isActive = true
            videoRangeView.rightConstraint = videoRangeView.rightAnchor.constraint(equalTo: videoListContentView.rightAnchor)
            videoRangeView.rightConstraint?.isActive = true
        } else {
            if index >= rangeViews.count {
                let leftVideoRangeView = rangeViews.last!
                rangeViews.append(videoRangeView)
                if let rightConstraint = leftVideoRangeView.rightConstraint {
                    rightConstraint.isActive = false
                }
                let leftConstraint = videoRangeView.leftAnchor.constraint(equalTo: leftVideoRangeView.rightAnchor)
                leftConstraint.constant = -videoRangeViewEarWidth * 2
                leftConstraint.isActive = true
                videoRangeView.leftConstraint = leftConstraint
                
                videoRangeView.rightConstraint = videoRangeView.rightAnchor.constraint(equalTo: videoListContentView.rightAnchor)
                videoRangeView.rightConstraint?.isActive = true
            } else if index == 0 {
                rangeViews.insert(videoRangeView, at: index)
                let rightVideoRangeView = rangeViews[index + 1]
                if let leftConstraint = rightVideoRangeView.leftConstraint {
                    leftConstraint.isActive = false
                }
                let leftConstraint = rightVideoRangeView.leftAnchor.constraint(equalTo: videoRangeView.rightAnchor)
                leftConstraint.constant = -videoRangeViewEarWidth * 2
                leftConstraint.isActive = true
                rightVideoRangeView.leftConstraint = leftConstraint
                
                videoRangeView.leftConstraint = videoRangeView.leftAnchor.constraint(equalTo: videoListContentView.leftAnchor)
                videoRangeView.leftConstraint?.isActive = true
            } else {
                rangeViews.insert(videoRangeView, at: index)
                let leftVideoRangeView = rangeViews[index - 1]
                videoRangeView.leftConstraint = videoRangeView.leftAnchor.constraint(equalTo: leftVideoRangeView.rightAnchor)
                videoRangeView.leftConstraint?.constant = -videoRangeViewEarWidth * 2
                videoRangeView.leftConstraint?.isActive = true
                
                let rightVideoRangeView = rangeViews[index + 1]
                if let leftConstraint = rightVideoRangeView.leftConstraint {
                    leftConstraint.isActive = false
                }
                let leftConstraint = rightVideoRangeView.leftAnchor.constraint(equalTo: videoRangeView.rightAnchor)
                leftConstraint.constant = -videoRangeViewEarWidth * 2
                leftConstraint.isActive = true
                rightVideoRangeView.leftConstraint = leftConstraint
            }
        }
        
        // Update sticker max durations when a new video is added
        DispatchQueue.main.async { [weak self] in
            self?.updateStickerMaxDurations()
        }
    }
    
    func removeAllRangeViews() {
        rangeViews.forEach { (view) in
            view.removeFromSuperview()
        }
        rangeViews.removeAll()
        
        // Update sticker max durations when videos are removed
        DispatchQueue.main.async { [weak self] in
            self?.updateStickerMaxDurations()
        }
    }
    
    
    
    fileprivate func timeDidChanged() {
        print("🟡 TimeLineView.timeDidChanged called")
        print("🟡 Number of rangeViews: \(rangeViews.count)")
        
        var duration: CGFloat = 0
        rangeViews.enumerated().forEach { (index, view) in
            let viewWidth = view.frame.size.width
            let contentWidth = view.contentView.contentWidth
            let viewDuration = viewWidth / widthPerSecond
            let contentDuration = contentWidth / widthPerSecond
            let expectedWidth = CGFloat(trackItems[index].duration.seconds) * widthPerSecond
            print("🟡 RangeView \(index): total width=\(viewWidth), content width=\(contentWidth)")
            print("🟡   Total duration=\(viewDuration), content duration=\(contentDuration)")
            print("🟡   Expected width for trackItem: \(expectedWidth) (trackItem duration: \(trackItems[index].duration.seconds))")
            print("🟡   Width difference: \(viewWidth - expectedWidth)")
            
            // Use content width for more accurate duration calculation
            duration = duration + contentDuration
        }
        print("🟡 Calculated duration from rangeViews: \(duration)")
        
        // Also calculate duration from trackItems as fallback
        var trackItemsDuration: CGFloat = 0
        trackItems.forEach { trackItem in
            let itemDuration = CGFloat(trackItem.duration.seconds)
            print("🟡 TrackItem duration: \(itemDuration)")
            trackItemsDuration += itemDuration
        }
        print("🟡 Calculated duration from trackItems: \(trackItemsDuration)")
        
        // Always prefer content width calculation as it reflects current trimmed state
        // Only fall back to trackItems if content width calculation failed (duration == 0)
        let useTrackItemsDuration = duration == 0
        let finalDuration = useTrackItemsDuration ? trackItemsDuration : duration
        print("🟡 Content duration: \(duration), trackItems duration: \(trackItemsDuration)")
        print("🟡 Using content duration (reflects trimming): \(!useTrackItemsDuration)")
        print("🟡 Final duration to use: \(finalDuration)")
        
        totalTimeLabel.text = String.init(format: "%.1f", finalDuration)
        
        print("🟡 Always showing complete timeline: 0 to \(finalDuration)")
        
        print("🟡 Handling \(rangeViews.count) videos")
        
        // Debug: show each video's range and edit status
        rangeViews.enumerated().forEach { (index, view) in
            let start = CGFloat(view.contentView.startTime.seconds)
            let end = CGFloat(view.contentView.endTime.seconds)
            let width = view.frame.size.width
            let contentWidth = view.contentView.contentWidth
            let isActive = view.isEditActive
            print("🟡   Video \(index): \(start)s-\(end)s, width: \(width), contentWidth: \(contentWidth), active: \(isActive)")
        }
        
        // Update ruler with new duration
        print("🟡 About to call rulerView.updateDuration with: \(finalDuration)")
        rulerView.updateDuration(finalDuration)
        print("🟡 TimeLineView.timeDidChanged completed")
    }
    
    // MARK: - Sticker Management
    
    func addSticker() {
        
        // Create predefined sticker image
        let stickerImage = createDefaultStickerImage()
        
        // Calculate current video timeline duration (trimmed)
        let totalVideoDuration = calculateTotalVideoDuration()
        let videoTimelineDuration = CGFloat(totalVideoDuration.seconds)
        
        // Use actual trimmed video duration or minimum 3 seconds as fallback
        let duration = max(videoTimelineDuration, 3.0)
        let stickerDuration = CMTime(seconds: duration, preferredTimescale: 600)
        
        print("🎯 Creating sticker with duration: \(duration)s (matches current trimmed video duration)")
        
        // Create sticker AssetTrackItem with predefined image and actual duration
        let stickerTrackItem = AssetTrackItem(assetType: .sticker, predefinedImage: stickerImage, duration: stickerDuration)
        
        // Create VideoRangeView for sticker
        let stickerRangeView = VideoRangeView()
        
        // Create custom content view for sticker
        let stickerRangeContentView = createStickerContentView(for: stickerTrackItem)
        stickerRangeView.loadContentView(stickerRangeContentView)
        
        // Configure sticker view properties (SAME AS VIDEO RANGE VIEWS)
        stickerRangeView.contentView.widthPerSecond = widthPerSecond  // ⚠️ CRITICAL: This enables ear movement
        stickerRangeView.contentInset = UIEdgeInsets(top: 2, left: videoRangeViewEarWidth, bottom: 2, right: videoRangeViewEarWidth)
        stickerRangeView.delegate = self
        stickerRangeView.isEditActive = false  // Match video range view initialization
        
        // Add tap gesture for selection (same as video range views)
        let tapContentGesture = UITapGestureRecognizer(target: self, action: #selector(tapContentAction(_:)))
        stickerRangeView.addGestureRecognizer(tapContentGesture)
        
        // Add to sticker views array
        stickerViews.append(stickerRangeView)
        stickerContentView.addSubview(stickerRangeView)
        
        // Position the sticker view
        positionStickerView(stickerRangeView)
        
        // Trigger UI reload (same as video range views)
        stickerRangeView.reloadUI()
        
        // Update scrollview content size to accommodate the new sticker
        updateScrollViewContentSize()
        
        print("Added sticker with duration: \(stickerTrackItem.duration.seconds)s (video timeline: \(videoTimelineDuration)s)")
    }
    
    func addText() {
        // Create predefined text image
        let textImage = createDefaultTextImage()
        
        // Calculate current video timeline duration (trimmed)
        let totalVideoDuration = calculateTotalVideoDuration()
        let videoTimelineDuration = CGFloat(totalVideoDuration.seconds)
        
        // Use actual trimmed video duration or minimum 3 seconds as fallback
        let duration = max(videoTimelineDuration, 3.0)
        let textDuration = CMTime(seconds: duration, preferredTimescale: 600)
        
        print("🎯 Creating text with duration: \(duration)s (matches current trimmed video duration)")
        
        // Create text AssetTrackItem with predefined image and actual duration
        let textTrackItem = AssetTrackItem(assetType: .text, predefinedImage: textImage, duration: textDuration)
        
        // Create VideoRangeView for text
        let textRangeView = VideoRangeView()
        
        // Create custom content view for text
        let textRangeContentView = createStickerContentView(for: textTrackItem)
        textRangeView.loadContentView(textRangeContentView)
        
        // Configure text view properties (SAME AS VIDEO RANGE VIEWS)
        textRangeView.contentView.widthPerSecond = widthPerSecond  // ⚠️ CRITICAL: This enables ear movement
        textRangeView.contentInset = UIEdgeInsets(top: 2, left: videoRangeViewEarWidth, bottom: 2, right: videoRangeViewEarWidth)
        textRangeView.delegate = self
        textRangeView.isEditActive = false  // Match video range view initialization
        
        // Add tap gesture for selection (same as video range views)
        let tapContentGesture = UITapGestureRecognizer(target: self, action: #selector(tapContentAction(_:)))
        textRangeView.addGestureRecognizer(tapContentGesture)
        
        // Add to sticker views array (we can reuse the same array for text)
        stickerViews.append(textRangeView)
        stickerContentView.addSubview(textRangeView)
        
        // Position the text view
        positionStickerView(textRangeView)
        
        // Trigger UI reload (same as video range views)
        textRangeView.reloadUI()
        
        // Update scrollview content size to accommodate the new text
        updateScrollViewContentSize()
        
        print("Added text with duration: \(textTrackItem.duration.seconds)s (video timeline: \(videoTimelineDuration)s)")
    }
    
    private func createStickerContentView(for trackItem: AssetTrackItem) -> RangeContentView {
        // Use ImageRangeContentView for sticker/text types with predefined images
        if (trackItem.assetType == .sticker || trackItem.assetType == .text), 
           let predefinedImage = trackItem.predefinedImage {
            let imageContentView = ImageRangeContentView()
            imageContentView.startTime = trackItem.timeRange.start
            imageContentView.endTime = trackItem.timeRange.end
            imageContentView.widthPerSecond = widthPerSecond
            imageContentView.supportUnlimitTime = false
            
            // Set max duration to total video duration
            let totalVideoDuration = calculateTotalVideoDuration()
            imageContentView.maxDuration = totalVideoDuration
            
            print("🚫 Set sticker max duration to: \(totalVideoDuration.seconds)s")
            
            // Configure with predefined image and asset type
            imageContentView.configure(with: predefinedImage, assetType: trackItem.assetType)
            
            return imageContentView
        }
        
        // Fallback to regular RangeContentView for other types
        let contentView = RangeContentView()
        contentView.startTime = trackItem.timeRange.start
        contentView.endTime = trackItem.timeRange.end
        contentView.widthPerSecond = widthPerSecond
        contentView.supportUnlimitTime = false
        
        // Customize appearance based on asset type
        switch trackItem.assetType {
        case .sticker:
            contentView.backgroundColor = .systemOrange.withAlphaComponent(0.8)
            contentView.layer.borderColor = UIColor.systemOrange.cgColor
        case .text:
            contentView.backgroundColor = .systemBlue.withAlphaComponent(0.8)
            contentView.layer.borderColor = UIColor.systemBlue.cgColor
        default:
            contentView.backgroundColor = .systemGray.withAlphaComponent(0.8)
            contentView.layer.borderColor = UIColor.systemGray.cgColor
        }
        
        contentView.layer.cornerRadius = 6
        contentView.layer.borderWidth = 1
        
        return contentView
    }
    
    private func positionStickerView(_ stickerView: VideoRangeView) {
        stickerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Calculate sticker positioning based on content
        let contentWidth = stickerView.contentView.contentWidth
        let startTime = stickerView.contentView.startTime
        let leftPosition = CGFloat(startTime.seconds) * widthPerSecond
        
        print("📍 Positioning sticker: startTime=\(startTime.seconds)s, leftPos=\(leftPosition), contentWidth=\(contentWidth)")
        
        // Create dynamic constraints similar to video range views
        let leftConstraint = stickerView.leftAnchor.constraint(equalTo: stickerContentView.leftAnchor, constant: leftPosition)
        let widthConstraint = stickerView.widthAnchor.constraint(equalToConstant: contentWidth + (videoRangeViewEarWidth * 2))
        
        // Store both constraints for dynamic updates
        stickerView.leftConstraint = leftConstraint
        objc_setAssociatedObject(stickerView, &stickerWidthConstraintKey, widthConstraint, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // Position and size the sticker view
        NSLayoutConstraint.activate([
            stickerView.topAnchor.constraint(equalTo: stickerContentView.topAnchor),
            stickerView.bottomAnchor.constraint(equalTo: stickerContentView.bottomAnchor),
            leftConstraint,
            widthConstraint
        ])
        
        print("✅ Positioned sticker with leftPos: \(leftPosition), width: \(contentWidth + (videoRangeViewEarWidth * 2))")
    }
    
    func removeAllStickerViews() {
        stickerViews.forEach { $0.removeFromSuperview() }
        stickerViews.removeAll()
    }
    
    func resignStickerViews() {
        stickerViews.filter({ $0.isEditActive }).forEach({ $0.isEditActive = false })
    }
    
    // MARK: - Video Duration Calculation
    
    private func calculateTotalVideoDuration() -> CMTime {
        var totalDuration = CMTime.zero
        
        // PRIORITY 1: Use rangeViews for current trimmed duration (real-time)
        for rangeView in rangeViews {
            let viewDuration = rangeView.contentView.endTime - rangeView.contentView.startTime
            totalDuration = totalDuration + viewDuration
            print("🎥 Range view (trimmed) duration: \(viewDuration.seconds)s")
        }
        
        // FALLBACK: Sum up trackItems original duration if no rangeViews
        if totalDuration == CMTime.zero {
            for trackItem in trackItems {
                if trackItem.assetType == .video || trackItem.assetType == .audio {
                    totalDuration = totalDuration + trackItem.duration
                    print("🎥 Video track (original) duration: \(trackItem.duration.seconds)s")
                }
            }
        }
        
        print("📏 Total video duration calculated: \(totalDuration.seconds)s (trimmed state)")
        return totalDuration
    }
    
    private func updateStickerMaxDurations() {
        let totalVideoDuration = calculateTotalVideoDuration()
        
        // Update max duration for all existing stickers
        for stickerView in stickerViews {
            stickerView.contentView.maxDuration = totalVideoDuration
            print("🔄 Updated sticker max duration to: \(totalVideoDuration.seconds)s")
        }
    }
    
    private func updateStickersAfterVideoTrimming() {
        let totalVideoDuration = calculateTotalVideoDuration()
        
        print("🎬 Checking stickers against video trimming - video duration: \(totalVideoDuration.seconds)s")
        
        for stickerView in stickerViews {
            let currentStickerDuration = stickerView.contentView.endTime - stickerView.contentView.startTime
            let stickerEndTime = stickerView.contentView.endTime
            let startTime = stickerView.contentView.startTime
            
            // Always update max duration (this sets the constraint for right ear dragging)
            stickerView.contentView.maxDuration = totalVideoDuration
            
            // Check if sticker end position matches video end position (within small tolerance)
            let tolerance = CMTime(seconds: 0.1, preferredTimescale: 600) // 0.1 second tolerance
            let positionsMatch = abs(stickerEndTime.seconds - totalVideoDuration.seconds) <= tolerance.seconds
            
            print("🔍 Sticker analysis:")
            print("   - Current duration: \(currentStickerDuration.seconds)s")
            print("   - Sticker end time: \(stickerEndTime.seconds)s")
            print("   - Video end time: \(totalVideoDuration.seconds)s")
            print("   - Positions match: \(positionsMatch)")
            
            // Only update sticker if:
            // 1. Sticker extends beyond video (must trim), OR
            // 2. Sticker end position matches video end position (trim together)
            if stickerEndTime > totalVideoDuration {
                // Case 1: Sticker extends beyond video - must trim
                let newEndTime = startTime + totalVideoDuration
                stickerView.contentView.endTime = newEndTime
                
                print("✂️ Trimmed sticker (exceeded video): \(currentStickerDuration.seconds)s → \(totalVideoDuration.seconds)s")
                
                updateStickerConstraints(for: stickerView)
            } else if positionsMatch {
                // Case 2: Sticker end position matches video end - trim together
                let newEndTime = startTime + totalVideoDuration
                stickerView.contentView.endTime = newEndTime
                
                print("🔄 Updated sticker (positions matched): \(currentStickerDuration.seconds)s → \(totalVideoDuration.seconds)s")
                
                updateStickerConstraints(for: stickerView)
            } else {
                // Case 3: Sticker is shorter and positions don't match - keep unchanged
                print("⏸️ Keeping sticker unchanged (different positions): \(currentStickerDuration.seconds)s")
            }
        }
        
        // Update scrollview content size after any sticker changes
        updateScrollViewContentSize()
    }
    
    // MARK: - ScrollView Content Size Management
    
    private func updateScrollViewContentSize() {
        // Calculate maximum width needed for all content (videos + stickers)
        var maxContentWidth: CGFloat = 0
        
        // Check video range views
        for rangeView in rangeViews {
            let viewRight = rangeView.frame.origin.x + rangeView.frame.size.width
            maxContentWidth = max(maxContentWidth, viewRight)
        }
        
        // Check sticker views
        for stickerView in stickerViews {
            let viewRight = stickerView.frame.origin.x + stickerView.frame.size.width
            maxContentWidth = max(maxContentWidth, viewRight)
        }
        
        // Add some padding
        maxContentWidth += 100
        
        // Update content size for all content views
        let newContentSize = CGSize(width: maxContentWidth, height: scrollView.contentSize.height)
        
        if scrollView.contentSize.width != newContentSize.width {
            print("📏 Updating scrollview content size: \(scrollView.contentSize.width) -> \(newContentSize.width)")
            scrollView.contentSize = newContentSize
            
            // Also update content view widths
            videoListContentView.frame.size.width = newContentSize.width
            stickerContentView.frame.size.width = newContentSize.width
        }
    }
    
    private func autoScrollIfNeeded(for view: VideoRangeView) {
        // Only auto-scroll for stickers extending beyond visible area
        guard stickerViews.contains(view) else { return }
        
        let viewRight = view.frame.origin.x + view.frame.size.width
        let visibleRight = scrollView.contentOffset.x + scrollView.bounds.width - scrollView.contentInset.right
        
        // If sticker extends beyond visible area, scroll to show it
        if viewRight > visibleRight {
            let targetOffset = viewRight - scrollView.bounds.width + scrollView.contentInset.right + 20 // 20px padding
            let maxOffset = scrollView.contentSize.width - scrollView.bounds.width + scrollView.contentInset.left
            let finalOffset = min(targetOffset, maxOffset)
            
            print("📱 Auto-scrolling to show sticker: targetOffset=\(finalOffset)")
            
            UIView.animate(withDuration: 0.3) {
                self.scrollView.setContentOffset(CGPoint(x: finalOffset, y: self.scrollView.contentOffset.y), animated: false)
            }
        }
    }
    
    private func updateStickerConstraints(for stickerView: VideoRangeView) {
        // Get the stored width constraint reference
        guard let widthConstraint = objc_getAssociatedObject(stickerView, &stickerWidthConstraintKey) as? NSLayoutConstraint,
              let leftConstraint = stickerView.leftConstraint else {
            print("❌ Error: Could not find stored constraints for sticker")
            // Try recreating the constraint if it's missing
            recreateStickerConstraints(for: stickerView)
            return
        }
        
        // Calculate new position and width based on content view
        let contentWidth = stickerView.contentView.contentWidth
        let startTime = stickerView.contentView.startTime
        let newLeftPosition = CGFloat(startTime.seconds) * widthPerSecond
        let newTotalWidth = contentWidth + (videoRangeViewEarWidth * 2)
        
        print("🔄 Updating sticker constraints:")
        print("  - Left: \(leftConstraint.constant) -> \(newLeftPosition)")
        print("  - Width: \(widthConstraint.constant) -> \(newTotalWidth)")
        print("  - Content: startTime=\(startTime.seconds)s, width=\(contentWidth)")
        
        // Update both constraints
        leftConstraint.constant = newLeftPosition
        widthConstraint.constant = newTotalWidth
        
        // Force immediate layout update with animation disabled
        UIView.performWithoutAnimation {
            stickerContentView.layoutIfNeeded()
            stickerView.layoutIfNeeded()
            
            // Ensure frame is updated before scrollview calculations
            stickerView.superview?.layoutIfNeeded()
        }
        
        print("✅ Sticker constraints updated successfully")
    }
    
    private func recreateStickerConstraints(for stickerView: VideoRangeView) {
        print("🔧 Recreating constraints for sticker view")
        
        // Clear existing constraint references
        stickerView.leftConstraint = nil
        objc_setAssociatedObject(stickerView, &stickerWidthConstraintKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // Remove existing constraints by removing and re-adding the view
        stickerView.removeFromSuperview()
        stickerContentView.addSubview(stickerView)
        
        // Reposition with fresh constraints
        positionStickerView(stickerView)
    }
    
    // MARK: - Predefined Image Creation
    
    private func createDefaultStickerImage() -> UIImage {
        // Try to use system image first
        if let starImage = UIImage(systemName: "star.fill") {
            return starImage.withTintColor(.white, renderingMode: .alwaysOriginal)
        }
        
        // Fallback: create a simple programmatic image
        return createProgrammaticStickerImage()
    }
    
    private func createDefaultTextImage() -> UIImage {
        // Try to use system image first
        if let textImage = UIImage(systemName: "textformat") {
            return textImage.withTintColor(.white, renderingMode: .alwaysOriginal)
        }
        
        // Fallback: create a simple programmatic image
        return createProgrammaticTextImage()
    }
    
    private func createProgrammaticStickerImage() -> UIImage {
        let size = CGSize(width: 40, height: 40)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()!
        
        // Draw a star shape
        context.setFillColor(UIColor.white.cgColor)
        
        // Simple star path
        let starPath = UIBezierPath()
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius: CGFloat = 15
        
        for i in 0..<10 {
            let angle = CGFloat(i) * .pi / 5
            let pointRadius = i % 2 == 0 ? radius : radius * 0.5
            let x = center.x + pointRadius * cos(angle - .pi / 2)
            let y = center.y + pointRadius * sin(angle - .pi / 2)
            
            if i == 0 {
                starPath.move(to: CGPoint(x: x, y: y))
            } else {
                starPath.addLine(to: CGPoint(x: x, y: y))
            }
        }
        starPath.close()
        starPath.fill()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private func createProgrammaticTextImage() -> UIImage {
        let size = CGSize(width: 40, height: 40)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()!
        
        // Draw text representation
        context.setFillColor(UIColor.white.cgColor)
        
        // Draw simple "T" shape
        let rect1 = CGRect(x: 10, y: 8, width: 20, height: 4) // Top bar
        let rect2 = CGRect(x: 18, y: 8, width: 4, height: 24) // Vertical bar
        
        context.fill(rect1)
        context.fill(rect2)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    
}

// MARK: - player
extension TimeLineView {
    func cancelLoadThumb() {
        rangeViews.forEach { (rangeView) in
            if let v = rangeView.contentView as? VideoRangeContentView {
                v.workitems.forEach({ (key, workitem) in
                    workitem.cancel()
                })
                v.workitems.removeAll()
            }
        }
    }
    
    func playerTimeChanged() {
        if isScrolling { return }
    }
    
    func adjustCollectionViewOffset(time: CMTime) {
        if !time.isValid { return }
        let time = max(time, CMTime.zero)
        let offsetX = getOffsetX(at: time).0
        if !offsetX.isNaN {
            scrollView.delegate = nil
            scrollView.contentOffset = CGPoint(x: offsetX, y: 0)
            displayRangeViewsIfNeed()
            activeCurrentVideoRangeView(time: time)
            scrollView.delegate = self
        }
    }
    
    fileprivate func activeCurrentVideoRangeView(time: CMTime) {
        if isFocusMode {
            if let view = rangeView(at: time) {
                if !view.isEditActive {
                    resignVideoRangeView()
                    if let handler = activeNextClipHandler {
                        if handler() {
                            view.superview?.bringSubviewToFront(view)
                            view.isEditActive = true
                        }
                    } else {
                        view.superview?.bringSubviewToFront(view)
                        view.isEditActive = true
                    }
                }
            }
        }
    }
    
    fileprivate func displayRangeViewsIfNeed() {
        let showingRangeViews = showingRangeView()
        let canLoadImageAsync = true
        if !shouldCancelLoadThumb(showingRangeViews) {
           // canLoadImageAsync = true
        }
        showingRangeViews.forEach({
            $0.contentView.canLoadImageAsync = canLoadImageAsync
            $0.contentView.updateDataIfNeed()
        })
    }
    
    // Is it possible to load thumbnails (it will not be loaded if there are more than 5
    fileprivate func shouldCancelLoadThumb(_ rangeViews: [VideoRangeView] = []) -> Bool {
        return ((rangeViews.count == 0) ? showingRangeView() : rangeViews).count > 7
    }
    
    // MARK: offset
    
    func getOffsetX(at time: CMTime) -> (CGFloat, Int) {
        var offsetX: CGFloat = -scrollView.contentInset.left
        guard time.isValid else { return (offsetX, 0) }
        
        var duration = time
        var index = 0
        for (i, rangeView) in rangeViews.enumerated() {
            let contentDuration = rangeView.contentView.endTime - rangeView.contentView.startTime
            if duration <= contentDuration {
                index = i
                break
            } else {
                duration = duration - contentDuration
            }
        }
        offsetX = offsetX + CGFloat(time.seconds) * widthPerSecond
        
        return (offsetX, index)
    }
    
    func getTime(at offsetX: CGFloat) -> (CMTime, Int) {
        var offsetX = offsetX + scrollView.contentInset.left
        let duration = CMTime(seconds: Float(offsetX / widthPerSecond))
        var index = 0
        for (i, rangeView) in rangeViews.enumerated() {
            let width = rangeView.contentView.contentWidth
            if offsetX <= width {
                index = i
                break
            } else {
                offsetX = offsetX - width
            }
        }
        
        return (duration, index)
    }
    
}

// MARK: - VideoRangeViewDelegate

extension TimeLineView: VideoRangeViewDelegate {
    
    fileprivate func replacePlayerItemToCurrentClipItem(view: VideoRangeView) {
        guard let index = rangeViews.firstIndex(of: view) else {
            return
        }
        if !view.contentView.supportUnlimitTime {
            let clip = trackItems[index]

        }
    }
    
    fileprivate func updateCurrentClipPlayerItem(time: CMTime, view: VideoRangeView) {
        if !view.contentView.supportUnlimitTime {
           // player?.fl_seekSmoothly(to: time)
        }
        
        let center = view.convert(view.leftEar.center, to: self)
        centerLineView.center = CGPoint(x: center.x + view.leftEar.bounds.width * 0.5, y: center.y)
    }
    
    fileprivate func restoreTimePlayerItem(view: VideoRangeView) {
        if !view.contentView.supportUnlimitTime {
        }
        
        centerLineView.center = CGPoint(x: bounds.width * 0.5, y: bounds.height * 0.5)
    }
    
    func videoRangeViewBeginUpdateLeft(_ view: VideoRangeView) {
        // Check if this is a sticker or video view
        if stickerViews.contains(view) {
            // Handle sticker independently
            view.isEditActive = true
            stickerViews.filter({ $0 != view && $0.isEditActive }).forEach({ $0.isEditActive = false })
            // Deactivate video views
            rangeViews.filter({ $0.isEditActive }).forEach({ $0.isEditActive = false })
            return
        }
        
        // Original video range view behavior
        scrollView.delegate = nil
        view.isEditActive = true
        rangeViews.filter({ $0 != view && $0.isEditActive }).forEach({ $0.isEditActive = false })
        // Deactivate sticker views
        stickerViews.filter({ $0.isEditActive }).forEach({ $0.isEditActive = false })
        replacePlayerItemToCurrentClipItem(view: view)
    }
    
    func videoRangeViewBeginUpdateRight(_ view: VideoRangeView) {
        // Check if this is a sticker or video view
        if stickerViews.contains(view) {
            // Handle sticker independently
            view.isEditActive = true
            stickerViews.filter({ $0 != view && $0.isEditActive }).forEach({ $0.isEditActive = false })
            // Deactivate video views
            rangeViews.filter({ $0.isEditActive }).forEach({ $0.isEditActive = false })
            return
        }
        
        // Original video range view behavior
        scrollView.delegate = nil
        view.isEditActive = true
        rangeViews.filter({ $0 != view && $0.isEditActive }).forEach({ $0.isEditActive = false })
        // Deactivate sticker views
        stickerViews.filter({ $0.isEditActive }).forEach({ $0.isEditActive = false })
//        delegate?.clipTimelineBeginClip(self)
//        VideoEditManager.shared.beginClipVideo()
        replacePlayerItemToCurrentClipItem(view: view)
    }
    
    func videoRangeView(_ view: VideoRangeView, updateLeftOffset offset: CGFloat, auto: Bool) {
        // Check if this is a sticker view
        if stickerViews.contains(view) {
            // For stickers, update the width constraint to reflect new content size
            let contentWidth = view.contentView.contentWidth
            print("🔄 Sticker left ear dragged - content width: \(contentWidth), offset: \(offset)")
            updateStickerConstraints(for: view)
            return
        }
        
        // Original video range view behavior
        updateCurrentClipPlayerItem(time: view.contentView.startTime, view: view)
        
        // Update ruler when ear moves
        print("🟣 Left ear moved, updating ruler")
        timeDidChanged()
        
        // Real-time sticker updates during video trimming
        updateStickersAfterVideoTrimming()
        
        if auto {
            return
        }
        
        var inset = scrollView.contentInset
        inset.left = scrollView.frame.width
        scrollView.contentInset = inset
        
        var contentOffset = scrollView.contentOffset
        contentOffset.x -= offset
        scrollView.setContentOffset(contentOffset, animated: false)
    }
    
    func videoRangeViewDidEndUpdateLeftOffset(_ view: VideoRangeView) {
        // Check if this is a sticker view
        if stickerViews.contains(view) {
            // For stickers, end edit state and ensure final width is correct
            let contentWidth = view.contentView.contentWidth
            print("⚙️ Sticker left ear drag ended - final content width: \(contentWidth)")
            view.isEditActive = false
            view.contentView.endExpand()
            updateStickerConstraints(for: view)
            return
        }
        
        // Original video range view behavior
        view.isEditActive = false
        restoreTimePlayerItem(view: view)
        scrollView.delegate = self
        var inset = scrollView.contentInset
        inset.left = inset.right
        UIView.animate(withDuration: 0.3) {
            /*
             if let stTime =  self.getTimeFor(view: view) {
             var rinset = stTime * self.widthPerSecond
             if rinset < inset.right {
             rinset = inset.right
             }
             inset.left = rinset
             }
             */
            self.scrollView.contentInset = inset
        }
        view.contentView.endExpand()
        endUpdate(view: view, isLeft: true)
        
        // Final ruler update when left ear trimming ends
        print("🟣 Left ear trimming ended, final ruler update")
        timeDidChanged()
    }
    
    func videoRangeView(_ view: VideoRangeView, updateRightOffset offset: CGFloat, auto: Bool) {
        // Check if this is a sticker view
        if stickerViews.contains(view) {
            // For stickers, update the width constraint to reflect new content size
            let contentWidth = view.contentView.contentWidth
            print("🔄 Sticker right ear dragged - content width: \(contentWidth), offset: \(offset)")
            updateStickerConstraints(for: view)
            
            // Update scrollview content size and auto-scroll if needed
            updateScrollViewContentSize()
            autoScrollIfNeeded(for: view)
            return
        }
        
        // Original video range view behavior
        updateCurrentClipPlayerItem(time: view.contentView.endTime, view: view)
        let center = view.convert(view.rightEar.center, to: self)
        centerLineView.center = CGPoint(x: center.x - view.rightEar.frame.size.width * 0.5, y: center.y)
        
        // Update ruler when ear moves
        print("🟣 Right ear moved, updating ruler")
        timeDidChanged()
        
        // Real-time sticker updates during video trimming
        updateStickersAfterVideoTrimming()
        
        if auto {
            var contentOffset = scrollView.contentOffset
            contentOffset.x += offset
            scrollView.setContentOffset(contentOffset, animated: false)
        } else {
            var inset = scrollView.contentInset
            inset.right = scrollView.frame.width
            scrollView.contentInset = inset
        }
    }
    
    func videoRangeViewDidEndUpdateRightOffset(_ view: VideoRangeView) {
        // Check if this is a sticker view
        if stickerViews.contains(view) {
            // For stickers, end edit state and ensure final width is correct
            let contentWidth = view.contentView.contentWidth
            print("⚙️ Sticker right ear drag ended - final content width: \(contentWidth)")
            view.isEditActive = false
            view.contentView.endExpand()
            updateStickerConstraints(for: view)
            
            // Final scrollview content size update
            updateScrollViewContentSize()
            return
        }
        
        // Original video range view behavior
        view.isEditActive = false
        restoreTimePlayerItem(view: view)
        scrollView.delegate = self
        var inset = scrollView.contentInset
        inset.right = inset.left
        UIView.animate(withDuration: 0.3) {
            self.scrollView.contentInset = inset
        }
        endUpdate(view: view, isLeft: false)
        
        // Final ruler update when right ear trimming ends  
        print("🟣 Right ear trimming ended, final ruler update")
        timeDidChanged()
    }
    
    private func endUpdate(view: VideoRangeView, isLeft: Bool) {
        if let index = rangeViews.firstIndex(of: view) {
            let track = trackItems[index]
            let timeRange = CMTimeRangeFromTimeToTime(start: view.contentView.startTime, end: view.contentView.endTime)
            if track.timeRange.start != timeRange.start || track.timeRange.duration != timeRange.duration {
                
                track.resourceTargetTimeRange = timeRange
                #warning("Update timeline data")
            }
        }
        
        // Update stickers after video trimming
        updateStickersAfterVideoTrimming()
    }
}

// MARK: - Helper

extension TimeLineView {
    
    var nextRangeViewIndex: Int {
        var index = 0
        let center = CGPoint(x: bounds.width * 0.5, y: bounds.height * 0.5)
        for (i, view) in rangeViews.enumerated() {
            let rect = view.superview!.convert(view.frame, to: centerLineView.superview!)
            if rect.contains(center) {
                if center.x - rect.origin.x < rect.maxX - center.x {
                    // On left side
                    index = i
                } else {
                    // On right side
                    index = i + 1
                }
                break
            }
        }
        
        return index
    }
    
    func showingRangeView() -> [VideoRangeView] {
        let showingRangeViews = rangeViews.filter { (view) -> Bool in
            let rect = view.superview!.convert(view.frame, to: scrollView)
            let intersects = scrollView.bounds.intersects(rect)
            return intersects
        }
        return showingRangeViews
    }
    
    func rangeView(at time: CMTime) -> VideoRangeView? {
        var duration = CMTime.zero
        for view in rangeViews {
            duration = duration + view.contentView.endTime - view.contentView.startTime - view.contentView.rightInsetDuration - view.contentView.leftInsetDuration
            if duration > time {
                return view
            }
        }
        return nil
    }
    
}

// MARK: UIScrollViewDelegate
extension TimeLineView: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isScrolling = true
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        // Update video range view
        displayRangeViewsIfNeed()
        
        let duration = adjustTime(getTime(at: scrollView.contentOffset.x).0)
        
        activeCurrentVideoRangeView(time: duration)
    }
    
    fileprivate func adjustTime(_ time: CMTime) -> CMTime {
        var res = time
        for clip in trackItems {
            let endTime = clip.timeRange.end
            if abs((time - endTime).seconds) < 0.1 {
                if (clip.resource?.duration.seconds ?? 0) <= 0.1 {
                    break
                }
                if time > endTime {
                    res = endTime + CMTime(seconds: 0.1)
                } else {
                    res = endTime - CMTime(seconds: 0.1)
                }
                break
            }
        }
        return res
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            isScrolling = false
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isScrolling = false
    }
}
