import Foundation
import AVFoundation
import MediaPlayer
import UIKit
import Combine
import os

class AudioPlayerService: NSObject, ObservableObject, AVPlayerItemMetadataOutputPushDelegate {
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTrack: Track?
    @Published private(set) var isBuffering = false

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var metadataOutput: AVPlayerItemMetadataOutput?
    private var timeObserverToken: Any?
    private var statusObserver: NSKeyValueObservation?

    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var isAudioSessionActive = false
    private var currentStation: Station?
    private var needsRestart = false

    override init() {
        super.init()
        setupAudioSession()
        setupBackgroundPlayback()
    }

    // MARK: - Audio Session Configuration

    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()

            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.allowAirPlay, .allowBluetooth, .mixWithOthers]
            )

            try audioSession.setPreferredIOBufferDuration(AppSettings.preferredIOBufferDuration)
            try audioSession.setPreferredSampleRate(AppSettings.preferredSampleRate)
            try audioSession.setActive(true, options: [.notifyOthersOnDeactivation])

            isAudioSessionActive = true
        } catch {
            Logger.log("Audio session setup failed: \(error)", category: .audio, type: .error)
            isAudioSessionActive = false
        }
    }

    // MARK: - Background Playback Setup

    private func setupBackgroundPlayback() {
        setupRemoteTransportControls()

        let notificationCenter = NotificationCenter.default

        notificationCenter.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(handleAppWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    // MARK: - App Lifecycle Handlers

    @objc private func handleAppDidEnterBackground() {
        beginBackgroundTask()
        if isPlaying {
            ensurePlaybackContinues()
        }
    }

    @objc private func handleAppWillEnterForeground() {
        endBackgroundTask()

        if isPlaying && player?.timeControlStatus != .playing {
            player?.play()
        }

        if needsRestart, let station = currentStation {
            needsRestart = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.play(station: station)
            }
        }

        objectWillChange.send()
    }

    @objc private func handleAppWillTerminate() {
        endBackgroundTask()
    }

    private func beginBackgroundTask() {
        endBackgroundTask()

        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }

    private func ensurePlaybackContinues() {
        if !isAudioSessionActive {
            setupAudioSession()
        }

        if let player = player {
            if player.timeControlStatus != .playing && isPlaying {
                player.play()
            }
        } else if isPlaying, let station = currentStation {
            needsRestart = true
        }
    }

    // MARK: - Audio Interruption Handlers

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            player?.pause()
            isAudioSessionActive = false

        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
               AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) {

                setupAudioSession()

                if isPlaying {
                    player?.play()
                }
            }

        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let _ = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        if isPlaying {
            ensurePlaybackContinues()
        }
    }

    // MARK: - Playback Control

    func metadataOutput(_ output: AVPlayerItemMetadataOutput, didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup], from track: AVPlayerItemTrack?) {
        if let group = groups.first,
           let metadataItem = group.items.first,
           let value = metadataItem.value as? String {
            parseStreamTitle(value)
        }
    }

    func play(station: Station) {
        let streamURL = station.streamURL
        guard let url = URL(string: streamURL) else {
            Logger.log("Invalid URL: \(streamURL)", category: .audio, type: .error)
            return
        }

        currentStation = station
        stop()

        if !isAudioSessionActive {
            setupAudioSession()
        }

        beginBackgroundTask()
        isBuffering = true

        let asset = AVURLAsset(url: url, options: [
            "AVURLAssetHTTPHeaderFieldsKey": [
                "User-Agent": "RadioPlay/1.0",
                "Icy-MetaData": "1"
            ],
            AVURLAssetPreferPreciseDurationAndTimingKey: false,
            AVURLAssetHTTPCookiesKey: [] as [HTTPCookie]
        ])

        Task {
            do {
                let isPlayable = try await asset.load(.isPlayable)

                guard isPlayable else {
                    await MainActor.run {
                        self.isBuffering = false
                    }
                    return
                }

                await MainActor.run {
                    self.playerItem = AVPlayerItem(asset: asset)
                    self.playerItem?.preferredForwardBufferDuration = AppSettings.preferredForwardBufferDuration
                    self.playerItem?.canUseNetworkResourcesForLiveStreamingWhilePaused = true

                    self.statusObserver = self.playerItem?.observe(\.status, options: [.new]) { [weak self] item, _ in
                        guard let self = self else { return }

                        switch item.status {
                        case .readyToPlay:
                            self.isBuffering = false

                            if self.isPlaying && self.player?.rate == 0 {
                                self.player?.play()
                            }

                        case .failed:
                            self.isBuffering = false

                            if self.isPlaying {
                                self.needsRestart = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    if self.needsRestart, let station = self.currentStation {
                                        self.needsRestart = false
                                        self.play(station: station)
                                    }
                                }
                            }

                        case .unknown:
                            break

                        @unknown default:
                            break
                        }
                    }

                    self.player = AVPlayer(playerItem: self.playerItem)
                    self.player?.automaticallyWaitsToMinimizeStalling = true
                    self.player?.volume = 1.0

                    if #available(iOS 16.0, *) {
                        self.player?.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible
                        self.player?.preventsDisplaySleepDuringVideoPlayback = false
                    }

                    self.player?.allowsExternalPlayback = true

                    self.setupMetadataObservers()
                    self.setupPlaybackObserver()
                    self.setupBufferObservers()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.player?.play()
                        self.isPlaying = true

                        self.currentTrack = Track(title: station.subtitle, artist: station.name, album: nil)
                        self.updateNowPlayingInfo()
                    }
                }
            } catch {
                await MainActor.run {
                    Logger.log("Asset loading error: \(error)", category: .audio, type: .error)
                    self.isBuffering = false
                }
            }
        }
    }

    func togglePlayPause() {
        if isPlaying {
            player?.pause()
            isPlaying = false

            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                if !self.isPlaying {
                    self.endBackgroundTask()
                }
            }
        } else {
            if !isAudioSessionActive {
                setupAudioSession()
            }

            beginBackgroundTask()

            if let player = player {
                player.play()
                isPlaying = true
            } else if let station = currentStation {
                play(station: station)
            }
        }

        updateNowPlayingInfo()
    }

    func stop() {
        if let item = playerItem {
            item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
            item.removeObserver(self, forKeyPath: "playbackBufferEmpty")
            item.removeObserver(self, forKeyPath: "playbackBufferFull")
        }

        statusObserver?.invalidate()
        statusObserver = nil

        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }

        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        playerItem = nil

        isPlaying = false
        isBuffering = false
        needsRestart = false

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.endBackgroundTask()
        }
    }

    // MARK: - Playback Observers

    private func setupPlaybackObserver() {
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }

        timeObserverToken = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 2.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }

            if self.isPlaying {
                if let player = self.player, player.timeControlStatus == .paused && !self.isBuffering {
                    player.play()
                }

                if !self.isAudioSessionActive {
                    self.setupAudioSession()
                }
            }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlaybackStalled),
            name: .AVPlayerItemPlaybackStalled,
            object: playerItem
        )
    }

    @objc private func handlePlaybackStalled(notification: Notification) {
        isBuffering = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }

            if self.isPlaying && self.player?.timeControlStatus != .playing {
                self.player?.play()
            }

            self.isBuffering = false
        }
    }

    private func setupBufferObservers() {
        guard let playerItem = playerItem else { return }

        playerItem.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: [.new], context: nil)
        playerItem.addObserver(self, forKeyPath: "playbackBufferEmpty", options: [.new], context: nil)
        playerItem.addObserver(self, forKeyPath: "playbackBufferFull", options: [.new], context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let item = object as? AVPlayerItem else { return }

        switch keyPath {
        case "playbackLikelyToKeepUp":
            if item.isPlaybackLikelyToKeepUp {
                isBuffering = false
                if isPlaying && player?.rate == 0 {
                    player?.play()
                }
            }

        case "playbackBufferEmpty":
            if item.isPlaybackBufferEmpty {
                isBuffering = true
            }

        case "playbackBufferFull":
            break

        default:
            break
        }
    }

    // MARK: - Metadata Handling

    private func setupMetadataObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMetadataUpdate),
            name: .AVPlayerItemNewAccessLogEntry,
            object: playerItem
        )

        metadataOutput = AVPlayerItemMetadataOutput(identifiers: nil)
        metadataOutput?.setDelegate(self, queue: DispatchQueue.main)
        playerItem?.add(metadataOutput!)
    }

    @objc private func handleMetadataUpdate(notification: Notification) {
        guard let playerItem = player?.currentItem else { return }

        if let metadataList = playerItem.timedMetadata {
            for item in metadataList {
                if let streamTitle = item.value as? String {
                    parseStreamTitle(streamTitle)
                    break
                }
            }
        }
    }

    private func parseStreamTitle(_ streamTitle: String) {
        guard let station = currentStation, station.useStreamMetadata else {
            return
        }

        var cleanTitle = streamTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        if let sectionIndex = cleanTitle.firstIndex(of: "§") {
            cleanTitle = String(cleanTitle[..<sectionIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        cleanTitle = cleanTitle.replacingOccurrences(
            of: "\\s*\\d{6,}\\s*",
            with: " ",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        cleanTitle = cleanTitle.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )

        let invalidTitles = ["true", "false", "null", "unknown", "n/a", "-", ""]

        guard !invalidTitles.contains(cleanTitle.lowercased()) else {
            return
        }

        let components = cleanTitle.components(separatedBy: " - ")

        if components.count >= 2 {
            var artist = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
            var title = components[1].trimmingCharacters(in: .whitespacesAndNewlines)

            if let sectionIndex = artist.firstIndex(of: "§") {
                artist = String(artist[..<sectionIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if let sectionIndex = title.firstIndex(of: "§") {
                title = String(title[..<sectionIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            }

            guard !artist.isEmpty && !title.isEmpty &&
                  !invalidTitles.contains(artist.lowercased()) &&
                  !invalidTitles.contains(title.lowercased()) else {
                return
            }

            currentTrack = Track(title: title, artist: artist, album: nil)
        } else if cleanTitle.count > 3 {
            currentTrack = Track(title: cleanTitle, artist: "", album: nil)
        }

        updateNowPlayingInfo()

        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    // MARK: - Remote Control

    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)

        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }

            if !self.isPlaying {
                if !self.isAudioSessionActive {
                    self.setupAudioSession()
                }

                self.beginBackgroundTask()

                if let player = self.player {
                    player.play()
                    self.isPlaying = true
                    return .success
                } else if let station = self.currentStation {
                    self.play(station: station)
                    return .success
                }
            }

            return .commandFailed
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }

            if self.isPlaying {
                self.player?.pause()
                self.isPlaying = false
                return .success
            }

            return .commandFailed
        }

        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }

            self.togglePlayPause()
            return .success
        }
    }

    private func updateNowPlayingInfo() {
        guard let station = currentStation else { return }

        var nowPlayingInfo = [String: Any]()

        if let track = currentTrack, !track.title.isEmpty {
            nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
            nowPlayingInfo[MPMediaItemPropertyArtist] = track.artist.isEmpty ? station.name : track.artist
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = station.subtitle
        } else {
            nowPlayingInfo[MPMediaItemPropertyTitle] = station.name
            nowPlayingInfo[MPMediaItemPropertyArtist] = station.subtitle
        }

        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = true
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = 0
        nowPlayingInfo[MPMediaItemPropertyMediaType] = MPMediaType.anyAudio.rawValue

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

        loadArtworkForNowPlaying(station: station, baseInfo: nowPlayingInfo)
    }

    private func loadArtworkForNowPlaying(station: Station, baseInfo: [String: Any]) {
        if let track = currentTrack, !track.title.isEmpty {
            loadTrackArtwork(track: track, station: station, baseInfo: baseInfo)
        } else {
            loadStationArtwork(station: station, baseInfo: baseInfo)
        }
    }

    private func loadTrackArtwork(track: Track, station: Station, baseInfo: [String: Any]) {
        let query = "\(track.artist) \(track.title)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(AppSettings.iTunesSearchBaseURL)?term=\(query)&entity=song&limit=1"

        guard let url = URL(string: urlString) else {
            loadStationArtwork(station: station, baseInfo: baseInfo)
            return
        }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let result = try JSONDecoder().decode(ITunesSearchResponse.self, from: data)

                if let firstResult = result.results.first,
                   let artworkURLString = firstResult.artworkUrl100?.replacingOccurrences(of: "100x100", with: "600x600"),
                   let artworkURL = URL(string: artworkURLString) {

                    let (imageData, _) = try await URLSession.shared.data(from: artworkURL)
                    if let image = UIImage(data: imageData) {
                        await updateNowPlayingArtwork(image: image, baseInfo: baseInfo)
                        return
                    }
                }

                await MainActor.run {
                    self.loadStationArtwork(station: station, baseInfo: baseInfo)
                }
            } catch {
                await MainActor.run {
                    self.loadStationArtwork(station: station, baseInfo: baseInfo)
                }
            }
        }
    }

    private func loadStationArtwork(station: Station, baseInfo: [String: Any]) {
        guard let logoURLString = station.logoURL,
              !logoURLString.isEmpty,
              let logoURL = URL(string: logoURLString) else {
            if let defaultImage = UIImage(named: "default_artwork") {
                updateNowPlayingArtworkSync(image: defaultImage, baseInfo: baseInfo)
            }
            return
        }

        Task {
            do {
                let (imageData, _) = try await URLSession.shared.data(from: logoURL)
                if let image = UIImage(data: imageData) {
                    await updateNowPlayingArtwork(image: image, baseInfo: baseInfo)
                } else if let defaultImage = UIImage(named: "default_artwork") {
                    await updateNowPlayingArtwork(image: defaultImage, baseInfo: baseInfo)
                }
            } catch {
                if let defaultImage = UIImage(named: "default_artwork") {
                    await updateNowPlayingArtwork(image: defaultImage, baseInfo: baseInfo)
                }
            }
        }
    }

    private func updateNowPlayingArtwork(image: UIImage, baseInfo: [String: Any]) async {
        await MainActor.run {
            updateNowPlayingArtworkSync(image: image, baseInfo: baseInfo)
        }
    }

    private func updateNowPlayingArtworkSync(image: UIImage, baseInfo: [String: Any]) {
        var updatedInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? baseInfo

        let artwork = MPMediaItemArtwork(boundsSize: image.size) { size in
            return image
        }

        updatedInfo[MPMediaItemPropertyArtwork] = artwork
        MPNowPlayingInfoCenter.default().nowPlayingInfo = updatedInfo
    }

    deinit {
        NotificationCenter.default.removeObserver(self)

        if let item = playerItem {
            item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
            item.removeObserver(self, forKeyPath: "playbackBufferEmpty")
            item.removeObserver(self, forKeyPath: "playbackBufferFull")
        }

        statusObserver?.invalidate()

        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
        }

        endBackgroundTask()

        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            Logger.log("Audio session deactivation error: \(error)", category: .audio, type: .error)
        }
    }
}
