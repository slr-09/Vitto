import Foundation

struct Playlist {
    let id: UUID
    let name: String
    let description: String?
    let coverImageUrl: String?
    let createdAt: Date
    let updatedAt: Date
    let songs: [Music]
}
