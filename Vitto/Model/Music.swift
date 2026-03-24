import Foundation

struct Music {
    let musicID: String       // PK - 노래 고유 ID
    let title: String         // 노래 제목
    let artist: String        // 노래 가수
    let totalDurationMs: Int  // 노래 길이 (밀리초)
    let isrc: String          // 곡의 고유 식별자
    let albumTitle: String    // 앨범명
    let artworkUrl: String    // 앨범 이미지 URL
    let genre: String         // 장르명
}

extension Music {
    var durationFormatted: String {
        let totalSeconds = totalDurationMs / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
