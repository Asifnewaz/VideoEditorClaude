//
//  ANVideoTimeLineViewDelegate.swift
//  VEClaude
//
//  Created by BCL Device 24 on 24/8/25.
//


import UIKit
import AVFoundation
//
//protocol ANVideoTimeLineViewDelegate: AnyObject {
//    func didTapOnRangeView(_ view: ANVideoTimeLineView, tag: Int)
//    func timeLineViewBeginUpdateLeft(_ view: ANVideoRangeView)
//    func timeLineViewView(_ view: ANVideoRangeView, updateLeftOffset offset: CGFloat, auto: Bool)
//    func timeLineViewDidEndUpdateLeftOffset(_ view: ANVideoTimeLineView, rview: ANVideoRangeView)
//    
//    func timeLineViewBeginUpdateRight(_ view: ANVideoRangeView)
//    func timeLineViewView(_ view: ANVideoRangeView, updateRightOffset offset: CGFloat, auto: Bool)
//    func timeLineViewDidEndUpdateRightOffset(_ view: ANVideoRangeView)
//}
//
//
//class ANVideoTimeLineView: UIView {
//
//    private(set) var contentView: UIView!
//    private(set) var totalTimeLabel: UILabel!
//
//    private(set) var rangeViews: [ANVideoRangeView] = []
//    private(set) var trackItem: AssetTrackItem?
//
//    var isEditActive: Bool {
//        get {
//            if let fRangeView = rangeViews.first {
//                return fRangeView.isEditActive
//            }
//            return false
//        }
//    }
//
//    weak var delegate: ANVideoTimeLineViewDelegate?
//
//
//    var videoRangeViewEarWidth: CGFloat
//    var widthPerSecond: CGFloat
//
//    var renderSize: CGSize = {
//        let width = UIScreen.main.bounds.width * 1.0
//        let height: CGFloat = round(width * 0.5625)
//        return CGSize.init(width: width, height: height)
//    }()
//
//
//    init(frame: CGRect, videoRangeViewEarWidth: CGFloat, widthPerSecond: CGFloat) {
//        self.videoRangeViewEarWidth = videoRangeViewEarWidth
//        self.widthPerSecond = widthPerSecond
//        super.init(frame: frame)
//        commonInit()
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        self.videoRangeViewEarWidth = 24.0
//        self.widthPerSecond = 60.0
//        super.init(coder: aDecoder)
//        commonInit()
//    }
//
//    func commonInit() {
//        contentView = UIView()
//        contentView.frame = self.bounds
//        contentView.backgroundColor = .clear
//        self.addSubview(contentView)
//
//        totalTimeLabel = UILabel()
//        addSubview(totalTimeLabel)
//        totalTimeLabel.textColor = UIColor.white
//        totalTimeLabel.font = UIFont.systemFont(ofSize: 16)
//
//        totalTimeLabel.translatesAutoresizingMaskIntoConstraints = false
//        let timeLabelRightConstraint = totalTimeLabel.rightAnchor.constraint(equalTo: rightAnchor)
//        timeLabelRightConstraint.constant = -15
//        timeLabelRightConstraint.isActive = true
//        let timeLabelBottomConstraint = totalTimeLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
//        timeLabelBottomConstraint.constant = -10
//        timeLabelBottomConstraint.isActive = true
//
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapLineViewAction(_:)))
//        addGestureRecognizer(tapGesture)
//    }
//
//    // MARK: - Actions
//
//    @objc private func tapContentAction(_ recognizer: UITapGestureRecognizer) {
//        if recognizer.state == .ended {
//            if let view = recognizer.view as? ANVideoRangeView, !view.isEditActive {
//                view.superview?.bringSubviewToFront(view)
//                view.isEditActive = true
//                rangeViews.filter({ $0 != view && $0.isEditActive }).forEach({ $0.isEditActive = false })
//            }
//        }
//        self.delegate?.didTapOnRangeView(self, tag: self.tag)
//    }
//
//    func selectTimelineTestView(select: Bool){
//        self.rangeViews.first?.isEditActive = select
//    }
//
//    @objc private func tapLineViewAction(_ recognizer: UITapGestureRecognizer) {
//        let point = recognizer.location(in: recognizer.view)
//        var tapOnVideoRangeView = false
//        for view in rangeViews {
//            let rect = view.superview!.convert(view.frame, to: self)
//            if rect.contains(point) {
//                tapOnVideoRangeView = true
//                break
//            }
//        }
//        if !tapOnVideoRangeView {
//            resignVideoRangeView()
//        }
//    }
//
//    // MARK: - Data
//
//    private let loadImageQueue: DispatchQueue = DispatchQueue(label: "com.videocat.loadimage")
//    func reload(with trackItem: AssetTrackItem) {
//        self.trackItem = trackItem
//        removeAllRangeViews()
//
//        appendVideoRangeView(configuration: { (rangeView) in
//            let contentView = VideoRangeContentView(frame: rangeView.bounds)
//            if trackItem.assetType == .image {
//                contentView.supportUnlimitTime = true
//            }
//            let timeRange = trackItem.resourceTargetTimeRange
//            contentView.loadImageQueue = loadImageQueue
//            if let imageGenerator = trackItem.generateFullRangeImageGenerator(size: renderSize) {
//                contentView.imageGenerator = ImageGenerator.createFrom(imageGenerator)
//            }
//            contentView.startTime = timeRange.start
//            contentView.endTime = timeRange.end
//
//
//            rangeView.loadContentView(contentView)
//
//            rangeView.reloadUI()
//        })
//
//    }
//
//    func resignVideoRangeView() {
//        rangeViews.filter({ $0.isEditActive }).forEach({ $0.isEditActive = false })
//    }
//
//    func appendVideoRangeView(configuration: (ANVideoRangeView) -> Void, at index: Int = Int.max) {
//        let videoRangeView = ANVideoRangeView(frame: self.bounds, videoRangeViewEarWidth: videoRangeViewEarWidth)
//        configuration(videoRangeView)
//        videoRangeView.contentView.widthPerSecond = widthPerSecond
//        videoRangeView.contentInset = UIEdgeInsets(top: 2, left: videoRangeViewEarWidth, bottom: 2, right: videoRangeViewEarWidth)
//        videoRangeView.delegate = self
//        videoRangeView.isEditActive = false
//        let tapContentGesture = UITapGestureRecognizer(target: self, action: #selector(tapContentAction(_:)))
//        videoRangeView.addGestureRecognizer(tapContentGesture)
//        contentView.insertSubview(videoRangeView, at: 0)
//
//        videoRangeView.frame = self.contentView.bounds
//        rangeViews.append(videoRangeView)
//    }
//
//    func removeAllRangeViews() {
//        rangeViews.forEach { (view) in
//            view.removeFromSuperview()
//        }
//        rangeViews.removeAll()
//    }
//
//
//    fileprivate func timeDidChanged() {
//        var duration: CGFloat = 0
//        rangeViews.forEach { (view) in
//            duration = duration + view.frame.size.width / widthPerSecond
//        }
//        totalTimeLabel.text = String.init(format: "%.1f", duration)
//    }
//
//}
//
//// MARK: - VideoRangeViewDelegate
//
//extension ANVideoTimeLineView: ANVideoRangeViewDelegate {
//
//    func videoRangeViewBeginUpdateLeft(_ view: ANVideoRangeView) {
//        self.delegate?.timeLineViewBeginUpdateLeft(view)
//    }
//
//    func videoRangeViewBeginUpdateRight(_ view: ANVideoRangeView) {
//        self.delegate?.timeLineViewBeginUpdateRight(view)
//    }
//
//    func videoRangeView(_ view: ANVideoRangeView, updateLeftOffset offset: CGFloat, auto: Bool) {
//        /*
//         //OLD
//         if auto { return }
//         */
//        var sFrame = self.frame
//        sFrame.origin.x += (offset)
//        sFrame.size.width -= (offset)
//        self.frame = sFrame
//
//        var cFrame = self.contentView.frame
//        cFrame.size.width -= (offset)
//        self.contentView.frame = cFrame
//
//        if auto { //OLD -- there was not check for this delegate
//            self.delegate?.timeLineViewView(view, updateLeftOffset: offset, auto: auto)
//        }
//    }
//
//    func videoRangeViewDidEndUpdateLeftOffset(_ view: ANVideoRangeView) {
//        self.delegate?.timeLineViewDidEndUpdateLeftOffset(self, rview: view)
//        view.contentView.endExpand()
//        endUpdate(view: view, isLeft: true)
//    }
//
//    func videoRangeView(_ view: ANVideoRangeView, updateRightOffset offset: CGFloat, auto: Bool) {
//        var sFrame = self.frame
//        sFrame.size.width += (offset)
//        self.frame = sFrame
//        
//        var cFrame = self.contentView.frame
//        cFrame.size.width += (offset)
//        self.contentView.frame = cFrame
//
//        self.delegate?.timeLineViewView(view, updateRightOffset: offset, auto: auto)
//    }
//
//    func videoRangeViewDidEndUpdateRightOffset(_ view: ANVideoRangeView) {
//        self.delegate?.timeLineViewDidEndUpdateRightOffset(view)
//        endUpdate(view: view, isLeft: false)
//    }
//
//    func getTimeFor(view: ANVideoRangeView, isLeft: Bool) -> Double? {
//        let timeRange = CMTimeRangeFromTimeToTime(start: view.contentView.startTime, end: view.contentView.endTime)
//        return timeRange.start.seconds
//    }
//
//    private func endUpdate(view: ANVideoRangeView, isLeft: Bool) {
//        if let track = trackItem {
//            let timeRange = CMTimeRangeFromTimeToTime(start: view.contentView.startTime, end: view.contentView.endTime)
//            if track.timeRange.start != timeRange.start || track.timeRange.duration != timeRange.duration {
//
//                track.resourceTargetTimeRange = timeRange
//            }
//        }
//    }
//}
