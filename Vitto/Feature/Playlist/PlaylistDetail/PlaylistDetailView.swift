import UIKit
import SnapKit

final class PlaylistDetailView: BaseView {

    let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.rowHeight = 64
        tv.register(SearchResultCell.self, forCellReuseIdentifier: SearchResultCell.identifier)
        return tv
    }()

    let emptyView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    private let emptyIconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "music.note")
        iv.tintColor = AppColor.onSurfaceVariant
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "노래가 없습니다"
        label.font = AppFont.bodyLarge
        label.textColor = AppColor.onSurfaceVariant
        label.textAlignment = .center
        return label
    }()

    override func setupHierarchy() {
        addSubview(tableView)
        addSubview(emptyView)
        [emptyIconView, emptyLabel].forEach { emptyView.addSubview($0) }
    }

    override func setupConstraints() {
        tableView.snp.makeConstraints {
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
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    func updateEmptyState(isEmpty: Bool) {
        emptyView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
}
