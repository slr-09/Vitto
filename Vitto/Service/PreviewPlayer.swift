//
//  PreviewPlayer.swift
//  Vitto
//
//  Created by 가은 on 3/30/26.
//

import AVFoundation

final class PreviewPlayer {

    /// 재생이 끝났을 때 호출되는 콜백
    var onPlaybackEnded: (() -> Void)?

    private var player: AVPlayer?
    private var endObserver: Any?

    /// 현재 재생 시간 (초)
    var currentTime: TimeInterval {
        let time = player?.currentTime().seconds ?? 0
        return time.isNaN ? 0 : time
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
}
