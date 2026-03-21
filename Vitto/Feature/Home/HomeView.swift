import UIKit
import SnapKit

final class HomeView: BaseView {

    private weak var nebulaLayer: CAGradientLayer?
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

    private let favoriteMixHeader = SectionHeaderView()
    lazy var favoriteMixCollectionView = makeHorizontalCollectionView(itemSize: CGSize(width: 120, height: 165))

    private func makeHorizontalCollectionView(itemSize: CGSize) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = itemSize
        layout.minimumLineSpacing = AppSpacing.md
        layout.sectionInset = UIEdgeInsets(top: 0, left: AppSpacing.screenHorizontal, bottom: 0, right: AppSpacing.screenHorizontal)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(MusicCardCell.self, forCellWithReuseIdentifier: MusicCardCell.reuseIdentifier)
        return cv
    }

    override func setupHierarchy() {
        [scrollView].forEach { addSubview($0) }
        scrollView.addSubview(contentStack)

        let recommendedSection = makeSectionContainer(header: recommendedHeader, collection: recommendedCollectionView)
        let favoriteMixSection = makeSectionContainer(header: favoriteMixHeader, collection: favoriteMixCollectionView)

        [heroSectionView, recommendedSection, favoriteMixSection].forEach { contentStack.addArrangedSubview($0) }
    }

    override func setupConstraints() {
        scrollView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(safeAreaLayoutGuide)
        }
        contentStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }
        heroSectionView.snp.makeConstraints {
            $0.height.equalTo(200)
        }
        recommendedCollectionView.snp.makeConstraints {
            $0.height.equalTo(185)
        }
        favoriteMixCollectionView.snp.makeConstraints {
            $0.height.equalTo(165)
        }
    }

    override func setupStyles() {
        recommendedHeader.configure(title: "Recommended for You")
        favoriteMixHeader.configure(title: "Your Favorite Mix")
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.showsVerticalScrollIndicator = false
        
        let gradient = AppGradients.backgroundNebula(frame: bounds)
        layer.insertSublayer(gradient, at: 0)
        self.nebulaLayer = gradient
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        nebulaLayer?.frame = bounds
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
