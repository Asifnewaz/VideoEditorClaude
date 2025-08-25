//
//  TimelineDataModel.swift
//  VEClaude
//
//  Created by BCL Device 24 on 25/8/25.
//

import UIKit
import AVFoundation

// MARK: - Video Track Info
struct VideoTrackInfo {
    let trackID: CMPersistentTrackID
    let asset: AVAsset
    let naturalSize: CGSize
    let preferredTransform: CGAffineTransform
    let originalDuration: CMTime
    let frameRate: Float
    let mediaType: AVMediaType
    
    init(from avAssetTrack: AVAssetTrack, asset: AVAsset) {
        self.trackID = avAssetTrack.trackID
        self.asset = asset
        self.naturalSize = avAssetTrack.naturalSize
        self.preferredTransform = avAssetTrack.preferredTransform
        self.originalDuration = avAssetTrack.timeRange.duration
        self.frameRate = avAssetTrack.nominalFrameRate
        self.mediaType = avAssetTrack.mediaType
    }
    
    // MARK: - Test Helper
    #if DEBUG
    static func createMockTrackInfo(asset: AVAsset) -> VideoTrackInfo {
        return VideoTrackInfo(
            trackID: 1,
            asset: asset,
            naturalSize: CGSize(width: 1920, height: 1080),
            preferredTransform: .identity,
            originalDuration: CMTime(seconds: 10.0, preferredTimescale: 600),
            frameRate: 30.0,
            mediaType: .video
        )
    }
    
    private init(trackID: CMPersistentTrackID, asset: AVAsset, naturalSize: CGSize, preferredTransform: CGAffineTransform, originalDuration: CMTime, frameRate: Float, mediaType: AVMediaType) {
        self.trackID = trackID
        self.asset = asset
        self.naturalSize = naturalSize
        self.preferredTransform = preferredTransform
        self.originalDuration = originalDuration
        self.frameRate = frameRate
        self.mediaType = mediaType
    }
    #endif
}

// MARK: - Timeline Track
class TimelineTrack {
    let id: UUID
    let trackInfo: VideoTrackInfo
    
    // Timeline positioning
    var timeRange: CMTimeRange
    var positionInTimeline: CMTime
    
    // Cropping/trimming
    var cropStartTime: CMTime
    var cropEndTime: CMTime
    
    // Computed properties
    var croppedDuration: CMTime {
        return CMTimeSubtract(cropEndTime, cropStartTime)
    }
    
    var endTimeInTimeline: CMTime {
        return CMTimeAdd(positionInTimeline, croppedDuration)
    }
    
    var isValid: Bool {
        return CMTIME_IS_VALID(cropStartTime) && 
               CMTIME_IS_VALID(cropEndTime) && 
               CMTIME_IS_VALID(positionInTimeline) &&
               CMTimeCompare(cropEndTime, cropStartTime) > 0
    }
    
    init(trackInfo: VideoTrackInfo, positionInTimeline: CMTime = CMTime.zero) {
        self.id = UUID()
        self.trackInfo = trackInfo
        self.positionInTimeline = positionInTimeline
        
        // Default to full duration
        self.cropStartTime = CMTime.zero
        self.cropEndTime = trackInfo.originalDuration
        let duration = CMTimeSubtract(self.cropEndTime, self.cropStartTime)
        self.timeRange = CMTimeRange(start: cropStartTime, duration: duration)
    }
    
    init(trackInfo: VideoTrackInfo, 
         cropStartTime: CMTime, 
         cropEndTime: CMTime, 
         positionInTimeline: CMTime) {
        self.id = UUID()
        self.trackInfo = trackInfo
        self.cropStartTime = cropStartTime
        self.cropEndTime = cropEndTime
        self.positionInTimeline = positionInTimeline
        let duration = CMTimeSubtract(cropEndTime, cropStartTime)
        self.timeRange = CMTimeRange(start: cropStartTime, duration: duration)
    }
    
    func updateCropRange(startTime: CMTime, endTime: CMTime) {
        guard CMTimeCompare(endTime, startTime) > 0,
              CMTimeCompare(startTime, CMTime.zero) >= 0,
              CMTimeCompare(endTime, trackInfo.originalDuration) <= 0 else {
            return
        }
        
        self.cropStartTime = startTime
        self.cropEndTime = endTime
        self.timeRange = CMTimeRange(start: startTime, duration: croppedDuration)
    }
    
    func moveToPosition(_ position: CMTime) {
        guard CMTIME_IS_VALID(position) && CMTimeCompare(position, CMTime.zero) >= 0 else {
            return
        }
        self.positionInTimeline = position
    }
}

// MARK: - Timeline Data Model
class TimelineDataModel {
    private(set) var tracks: [TimelineTrack] = []
    
    // Computed properties
    var totalDuration: CMTime {
        guard !tracks.isEmpty else { return CMTime.zero }
        
        let lastEndTime = tracks.map { $0.endTimeInTimeline }.max { 
            CMTimeCompare($0, $1) < 0 
        }
        return lastEndTime ?? CMTime.zero
    }
    
    var trackCount: Int {
        return tracks.count
    }
    
    var isEmpty: Bool {
        return tracks.isEmpty
    }
    
    // MARK: - Track Management
    
    func addTrack(_ track: TimelineTrack) {
        tracks.append(track)
        notifyDataChanged()
    }
    
    func addTrack(from asset: AVAsset, at position: CMTime = CMTime.zero) {
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            return
        }
        
        let trackInfo = VideoTrackInfo(from: videoTrack, asset: asset)
        let timelineTrack = TimelineTrack(trackInfo: trackInfo, positionInTimeline: position)
        addTrack(timelineTrack)
    }
    
    func removeTrack(withId id: UUID) {
        tracks.removeAll { $0.id == id }
        notifyDataChanged()
    }
    
    func removeTrack(at index: Int) {
        guard index >= 0 && index < tracks.count else { return }
        tracks.remove(at: index)
        notifyDataChanged()
    }
    
    func getTrack(withId id: UUID) -> TimelineTrack? {
        return tracks.first { $0.id == id }
    }
    
    func getTrack(at index: Int) -> TimelineTrack? {
        guard index >= 0 && index < tracks.count else { return nil }
        return tracks[index]
    }
    
    // MARK: - Timeline Operations
    
    func moveTrack(withId id: UUID, to position: CMTime) {
        guard let track = getTrack(withId: id) else { return }
        track.moveToPosition(position)
        notifyDataChanged()
    }
    
    func updateTrackCropRange(trackId: UUID, startTime: CMTime, endTime: CMTime) {
        guard let track = getTrack(withId: trackId) else { return }
        track.updateCropRange(startTime: startTime, endTime: endTime)
        notifyDataChanged()
    }
    
    func getTracksAtTime(_ time: CMTime) -> [TimelineTrack] {
        return tracks.filter { track in
            let startTime = track.positionInTimeline
            let endTime = track.endTimeInTimeline
            return CMTimeRangeContainsTime(CMTimeRange(start: startTime, end: endTime), time: time)
        }
    }
    
    // MARK: - Validation
    
    func validateTimeline() -> [String] {
        var issues: [String] = []
        
        for (index, track) in tracks.enumerated() {
            if !track.isValid {
                issues.append("Track \(index) has invalid time configuration")
            }
            
            if CMTimeCompare(track.positionInTimeline, CMTime.zero) < 0 {
                issues.append("Track \(index) has negative position")
            }
            
            if CMTimeCompare(track.cropStartTime, CMTime.zero) < 0 {
                issues.append("Track \(index) has negative crop start time")
            }
            
            if CMTimeCompare(track.cropEndTime, track.trackInfo.originalDuration) > 0 {
                issues.append("Track \(index) crop end time exceeds original duration")
            }
        }
        
        return issues
    }
    
    // MARK: - Notifications
    
    static let dataChangedNotification = Notification.Name("TimelineDataModelChanged")
    
    private func notifyDataChanged() {
        NotificationCenter.default.post(name: Self.dataChangedNotification, object: self)
    }
    
    // MARK: - Clear
    
    func clearAllTracks() {
        tracks.removeAll()
        notifyDataChanged()
    }
}

// MARK: - Extensions

extension CMTimeRange {
    init(start: CMTime, end: CMTime) {
        let duration = CMTimeSubtract(end, start)
        self.init(start: start, duration: duration)
    }
}

extension TimelineDataModel: CustomStringConvertible {
    var description: String {
        let trackDescriptions = tracks.enumerated().map { index, track in
            return "Track \(index): pos=\(track.positionInTimeline.seconds)s, crop=\(track.cropStartTime.seconds)s-\(track.cropEndTime.seconds)s, duration=\(track.croppedDuration.seconds)s"
        }.joined(separator: "\n")
        
        return """
        TimelineDataModel:
        Total Duration: \(totalDuration.seconds)s
        Track Count: \(trackCount)
        Tracks:
        \(trackDescriptions)
        """
    }
}
