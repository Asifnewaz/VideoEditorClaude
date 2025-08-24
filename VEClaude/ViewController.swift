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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
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
        
        // Add to trackItems array
        trackItems.append(trackItem)
        
        // Show timeline and reload with track items
        timelineView.isHidden = false
        timelineView.reload(with: trackItems)
        
        print("Added video to timeline: duration = \(asset.duration.seconds)s, total videos: \(trackItems.count)")
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
        timelineView.removeAllRangeViews()
        timelineView.isHidden = true
        print("Timeline cleared")
    }
}

