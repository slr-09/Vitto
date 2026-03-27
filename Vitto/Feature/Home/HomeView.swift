import UIKit
import SnapKit

final class HomeView: BaseView {

    let scrollView = UIScrollView()
    private let contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = AppSpacing.xxl
        return sv
    }()

    let heroSectionView = HeroSectionView()

    private let recommendedHeader = SectionHeaderView()
    lazy var recommendedCollectionView = makeHorizontalCollectionView(itemSize: CGSize(width: 140, height: 185))

    private func makeHorizontalCollectionView(itemSize: CGSize) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = itemSize
        layout.minimumLineSpacing = AppSpacing.md
        layout.sectionInset = UIEdgeInsets(top: 0, left: AppSpacing.screenHorizontal, bottom: 0, right: AppSpacing.screenHorizontal)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(MusicCardCell.self, forCellWithReuseIdentifier: MusicCardCell.identifier)
        return cv
    }

    override func setupHierarchy() {
        [scrollView].forEach { addSubview($0) }
        scrollView.addSubview(contentStack)

        let recommendedSection = makeSectionContainer(header: recommendedHeader, collection: recommendedCollectionView)

        [heroSectionView, recommendedSection].forEach { contentStack.addArrangedSubview($0) }
    }

    override func setupConstraints() {
        scrollView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().inset(AppSpacing.md)
        }
        contentStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }
        recommendedCollectionView.snp.makeConstraints {
            $0.height.equalTo(185)
        }
    }

    override func setupStyles() {
        recommendedHeader.configure(title: "Recommended for You")
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.showsVerticalScrollIndicator = false
        
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        scrollView.contentInset.bottom = safeAreaInsets.bottom
        scrollView.verticalScrollIndicatorInsets.bottom = safeAreaInsets.bottom
    }

    private func makeSectionContainer(header: SectionHeaderView, collection: UICollectionView) -> UIView {
        let container = UIView()
        [header, collection].forEach { container.addSubview($0) }
        header.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.screenHorizontal)
            $0.height.equalTo(36)
        }
        collection.snp.makeConstraints {
            $0.top.equalTo(header.snp.bottom).offset(AppSpacing.sm)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        return container
    }
}
