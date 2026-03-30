//
//  PreviewPlayer.swift
//  Vitto
//
//  Created by 가은 on 3/30/26.
//

import UIKit
import AVFoundation
import MediaPlayer
import RxCocoa

enum RemoteCommand {
    case play, pause, next, previous
}

final class PreviewPlayer {

    /// 재생이 끝났을 때 호출되는 콜백
    var onPlaybackEnded: (() -> Void)?

    /// 잠금화면/제어센터 리모트 커맨드 이벤트
    let remoteCommand = PublishRelay<RemoteCommand>()

    private var player: AVPlayer?
    private var endObserver: Any?

    /// 현재 재생 시간 (초)
    var currentTime: TimeInterval {
        let time = player?.currentTime().seconds ?? 0
        return time.isNaN ? 0 : time
    }

    // MARK: - Audio Session
    /// 백그라운드 재생
    func setupAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    // MARK: - Playback

    func play(for music: Music) {
        stop()

        guard let urlString = music.previewUrl,
              let url = URL(string: urlString) else {
            print("[PreviewPlayer] 미리듣기 URL 없음: \(music.title)")
            return
        }

        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.play()

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.onPlaybackEnded?()
        }
    }

    func pause() {
        player?.pause()
    }

    func resume() {
        player?.play()
    }

    func stop() {
        pause()
        player = nil
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }
    }

    // MARK: - Remote Commands (잠금화면/제어센터)

    func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            self?.remoteCommand.accept(.play)
            return .success
        }

        center.pauseCommand.addTarget { [weak self] _ in
            self?.remoteCommand.accept(.pause)
            return .success
        }

        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.remoteCommand.accept(.next)
            return .success
        }

        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.remoteCommand.accept(.previous)
            return .success
        }
    }

    // MARK: - Now Playing Info (제어센터 곡 정보)

    func updateNowPlayingInfo(for music: Music, isPlaying: Bool) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: music.title,
            MPMediaItemPropertyArtist: music.artist,
            MPMediaItemPropertyPlaybackDuration: Double(music.totalDurationMs) / 1000.0,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]

        if let url = URL(string: music.artworkUrl) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data, let image = UIImage(data: data) else { return }
                let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                info[MPMediaItemPropertyArtwork] = artwork
                MPNowPlayingInfoCenter.default().nowPlayingInfo = info
            }.resume()
        } else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }

    func updateNowPlayingPlaybackState(isPlaying: Bool) {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
