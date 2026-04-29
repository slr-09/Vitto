//
//  AnimatedTimeView.swift
//  Vitto
//
//  Created by 가은 on 4/29/26.
//

import UIKit
import SnapKit

final class AnimatedTimeView: UIView {

    private enum TimeSegment: Equatable {
        case digit(String)
        case unit(String)
    }

    private let stack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 0
        return s
    }()

    private var currentTimeSegments: [TimeSegment] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stack)
        stack.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    func update(to ms: Int, animated: Bool = true) {
        let newTimeSegments = Self.tokenize(ms)
        defer { currentTimeSegments = newTimeSegments }

        guard animated, sameStructure(currentTimeSegments, newTimeSegments) else {
            rebuild(tokens: newTimeSegments, animated: animated && !currentTimeSegments.isEmpty)
            return
        }

        let slots = stack.arrangedSubviews.compactMap { $0 as? DigitSlotView }
        var slotIndex = 0
        var changedOrder = 0
        for (old, new) in zip(currentTimeSegments, newTimeSegments) {
            guard case .digit(let oldChar) = old, case .digit(let newChar) = new else { continue }
            defer { slotIndex += 1 }
            if oldChar != newChar {
                slots[slotIndex].slide(to: newChar, delay: Double(changedOrder) * 0.08)
                changedOrder += 1
            }
        }
    }

    private func rebuild(tokens: [TimeSegment], animated: Bool) {
        let newViews = tokens.map { makeView(for: $0) }
        let apply = {
            self.stack.arrangedSubviews.forEach {
                self.stack.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
            newViews.forEach { self.stack.addArrangedSubview($0) }
        }
        if animated {
            UIView.transition(with: self, duration: 0.25, options: .transitionCrossDissolve, animations: apply)
        } else {
            apply()
        }
    }

    private func makeView(for token: TimeSegment) -> UIView {
        switch token {
        case .digit(let char):
            let slot = DigitSlotView()
            slot.set(char)
            return slot
        case .unit(let text):
            let label = UILabel()
            label.text = text
            label.font = AppFont.displayLG
            label.textColor = AppColor.onBackground
            return label
        }
    }

    private func sameStructure(_ a: [TimeSegment], _ b: [TimeSegment]) -> Bool {
        guard a.count == b.count else { return false }
        return zip(a, b).allSatisfy {
            switch ($0, $1) {
            case (.digit, .digit): return true
            case (.unit(let u1), .unit(let u2)): return u1 == u2
            default: return false
            }
        }
    }

    private static func tokenize(_ ms: Int) -> [TimeSegment] {
        let totalSeconds = ms / 1_000
        let totalMinutes = totalSeconds / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        var tokens: [TimeSegment] = []

        if hours > 0 {
            for ch in "\(hours)" { tokens.append(.digit(String(ch))) }
            tokens.append(.unit("시간 "))
            for ch in String(format: "%02d", minutes) { tokens.append(.digit(String(ch))) }
            tokens.append(.unit("분"))
        } else if totalSeconds >= 60 {
            for ch in "\(totalMinutes)" { tokens.append(.digit(String(ch))) }
            tokens.append(.unit("분"))
        } else {
            for ch in "\(totalSeconds)" { tokens.append(.digit(String(ch))) }
            tokens.append(.unit("초"))
        }

        return tokens
    }
}
