//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 02.02.24.
//

import Foundation
import Defaults
import Intents
import AVKit
import Defaults
import SPFoundation
import SPExtension

extension AudioPlayer {
    func startPlayback(item: PlayableItem, tracks: PlayableItem.AudioTracks, chapters: PlayableItem.Chapters, startTime: Double, playbackReporter: PlaybackReporter) {
        if tracks.isEmpty {
            return
        }
        
        stopPlayback()
        
        self.item = item
        self.tracks = tracks.sorted()
        self.chapters = chapters.sorted()
        self.playbackReporter = playbackReporter
        
        let playbackSpeed: Float?
        if let episode = item as? Episode {
            playbackSpeed = Defaults[.playbackSpeed(itemId: episode.podcastId, episodeId: episode.id)]
        } else {
            playbackSpeed = Defaults[.playbackSpeed(itemId: item.id, episodeId: nil)]
        }
        
        updateBookmarkCommand(active: item as? Audiobook != nil)
        setPlaybackRate(playbackSpeed ?? Defaults[.defaultPlaybackSpeed])
        
        Task { @MainActor in
            await seek(to: startTime)
            setPlaying(true)
            
            setupNowPlayingMetadata()
        }
        
        Task.detached {
            let intent = INPlayMediaIntent(
                mediaItems: MediaResolver.shared.convert(items: [item]),
                mediaContainer: nil,
                playShuffled: false,
                playbackRepeatMode: .none,
                resumePlayback: true,
                playbackQueueLocation: .now,
                playbackSpeed: Double(self.playbackRate),
                mediaSearch: nil)
            
            let activityType: String
            let userInfo: [String: Any]
            
            switch item {
                case is Audiobook:
                    activityType = "audiobook"
                    userInfo = [
                        "audiobookId": item.id,
                    ]
                case is Episode:
                    activityType = "episode"
                    userInfo = [
                        "episodeId": item.id,
                    ]
                default:
                    activityType = "unknown"
                    userInfo = [:]
            }
            
            let activity = NSUserActivity(activityType: "io.rfk.shelfplayer.\(activityType)")
            
            activity.title = item.name
            activity.persistentIdentifier = item.id
            activity.targetContentIdentifier = "\(activityType):\(item.id)"
            
            // Are these journal suggestions?
            activity.shortcutAvailability = [.sleepJournaling, .sleepPodcasts]
            
            activity.isEligibleForPrediction = true
            activity.userInfo = userInfo
            
            let interaction = INInteraction(intent: intent, response: INPlayMediaIntentResponse(code: .success, userActivity: activity))
            try? await interaction.donate()
        }
    }
    
    // The following functions are invoked using the computed variables
    
    func setPlaying(_ playing: Bool) {
        updateNowPlayingStatus()
        
        if playing {
            Task {
                if let lastPause = lastPause, lastPause.timeIntervalSince(Date()) <= -10 * 60 {
                    await seek(to: getItemCurrentTime() - 30)
                }
                
                lastPause = nil
                audioPlayer.play()
                updateAudioSession(active: true)
            }
        } else {
            audioPlayer.pause()
            
            if Defaults[.smartRewind] {
                lastPause = Date()
            }
        }
        
        _playing = playing
        playbackReporter?.reportProgress(playing: playing, currentTime: getItemCurrentTime(), duration: getItemDuration())
    }
    
    func setPlaybackRate(_ playbackRate: Float) {
        _playbackRate = playbackRate
        audioPlayer.defaultRate = playbackRate
        
        if let item = item {
            if let episode = item as? Episode {
                Defaults[.playbackSpeed(itemId: episode.podcastId, episodeId: episode.id)] = playbackRate
            } else {
                Defaults[.playbackSpeed(itemId: item.id, episodeId: nil)] = playbackRate
            }
        }
        
        if playing {
            audioPlayer.rate = playbackRate
        }
    }
}
 
public extension AudioPlayer {
    func stopPlayback() {
        item = nil
        tracks = []
        chapters = []
        
        playbackReporter = nil
        
        activeAudioTrackIndex = nil
        activeChapterIndex = nil
        
        audioPlayer.removeAllItems()
        
        updateAudioSession(active: false)
        clearNowPlayingMetadata()
    }
    
    func seek(to: Double, includeChapterOffset: Bool = false) async {
        if to < 0 {
            await seek(to: 0, includeChapterOffset: includeChapterOffset)
            return
        }
        
        var to = to
        if includeChapterOffset {
            to += AudioPlayer.shared.getChapter()?.start ?? 0
        }
        
        if to >= getItemDuration() && getItemDuration() > 0 {
            playbackReporter?.reportProgress(currentTime: getItemDuration(), duration: getItemDuration())
            stopPlayback()
            
            return
        } else if let index = getTrackIndex(currentTime: to) {
            if index == activeAudioTrackIndex {
                let offset = getTrack(currentTime: to)!.offset
                await audioPlayer.seek(to: CMTime(seconds: to - offset, preferredTimescale: 1000))
            } else {
                guard let item = item else { return }
                
                let resume = playing
                
                let track = getTrack(currentTime: to)!
                let queue = getQueue(currentTime: to)
                
                audioPlayer.pause()
                audioPlayer.removeAllItems()
                
                audioPlayer.insert(await getAVPlayerItem(item: item, track: track), after: nil)
                for queueTrack in queue {
                    audioPlayer.insert(await getAVPlayerItem(item: item, track: queueTrack), after: nil)
                }
                
                await audioPlayer.seek(to: CMTime(seconds: to - track.offset, preferredTimescale: 1000))
                
                activeAudioTrackIndex = index
                setPlaying(resume)
            }
        } else {
            logger.fault("Seek to position outside of range")
        }
        
        updateNowPlayingStatus()
    }
    func seek(to: Double, includeChapterOffset: Bool = false) {
        Task {
            await seek(to: to, includeChapterOffset: includeChapterOffset)
        }
    }
}
