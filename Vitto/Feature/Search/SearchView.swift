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
    
    // MARK: - Setup
    override func setupHierarchy() {
        addSubview(titleLabel)
        addSubview(searchBar)
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
    }
    
    override func setupStyles() {
        super.setupStyles()
        backgroundColor = AppColor.background
    }
}
