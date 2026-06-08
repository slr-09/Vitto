import UIKit
import SnapKit

final class PlaylistView: BaseView {

    // MARK: - Favorites Entry Card

    let favoritesCard: UIControl = {
        let view = UIControl()
        view.backgroundColor = AppColor.surfaceContainerHigh
        view.layer.cornerRadius = AppSpacing.Radius.lg
        return view
    }()

    private let favoritesIconView: UIImageView = {
        let iv = UIImageView()
        let cfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        iv.image = UIImage(systemName: "heart.fill", withConfiguration: cfg)
        iv.tintColor = AppColor.primaryRose
        iv.contentMode = .center
        return iv
    }()

    private let favoritesTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "좋아요한 곡"
        label.font = AppFont.h3
        label.textColor = AppColor.onBackground
        return label
    }()

    private let favoritesCountLabel: UILabel = {
        let label = UILabel()
        label.text = "0곡"
        label.font = AppFont.caption
        label.textColor = AppColor.onSurfaceVariant
        return label
    }()

    private let favoritesChevron: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.right")
        iv.tintColor = AppColor.onSurfaceVariant
        iv.contentMode = .center
        return iv
    }()

    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = AppSpacing.md
        layout.minimumInteritemSpacing = AppSpacing.md
        layout.sectionInset = UIEdgeInsets(
            top: AppSpacing.md,
            left: AppSpacing.screenHorizontal,
            bottom: AppSpacing.md,
            right: AppSpacing.screenHorizontal
        )
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false
        cv.register(PlaylistCardCell.self, forCellWithReuseIdentifier: PlaylistCardCell.identifier)
        cv.delegate = self
        return cv
    }()

    let emptyView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    private let emptyIconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "music.note.list")
        iv.tintColor = AppColor.onSurfaceVariant
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "플레이리스트가 없습니다"
        label.font = AppFont.bodyLarge
        label.textColor = AppColor.onSurfaceVariant
        label.textAlignment = .center
        return label
    }()

    private let emptySubLabel: UILabel = {
        let label = UILabel()
        label.text = "+ 버튼을 눌러 새 플레이리스트를 만들어 보세요"
        label.font = AppFont.bodySmall
        label.textColor = AppColor.onSurfaceVariant
        label.textAlignment = .center
        return label
    }()

    override func setupHierarchy() {
        addSubview(favoritesCard)
        [favoritesIconView, favoritesTitleLabel, favoritesCountLabel, favoritesChevron].forEach {
            favoritesCard.addSubview($0)
        }
        addSubview(collectionView)
        addSubview(emptyView)
        [emptyIconView, emptyLabel, emptySubLabel].forEach { emptyView.addSubview($0) }
    }

    override func setupConstraints() {
        favoritesCard.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(AppSpacing.md)
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.screenHorizontal)
            $0.height.equalTo(64)
        }

        favoritesIconView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(AppSpacing.md)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(40)
        }

        favoritesTitleLabel.snp.makeConstraints {
            $0.leading.equalTo(favoritesIconView.snp.trailing).offset(AppSpacing.md)
            $0.top.equalToSuperview().inset(AppSpacing.md)
        }

        favoritesCountLabel.snp.makeConstraints {
            $0.leading.equalTo(favoritesTitleLabel)
            $0.top.equalTo(favoritesTitleLabel.snp.bottom).offset(2)
        }

        favoritesChevron.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(AppSpacing.md)
            $0.centerY.equalToSuperview()
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(favoritesCard.snp.bottom).offset(AppSpacing.sm)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        emptyView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.screenHorizontal)
        }

        emptyIconView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.centerX.equalToSuperview()
            $0.size.equalTo(48)
        }

        emptyLabel.snp.makeConstraints {
            $0.top.equalTo(emptyIconView.snp.bottom).offset(AppSpacing.md)
            $0.leading.trailing.equalToSuperview()
        }

        emptySubLabel.snp.makeConstraints {
            $0.top.equalTo(emptyLabel.snp.bottom).offset(AppSpacing.sm)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    func updateEmptyState(isEmpty: Bool) {
        emptyView.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
    }

    func updateFavoritesCount(_ count: Int) {
        favoritesCountLabel.text = "\(count)곡"
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension PlaylistView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing = AppSpacing.screenHorizontal * 2 + AppSpacing.lg
        let width = (collectionView.bounds.width - spacing) / 2
        return CGSize(width: width, height: width + 54) // 이미지(정사각형) + 하단 텍스트 영역
    }
}
