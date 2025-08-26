//
//  AssetTrackItem.swift
//  VideoTimelineView
//
//  Created by USER on 6/29/23.
//

import AVKit

public enum AssetType {
    case image
    case video
    case audio
    case text
    case sticker
}

class AssetTrackItem: NSCopying {
    public var identifier: String
    public var resource: AVAsset?
    public var predefinedImage: UIImage? // For sticker/text types
    
    public var timeRange: CMTimeRange = .zero
    public var resourceTargetTimeRange: CMTimeRange = .zero
    public var duration: CMTime = .zero
    public var assetType: AssetType = .video
    
    public required init(resource: AVAsset) {
        identifier = ProcessInfo.processInfo.globallyUniqueString
        self.resource = resource
        updateData()
    }
    
    // Convenience initializer for sticker/text with predefined image
    public init(assetType: AssetType, predefinedImage: UIImage, duration: CMTime = CMTime(seconds: 3.0, preferredTimescale: 600)) {
        identifier = ProcessInfo.processInfo.globallyUniqueString
        self.resource = nil // No AVAsset needed for predefined content
        self.predefinedImage = predefinedImage
        self.assetType = assetType
        self.duration = duration
        timeRange = CMTimeRange(start: .zero, duration: duration)
        resourceTargetTimeRange = timeRange
    }
    
    func updateData() {
        // Only update from resource if we have one (for video/image/audio types)
        if let resource = resource {
            duration = resource.duration
            timeRange = CMTimeRange(start: .zero, duration: duration)
            resourceTargetTimeRange = timeRange
        }
        // For predefined content (sticker/text), duration is already set in initializer
    }
    
    func tracks(for type: AVMediaType) -> [AVAssetTrack] {
        return resource?.tracks(withMediaType: type) ?? []
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        let item: AssetTrackItem
        
        // Handle copying based on whether we have an AVAsset or predefined content
        if let resource = resource {
            item = type(of: self).init(resource: resource.copy() as! AVAsset)
        } else if let predefinedImage = predefinedImage {
            item = AssetTrackItem(assetType: assetType, predefinedImage: predefinedImage, duration: duration)
        } else {
            // Fallback - this shouldn't happen but creates a safe default
            item = AssetTrackItem(assetType: assetType, predefinedImage: UIImage(), duration: duration)
        }
        
        item.identifier = identifier
        item.timeRange = timeRange
        item.resourceTargetTimeRange = resourceTargetTimeRange
        item.duration = duration
        item.assetType = assetType
        item.predefinedImage = predefinedImage
        return item
    }
}

extension AssetTrackItem {
    
    func makeFullRangeCopy() -> AssetTrackItem {
        let item = self.copy() as! AssetTrackItem
        return item
    }
    
    func generateFullRangeImageGenerator(size: CGSize = .zero) -> AVAssetImageGenerator? {
        guard let resource = resource else {
            // No image generator available for predefined content
            return nil
        }
        let item = makeFullRangeCopy()
        let imageGenerator = AVAssetImageGenerator(asset: resource) //.create(from: [item], renderSize: size)
        imageGenerator.updateAspectFitSize(size)
        return imageGenerator
    }
    
}
