//
//  SharedFileStorage.swift
//  Vitto
//
//  Created by 가은 on 4/7/26.
//

import Foundation

enum SharedFileStorage {

    private static let groupIdentifier = "group.com.siro.Vitto"

    private static var baseDirectory: URL {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier)!
    }

    // MARK: - General

    private static func directory(for subdirectory: String) -> URL {
        baseDirectory.appendingPathComponent(subdirectory, isDirectory: true)
    }

    /// 지정한 서브디렉토리 초기화 (기존 파일 삭제 후 재생성)
    static func cleanup(subdirectory: String) {
        let fm = FileManager.default
        let dir = directory(for: subdirectory)
        if fm.fileExists(atPath: dir.path) {
            try? fm.removeItem(at: dir)
        }
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    /// 지정한 서브디렉토리에 파일 저장
    static func save(data: Data, fileName: String, subdirectory: String) {
        let dir = directory(for: subdirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileURL = dir.appendingPathComponent(fileName)
        try? data.write(to: fileURL)
    }

    /// 지정한 서브디렉토리에서 파일 URL 반환 (없으면 nil)
    static func fileURL(fileName: String, subdirectory: String) -> URL? {
        let fileURL = directory(for: subdirectory).appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }

    // MARK: - Artwork

    private static let artworkSubdirectory = "WidgetArtworks"

    static func cleanupArtworks() {
        cleanup(subdirectory: artworkSubdirectory)
    }

    static func saveArtwork(musicID: String, data: Data) {
        save(data: data, fileName: "\(musicID).jpg", subdirectory: artworkSubdirectory)
    }

    static func artworkURL(for musicID: String) -> URL? {
        fileURL(fileName: "\(musicID).jpg", subdirectory: artworkSubdirectory)
    }
}
