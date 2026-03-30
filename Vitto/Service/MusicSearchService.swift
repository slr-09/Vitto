//
//  MusicSearchService.swift
//  Vitto
//
//  Created by 가은 on 3/30/26.
//

import Foundation
import MusicKit
import RxSwift

final class MusicSearchService {

    static let shared = MusicSearchService()
    private init() {}

    func searchMusic(query: String) -> Observable<[Music]> {
        return .async {
            var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
            request.limit = 20
            let response = try await request.response()

            return response.songs.map { $0.toMusic() }
        }
    }

    /// 장르명으로 노래를 검색합니다.
    func searchSongs(byGenreName name: String) -> Observable<[Music]> {
        return .async {
            var request = MusicCatalogSearchRequest(term: name, types: [Song.self])
            request.limit = 30
            let response = try await request.response()

            let songs = response.songs.map { $0.toMusic() }

            print("[MusicSearchService] 장르명 검색 완료: \(name) → \(songs.count)곡")
            return songs
        }
    }
    
    /// 장르 ID로 인기곡 차트를 가져옵니다.
    func searchSongs(byGenreID genreID: MusicItemID) -> Observable<[Music]> {
        return .async {
            let genreRequest = MusicCatalogResourceRequest<Genre>(
                matching: \.id,
                equalTo: genreID
            )
            let genreResponse = try await genreRequest.response()

            guard let genre = genreResponse.items.first else {
                print("[MusicService] 장르 ID를 찾을 수 없음: \(genreID)")
                return []
            }

            var chartRequest = MusicCatalogChartsRequest(genre: genre, types: [])
            chartRequest.limit = 20
            let chartResponse = try await chartRequest.response()

            let songs = (chartResponse.songCharts.first?.items ?? []).map { $0.toMusic() }

            print("[MusicService] 장르 ID 차트 조회 완료: \(genre.name) → \(songs.count)곡")
            return songs
        }
    }

    /// 키워드로 Apple Music 큐레이션 플레이리스트를 검색하고, 첫 번째 플레이리스트의 트랙을 반환
    func searchCuratedPlaylistTracks(query: String, limit: Int = 20) -> Observable<[Music]> {
        return .async {
            var request = MusicCatalogSearchRequest(term: query, types: [MusicKit.Playlist.self])
            request.limit = 1
            let response = try await request.response()

            guard let playlist = response.playlists.first else { return [] }

            let detailedPlaylist = try await playlist.with([.tracks])

            guard let tracks = detailedPlaylist.tracks else { return [] }

            return tracks.prefix(limit).compactMap { track -> Music? in
                guard case let .song(song) = track else { return nil }
                return song.toMusic()
            }
        }
    }

    /// Apple Music 카탈로그에서 전체 장르 목록을 가져옵니다.
    func fetchGenres() -> Observable<[Genre]> {
        return .async {
            let countryCode = try await MusicDataRequest.currentCountryCode
            let url = URL(string: "https://api.music.apple.com/v1/catalog/\(countryCode)/genres")!

            let request = MusicDataRequest(urlRequest: URLRequest(url: url))
            let response = try await request.response()
            let genres = try JSONDecoder().decode(MusicItemCollection<Genre>.self, from: response.data)

            print("[MusicSearchService] 장르 조회 완료: \(genres.count)개")
            dump(genres)

            return Array(genres)
        }
    }
}
