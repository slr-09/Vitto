//
//  SharedModel.swift
//  Vitto
//
//  Created by 가은 on 4/7/26.
//

import Foundation

struct Top100Song: Codable {
    let rank: Int
    let musicID: String
    let title: String
    let artist: String
    let artworkUrl: String
}
