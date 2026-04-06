import Foundation

struct Top100Song: Codable {
    let rank: Int
    let musicID: String
    let title: String
    let artist: String
    let artworkUrl: String
}
