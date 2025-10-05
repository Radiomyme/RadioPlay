import Foundation
import UIKit
import Combine
import MediaPlayer

class AudioPlayerManager: ObservableObject {
    static let shared = AudioPlayerManager()

    private let audioService = AudioPlayerService()
    private var cancellables = Set<AnyCancellable>()

    @Published var currentStation: Station?
    @Published var isPlaying: Bool = false
    @Published var currentTrack: Track?
    @Published var isBuffering: Bool = false
    @Published var artwork: UIImage?

    let sleepTimerService = SleepTimerService()

    private init() {
        setupObservers()
        setupRemoteCommandCenter()
    }

    // MARK: - Setup

    private func setupObservers() {
        audioService.$isPlaying
            .assign(to: \.isPlaying, on: self)
            .store(in: &cancellables)

        audioService.$isBuffering
            .assign(to: \.isBuffering, on: self)
            .store(in: &cancellables)

        audioService.$currentTrack
            .sink { [weak self] track in
                guard let self = self, let track = track else { return }
                self.currentTrack = track
                self.updateArtwork(for: track)
            }
            .store(in: &cancellables)
    }

    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }

            if !self.isPlaying {
                self.togglePlayPause()
                return .success
            }
            return .commandFailed
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }

            if self.isPlaying {
                self.togglePlayPause()
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

    // MARK: - Playback Control

    func play(station: Station) {
        if currentStation?.id != station.id {
            currentStation = station
            audioService.play(station: station)
            loadStationLogoAsArtwork(station: station)
        } else if !isPlaying {
            audioService.togglePlayPause()
        }
    }

    func togglePlayPause() {
        audioService.togglePlayPause()
    }

    func stop() {
        audioService.stop()
        currentStation = nil
        artwork = nil
    }

    // MARK: - Sleep Timer

    func setupSleepTimer(duration: TimeInterval) {
        sleepTimerService.startTimer(duration: duration) { [weak self] in
            self?.stop()
        }
    }

    func cancelSleepTimer() {
        sleepTimerService.stopTimer()
    }

    // MARK: - Artwork Management

    private func updateArtwork(for track: Track) {
        Task {
            do {
                let artworkService = ArtworkService()
                let image = try await artworkService.fetchArtwork(for: track)
                await MainActor.run {
                    self.artwork = image ?? UIImage(named: "default_artwork")
                    self.updateNowPlayingInfo()
                }
            } catch {
                await MainActor.run {
                    if let station = self.currentStation {
                        self.loadStationLogoAsArtwork(station: station)
                    } else {
                        self.artwork = UIImage(named: "default_artwork")
                    }
                    self.updateNowPlayingInfo()
                }
            }
        }
    }

    private func loadStationLogoAsArtwork(station: Station) {
        guard artwork == nil || artwork == UIImage(named: "default_artwork") else {
            return
        }

        guard let logoURLString = station.logoURL, !logoURLString.isEmpty,
              let logoURL = URL(string: logoURLString) else {
            self.artwork = UIImage(named: "default_artwork")
            return
        }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: logoURL)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        if self.artwork == nil || self.artwork == UIImage(named: "default_artwork") {
                            self.artwork = image
                            self.updateNowPlayingInfo()
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.artwork = UIImage(named: "default_artwork")
                }
            }
        }
    }

    // MARK: - Now Playing Info

    private func updateNowPlayingInfo() {
        guard let station = currentStation else { return }

        var nowPlayingInfo = [String: Any]()

        if let track = currentTrack {
            nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
            nowPlayingInfo[MPMediaItemPropertyArtist] = track.artist
        } else {
            nowPlayingInfo[MPMediaItemPropertyTitle] = station.name
            nowPlayingInfo[MPMediaItemPropertyArtist] = station.subtitle
        }

        if let artwork = self.artwork {
            let mpArtwork = MPMediaItemArtwork(boundsSize: artwork.size) { _ in artwork }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = mpArtwork
        }

        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
