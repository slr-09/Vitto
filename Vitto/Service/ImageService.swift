//
//  ImageService.swift
//  Vitto
//
//  Created by 가은 on 4/7/26.
//

import UIKit

enum ImageService {

    /// 이미지 Data를 지정 사이즈로 리사이즈한 JPEG Data 반환
    static func resizedJPEGData(from data: Data, maxSize: CGFloat, quality: CGFloat = 0.7) -> Data? {
        guard let original = UIImage(data: data) else { return nil }
        let size = CGSize(width: maxSize, height: maxSize)
        let resized = UIGraphicsImageRenderer(size: size).image { _ in
            original.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: quality)
    }
}
