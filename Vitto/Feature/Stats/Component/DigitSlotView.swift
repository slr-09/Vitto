//
//  DigitSlotView.swift
//  Vitto
//
//  Created by 가은 on 4/29/26.
//

import UIKit
import SnapKit

final class DigitSlotView: UIView {

    private let frontLabel = UILabel()
    private let backLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        clipsToBounds = true
        for label in [frontLabel, backLabel] {
            label.font = AppFont.displayLG
            label.textColor = AppColor.onBackground
            label.textAlignment = .center
            addSubview(label)
            label.snp.makeConstraints { $0.edges.equalToSuperview() }
        }
        backLabel.alpha = 0
    }

    required init?(coder: NSCoder) { fatalError() }

    func set(_ char: String) {
        frontLabel.text = char
        backLabel.text = char
    }

    func slide(to char: String, delay: TimeInterval = 0) {
        let height = frontLabel.intrinsicContentSize.height
        backLabel.text = char
        backLabel.alpha = 1
        backLabel.transform = CGAffineTransform(translationX: 0, y: height)

        UIView.animate(withDuration: 0.3, delay: delay, options: .curveEaseInOut) {
            self.frontLabel.transform = CGAffineTransform(translationX: 0, y: -height)
            self.backLabel.transform = .identity
        } completion: { _ in
            self.frontLabel.text = char
            self.frontLabel.transform = .identity
            self.backLabel.alpha = 0
        }
    }

    override var intrinsicContentSize: CGSize {
        frontLabel.intrinsicContentSize
    }
}
