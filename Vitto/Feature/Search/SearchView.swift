import UIKit
import SnapKit

final class SearchView: BaseView {
    
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Search"
        label.font = AppFont.displayMD
        label.textColor = AppColor.onBackground
        return label
    }()
    
    let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Artists, Songs, or Albums"
        
        // 검색 텍스트 필드 스타일링
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.font = AppFont.bodyMedium
            textField.textColor = AppColor.onBackground
            textField.backgroundColor = AppColor.surfaceContainerHigh
            
            // placeholder 텍스트 색상 변경
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: AppColor.onSurfaceVariant,
                .font: AppFont.bodyMedium
            ]
            textField.attributedPlaceholder = NSAttributedString(string: "Artists, Songs, or Albums", attributes: attributes)
            
            // 돋보기 아이콘 색상 변경
            if let leftView = textField.leftView as? UIImageView {
                leftView.tintColor = AppColor.onSurfaceVariant
            }
            // 클리어 버튼 아이콘 색상 변경
            if let clearButton = textField.value(forKey: "clearButton") as? UIButton {
                clearButton.setImage(clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate), for: .normal)
                clearButton.tintColor = AppColor.onSurfaceVariant
            }
        }
        
        return searchBar
    }()
    
    // MARK: - Genre Section
    let genreSectionView = UIView()

    private let genreSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "Explore Genres"
        label.font = AppFont.h2
        label.textColor = AppColor.onBackground
        return label
    }()

    private let genreGridView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = AppSpacing.sm
        sv.distribution = .fillEqually
        return sv
    }()

    private let genreTopRow: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = AppSpacing.sm
        sv.distribution = .fillEqually
        return sv
    }()

    private let genreBottomRow: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = AppSpacing.sm
        sv.distribution = .fillEqually
        return sv
    }()

    let genreChipViews: [GenreChipView] = (0..<4).map { _ in GenreChipView() }

    // MARK: - Search Result
    let searchResultTableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.isHidden = true // 처음에는 숨김 처리
        tv.register(SearchResultCell.self, forCellReuseIdentifier: SearchResultCell.identifier)
        return tv
    }()
    
    let topResultCard = TopResultCardView()
    private let tableHeaderContainer = UIView()
    
    // MARK: - Setup
    override func setupHierarchy() {
        addSubview(titleLabel)
        addSubview(searchBar)
        addSubview(genreSectionView)
        addSubview(searchResultTableView)

        genreSectionView.addSubview(genreSectionLabel)
        genreSectionView.addSubview(genreGridView)
        genreGridView.addArrangedSubview(genreTopRow)
        genreGridView.addArrangedSubview(genreBottomRow)
        genreTopRow.addArrangedSubview(genreChipViews[0])
        genreTopRow.addArrangedSubview(genreChipViews[1])
        genreBottomRow.addArrangedSubview(genreChipViews[2])
        genreBottomRow.addArrangedSubview(genreChipViews[3])

        tableHeaderContainer.addSubview(topResultCard)
        searchResultTableView.tableHeaderView = tableHeaderContainer
    }
    
    override func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(AppSpacing.md)
            $0.leading.equalToSuperview().inset(AppSpacing.screenHorizontal)
        }
        
        searchBar.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(AppSpacing.md)
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.sm)
            $0.height.equalTo(56)
        }
        
        genreSectionView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(AppSpacing.lg)
            $0.leading.trailing.equalToSuperview()
        }

        genreSectionLabel.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalToSuperview().inset(AppSpacing.screenHorizontal)
        }

        genreGridView.snp.makeConstraints {
            $0.top.equalTo(genreSectionLabel.snp.bottom).offset(AppSpacing.md)
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.screenHorizontal)
            $0.bottom.equalToSuperview()
        }

        genreChipViews.forEach {
            $0.snp.makeConstraints { $0.height.equalTo(56) }
        }

        searchResultTableView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(AppSpacing.md)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        
        topResultCard.snp.makeConstraints {
            $0.top.equalToSuperview().offset(AppSpacing.sm)
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.screenHorizontal)
            $0.bottom.equalToSuperview().offset(-AppSpacing.lg)
            // 명시적 높이 지정으로 AutoLayout이 크기를 잡게 함
            $0.height.equalTo(200)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 테이블 뷰 헤더의 동적 높이 계산 및 업데이트
        if let headerView = searchResultTableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            if headerView.frame.size.height != height {
                var frame = headerView.frame
                frame.size.height = height
                headerView.frame = frame
                searchResultTableView.tableHeaderView = headerView
            }
        }
    }
    
    override func setupStyles() {
        super.setupStyles()
        backgroundColor = AppColor.background
    }
}
