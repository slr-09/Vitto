import UIKit
import SnapKit

final class GenreChipView: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStyles()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupStyles() {
        titleLabel?.font = AppFont.h3
        setTitleColor(AppColor.onBackground, for: .normal)
        backgroundColor = AppColor.surfaceContainerHigh
        layer.cornerRadius = AppSpacing.Radius.md
        clipsToBounds = true
        contentEdgeInsets = UIEdgeInsets(
            top: AppSpacing.sm,
            left: AppSpacing.md,
            bottom: AppSpacing.sm,
            right: AppSpacing.md
        )
    }

    private(set) var genre: GenreInfo?

    func configure(genre: GenreInfo) {
        self.genre = genre
        setTitle(genre.name, for: .normal)
    }
}
