//
//  ImageRangeContentView.swift
//  VEClaude
//
//  Created by Claude on 26/8/25.
//

import UIKit
import AVFoundation

class ImageRangeContentView: RangeContentView {
    
    private var thumbnailImageViews: [UIImageView] = []
    private var predefinedImage: UIImage?
    private var assetType: AssetType = .sticker
    private var thumbnailSize: CGFloat = 40 // Width of each thumbnail
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupImageView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupImageView()
    }
    
    private func setupImageView() {
        // Initial setup - thumbnails will be created dynamically based on duration
        clipsToBounds = true
    }
    
    func configure(with image: UIImage, assetType: AssetType) {
        self.predefinedImage = image
        self.assetType = assetType
        
        // Set background color based on asset type
        switch assetType {
        case .sticker:
            backgroundColor = .systemOrange.withAlphaComponent(0.8)
            layer.borderColor = UIColor.systemOrange.cgColor
        case .text:
            backgroundColor = .systemBlue.withAlphaComponent(0.8)
            layer.borderColor = UIColor.systemBlue.cgColor
        default:
            backgroundColor = .systemGray.withAlphaComponent(0.8)
            layer.borderColor = UIColor.systemGray.cgColor
        }
        
        layer.cornerRadius = 6
        layer.borderWidth = 1
        
        // Create initial thumbnails
        createThumbnails()
    }
    
    private func createThumbnails() {
        guard let image = predefinedImage else { return }
        
        // Clear existing thumbnails
        thumbnailImageViews.forEach { $0.removeFromSuperview() }
        thumbnailImageViews.removeAll()
        
        // Calculate how many thumbnails we need based on content width
        let contentWidth = self.contentWidth
        let numberOfThumbnails = max(1, Int(ceil(contentWidth / thumbnailSize)))
        
        print("🖼️ Creating \(numberOfThumbnails) thumbnails for content width: \(contentWidth)")
        
        for i in 0..<numberOfThumbnails {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 4
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            addSubview(imageView)
            thumbnailImageViews.append(imageView)
            
            let xPosition = CGFloat(i) * thumbnailSize
            
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: xPosition),
                imageView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
                imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
                imageView.widthAnchor.constraint(equalToConstant: thumbnailSize)
            ])
        }
    }
    
    override func timeDidChange() {
        // ⚠️ OVERRIDE: Do NOT call super.timeDidChange() to prevent thumbnail movement
        // For stickers, thumbnails should stay in place when left ear moves
        print("🚫 Sticker timeDidChange: NOT moving thumbnails (startTime: \(startTime.seconds)s)")
        
        // Recreate thumbnails if content width changed significantly
        createThumbnails()
    }
    
    override func reloadData() {
        // For predefined images, recreate thumbnails
        if predefinedImage != nil {
            createThumbnails()
            return
        }
        super.reloadData()
    }
    
    override func updateDataIfNeed() {
        // For predefined images, recreate thumbnails if needed
        if predefinedImage != nil {
            createThumbnails()
            return
        }
        super.updateDataIfNeed()
    }
}