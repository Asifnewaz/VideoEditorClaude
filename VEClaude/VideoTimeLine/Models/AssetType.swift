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
    public var resource: AVAsset
    
    public var timeRange: CMTimeRange = .zero
    public var resourceTargetTimeRange: CMTimeRange = .zero
    public var duration: CMTime = .zero
    public var assetType: AssetType = .video
    
    public required init(resource: AVAsset) {
        identifier = ProcessInfo.processInfo.globallyUniqueString
        self.resource = resource
        updateData()
    }
    
    func updateData() {
        duration = resource.duration
        timeRange =  CMTimeRange(start: .zero, duration: duration)
        resourceTargetTimeRange =  timeRange
    }
    
    func tracks(for type: AVMediaType) -> [AVAssetTrack] {
        return resource.tracks(withMediaType: type)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        let item = type(of: self).init(resource: resource.copy() as! AVAsset)
        item.identifier = identifier
        item.timeRange = timeRange
        item.resourceTargetTimeRange = resourceTargetTimeRange
        item.duration = duration
        item.assetType = assetType
        return item
    }
}

extension AssetTrackItem {
    
    func makeFullRangeCopy() -> AssetTrackItem {
        let item = self.copy() as! AssetTrackItem
        return item
    }
    
    func generateFullRangeImageGenerator(size: CGSize = .zero) -> AVAssetImageGenerator? {
        let item = makeFullRangeCopy()
        let imageGenerator = AVAssetImageGenerator(asset: item.resource) //.create(from: [item], renderSize: size)
        imageGenerator.updateAspectFitSize(size)
        return imageGenerator
    }
    
}
