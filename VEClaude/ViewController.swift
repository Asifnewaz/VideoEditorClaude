//
//  ViewController.swift
//  VEClaude
//
//  Created by BCL Device 24 on 21/8/25.
//

import UIKit
import AVFoundation
import MobileCoreServices

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, VideoTimelineViewDelegate {

    private var videoTimelineView: VideoTimelineView!

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
        
        videoTimelineView = VideoTimelineView()
        videoTimelineView.timelineHeight = 80 // Set custom height to 80px
        videoTimelineView.thumbnailTimeInterval = 1.0 // 1 thumbnail per second
        videoTimelineView.delegate = self
        videoTimelineView.isHidden = true // Initially hidden until video is selected
        
        videoPickerButton.translatesAutoresizingMaskIntoConstraints = false
        videoTimelineView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(videoPickerButton)
        view.addSubview(videoTimelineView)
        
        NSLayoutConstraint.activate([
            videoPickerButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            videoPickerButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            videoPickerButton.widthAnchor.constraint(equalToConstant: 200),
            videoPickerButton.heightAnchor.constraint(equalToConstant: 50),
            
            videoTimelineView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            videoTimelineView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            videoTimelineView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            videoTimelineView.heightAnchor.constraint(equalToConstant: 80)
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
        
        // Show timeline and add the video
        videoTimelineView.isHidden = false
        videoTimelineView.addVideo(from: url)
    }
    
    // MARK: - VideoTimelineViewDelegate
    func videoTimelineView(_ timelineView: VideoTimelineView, didSelectVideoAt index: Int) {
        print("Selected video at index: \(index)")
        // Handle video selection - you can add more functionality here
        // For example: show video details, enable editing options, etc.
    }
}

