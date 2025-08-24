//
//  AVAssetGeneratorExt.swift
//  VEClaude
//
//  Created by BCL Device 24 on 24/8/25.
//

import AVFoundation


extension AVAssetImageGenerator {

    static func create(fromAsset asset: AVAsset) -> AVAssetImageGenerator {
        let ge = AVAssetImageGenerator(asset: asset)
        ge.requestedTimeToleranceBefore = CMTime.zero
        ge.requestedTimeToleranceAfter = CMTime.zero
        ge.appliesPreferredTrackTransform = true
        return ge
    }
    
    func updateAspectFitSize(_ size: CGSize) {
        var maximumSize = size
        if !maximumSize.equalTo(.zero) {
            let tracks = asset.tracks(withMediaType: .video)
            if tracks.count > 0 {
                let videoTrack = tracks[0]
                let width = videoTrack.naturalSize.width
                let height = videoTrack.naturalSize.height
                var side: CGFloat
                if width > height {
                    side = maximumSize.width / height * width
                } else {
                    side = maximumSize.width / width * height
                }
                side = side * 1.0
                maximumSize = CGSize(width: side, height: side)
            }
        }
        
        self.maximumSize = maximumSize
    }
    
    func makeCopy() -> AVAssetImageGenerator {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = appliesPreferredTrackTransform
        generator.maximumSize = maximumSize
        generator.apertureMode = apertureMode
        generator.videoComposition = videoComposition
        generator.requestedTimeToleranceBefore = requestedTimeToleranceBefore
        generator.requestedTimeToleranceAfter = requestedTimeToleranceAfter
        return generator
    }
    
}
