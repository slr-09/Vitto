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
    let heroSkeletonView = HeroSkeletonView()

    private let recommendedHeader = SectionHeaderView()
    lazy var recommendedCollectionView = makeHorizontalCollectionView(itemSize: CGSize(width: 140, height: 200))
    let recommendedSkeletonView = RecommendedSkeletonView()

    let top100Header = SectionHeaderView()
    let top100SkeletonView = Top100SkeletonView()
    let top100PreviewTableView: SelfSizingTableView = {
        let tv = SelfSizingTableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.isScrollEnabled = false
        tv.register(SearchResultCell.self, forCellReuseIdentifier: SearchResultCell.identifier)
        return tv
    }()

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
        let top100Section = makeTop100SectionContainer()

        [heroSectionView, recommendedSection, top100Section].forEach { contentStack.addArrangedSubview($0) }

        // 스켈레톤 오버레이
        heroSectionView.addSubview(heroSkeletonView)
        heroSkeletonView.snp.makeConstraints { $0.edges.equalToSuperview() }
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
            $0.height.equalTo(200)
        }
    }

    override func setupStyles() {
        recommendedHeader.configure(title: "Recommended for You", showMore: false)
        top100Header.configure(title: "실시간 Top 100")
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.showsVerticalScrollIndicator = false
        
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        scrollView.contentInset.bottom = safeAreaInsets.bottom
        scrollView.verticalScrollIndicatorInsets.bottom = safeAreaInsets.bottom
    }

    private func makeTop100SectionContainer() -> UIView {
        let container = UIView()
        [top100Header, top100PreviewTableView, top100SkeletonView].forEach { container.addSubview($0) }
        top100Header.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(AppSpacing.screenHorizontal)
        }
        top100PreviewTableView.snp.makeConstraints {
            $0.top.equalTo(top100Header.snp.bottom).offset(AppSpacing.sm)
            $0.horizontalEdges.bottom.equalToSuperview()
        }
        top100SkeletonView.snp.makeConstraints {
            $0.top.equalTo(top100Header.snp.bottom).offset(AppSpacing.sm)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(64 * 5)
        }
        return container
    }

    private func makeSectionContainer(header: SectionHeaderView, collection: UICollectionView) -> UIView {
        let container = UIView()
        [header, collection, recommendedSkeletonView].forEach { container.addSubview($0) }
        header.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.screenHorizontal)
            $0.height.equalTo(36)
        }
        collection.snp.makeConstraints {
            $0.top.equalTo(header.snp.bottom).offset(AppSpacing.sm)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        recommendedSkeletonView.snp.makeConstraints {
            $0.edges.equalTo(collection)
        }
        return container
    }
}
