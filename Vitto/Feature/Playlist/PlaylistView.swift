import UIKit
import SnapKit

final class PlaylistView: BaseView {

    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = AppSpacing.md
        layout.minimumInteritemSpacing = AppSpacing.md
        layout.sectionInset = UIEdgeInsets(
            top: AppSpacing.md,
            left: AppSpacing.screenHorizontal,
            bottom: AppSpacing.xxl,
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
        addSubview(collectionView)
        addSubview(emptyView)
        [emptyIconView, emptyLabel, emptySubLabel].forEach { emptyView.addSubview($0) }
    }

    override func setupConstraints() {
        collectionView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
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
}

// MARK: - UICollectionViewDelegateFlowLayout
extension PlaylistView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing = AppSpacing.screenHorizontal * 2 + AppSpacing.lg
        let width = (collectionView.bounds.width - spacing) / 2
        return CGSize(width: width, height: width + 54) // 이미지(정사각형) + 하단 텍스트 영역
    }
}
