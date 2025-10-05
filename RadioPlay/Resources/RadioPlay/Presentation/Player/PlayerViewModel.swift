import Foundation
import UIKit
import MediaPlayer
import Combine

class PlayerViewModel: ObservableObject {
    @Published var isPlaying = false
    @Published var isBuffering = false
    @Published var currentTrack: Track?
    @Published var artwork: UIImage?

    private let audioService = AudioPlayerService()
    private let artworkService = ArtworkService()
    let sleepTimerService = SleepTimerService()

    private let station: Station
    private var cancellables = Set<AnyCancellable>()

    init(station: Station) {
        self.station = station
        setupObservers()
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

    // MARK: - Playback Control

    func startPlaying() {
        audioService.play(station: station)
    }

    func stopPlaying() {
        audioService.stop()
    }

    func togglePlayPause() {
        audioService.togglePlayPause()
    }

    // MARK: - Artwork Management

    private func updateArtwork(for track: Track) {
        Task {
            do {
                let image = try await artworkService.fetchArtwork(for: track)
                await MainActor.run {
                    self.artwork = image ?? UIImage(named: "default_artwork")
                }
            } catch {
                await MainActor.run {
                    self.artwork = UIImage(named: "default_artwork")
                }
            }
        }
    }

    // MARK: - Sharing

    func shareTrack() {
        guard let track = currentTrack else { return }

        let text = L10n.Player.shareMessage(
            track: track.title,
            artist: track.artist,
            station: station.name
        )

        var items: [Any] = [text]

        if let artwork = artwork {
            items.append(artwork)
        }

        let activityViewController = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        if let rootVC = AppUtility.rootViewController {
            rootVC.present(activityViewController, animated: true)
        }
    }

    func openInAppleMusic() {
        guard let track = currentTrack else { return }

        let query = "\(track.artist) \(track.title)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(AppSettings.appleMusicSearchBaseURL)?term=\(query)"

        guard let url = URL(string: urlString) else { return }

        UIApplication.shared.open(url)
    }

    // MARK: - Sleep Timer

    func setupSleepTimer(duration: TimeInterval) {
        sleepTimerService.startTimer(duration: duration) { [weak self] in
            self?.stopPlaying()
        }
    }

    func cancelSleepTimer() {
        sleepTimerService.stopTimer()
    }
}
