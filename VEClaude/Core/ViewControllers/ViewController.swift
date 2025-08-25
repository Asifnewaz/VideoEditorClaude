//
//  ViewController.swift
//  VEClaude
//
//  Created by BCL Device 24 on 21/8/25.
//

import UIKit
import AVFoundation
import MobileCoreServices

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private var timelineView: TimeLineView!
    private var trackItems: [AssetTrackItem] = []
    
    // Timeline Data Model
    private let timelineDataModel = TimelineDataModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTimelineDataModelObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupUI() {
        let videoPickerButton = UIButton(type: .system)
        videoPickerButton.setTitle("Select Video", for: .normal)
        videoPickerButton.backgroundColor = .systemBlue
        videoPickerButton.setTitleColor(.white, for: .normal)
        videoPickerButton.layer.cornerRadius = 8
        videoPickerButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        videoPickerButton.addTarget(self, action: #selector(selectVideoButtonTapped), for: .touchUpInside)
        
        // Initialize professional TimeLineView
        timelineView = TimeLineView()
        timelineView.backgroundColor = .systemGray6
        timelineView.layer.cornerRadius = 8
        timelineView.layer.borderWidth = 1
        timelineView.layer.borderColor = UIColor.systemGray4.cgColor
        timelineView.isHidden = true // Initially hidden until video is selected
        
        videoPickerButton.translatesAutoresizingMaskIntoConstraints = false
        timelineView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(videoPickerButton)
        view.addSubview(timelineView)
        
        NSLayoutConstraint.activate([
            videoPickerButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            videoPickerButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            videoPickerButton.widthAnchor.constraint(equalToConstant: 200),
            videoPickerButton.heightAnchor.constraint(equalToConstant: 50),
            
            timelineView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            timelineView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            timelineView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            timelineView.heightAnchor.constraint(equalToConstant: 120) // Increased height for ruler
        ])
    }
    
    @objc private func selectVideoButtonTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [kUTTypeMovie as String]
        imagePicker.videoQuality = .typeHigh
        imagePicker.allowsEditing = false
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let videoURL = info[.mediaURL] as? URL {
            print("Selected video URL: \(videoURL)")
            // Handle the selected video here
            handleSelectedVideo(url: videoURL)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    private func handleSelectedVideo(url: URL) {
        print("Video selected successfully: \(url.lastPathComponent)")
        
        // Create AssetTrackItem from video URL
        let asset = AVAsset(url: url)
        let trackItem = AssetTrackItem(resource: asset)
        trackItem.assetType = .video
        
        // Add to trackItems array (for existing timeline view)
        trackItems.append(trackItem)
        
        // Add to new data model
        let currentPosition = timelineDataModel.totalDuration
        timelineDataModel.addTrack(from: asset, at: currentPosition)
        
        // Show timeline and reload with track items
        timelineView.isHidden = false
        timelineView.reload(with: trackItems)
        
        print("Added video to timeline: duration = \(asset.duration.seconds)s, total videos: \(trackItems.count)")
        print("Timeline data model: \(timelineDataModel.description)")
    }
    
    // MARK: - Helper Methods
    
    func addMultipleVideos(_ urls: [URL]) {
        for url in urls {
            let asset = AVAsset(url: url)
            let trackItem = AssetTrackItem(resource: asset)
            trackItem.assetType = .video
            trackItems.append(trackItem)
        }
        
        timelineView.isHidden = false
        timelineView.reload(with: trackItems)
        
        print("Added \(urls.count) videos to timeline, total: \(trackItems.count)")
    }
    
    func clearTimeline() {
        trackItems.removeAll()
        timelineDataModel.clearAllTracks()
        timelineView.removeAllRangeViews()
        timelineView.isHidden = true
        print("Timeline cleared")
    }
    
    // MARK: - Timeline Data Model Integration
    
    private func setupTimelineDataModelObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(timelineDataModelChanged(_:)),
            name: TimelineDataModel.dataChangedNotification,
            object: nil
        )
    }
    
    @objc private func timelineDataModelChanged(_ notification: Notification) {
        guard let dataModel = notification.object as? TimelineDataModel else { return }
        
        print("Timeline data model updated:")
        print("- Total Duration: \(dataModel.totalDuration.seconds)s")
        print("- Track Count: \(dataModel.trackCount)")
        print("- Is Empty: \(dataModel.isEmpty)")
        
        // Update UI or perform other actions based on data model changes
        updateUIFromDataModel(dataModel)
    }
    
    private func updateUIFromDataModel(_ dataModel: TimelineDataModel) {
        // Example: Update timeline view based on data model
        // You can access all track information here
        
        for (index, track) in dataModel.tracks.enumerated() {
            print("Track \(index):")
            print("  - Position: \(track.positionInTimeline.seconds)s")
            print("  - Crop Range: \(track.cropStartTime.seconds)s - \(track.cropEndTime.seconds)s")
            print("  - Cropped Duration: \(track.croppedDuration.seconds)s")
            print("  - Original Duration: \(track.trackInfo.originalDuration.seconds)s")
            print("  - Natural Size: \(track.trackInfo.naturalSize)")
        }
    }
    
    // MARK: - Data Model Access Methods
    
    func getCurrentTimelineData() -> TimelineDataModel {
        return timelineDataModel
    }
    
    func getTrackAtIndex(_ index: Int) -> TimelineTrack? {
        return timelineDataModel.getTrack(at: index)
    }
    
    func getTracksAtTime(_ time: CMTime) -> [TimelineTrack] {
        return timelineDataModel.getTracksAtTime(time)
    }
    
    func updateTrackCropRange(trackIndex: Int, startTime: CMTime, endTime: CMTime) {
        guard let track = timelineDataModel.getTrack(at: trackIndex) else { return }
        timelineDataModel.updateTrackCropRange(trackId: track.id, startTime: startTime, endTime: endTime)
    }
    
    func moveTrack(at index: Int, to position: CMTime) {
        guard let track = timelineDataModel.getTrack(at: index) else { return }
        timelineDataModel.moveTrack(withId: track.id, to: position)
    }
    
    func validateCurrentTimeline() -> [String] {
        return timelineDataModel.validateTimeline()
    }
}

