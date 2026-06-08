import UIKit
import SnapKit

final class FavoritesView: BaseView {

    let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.rowHeight = 64
        tv.register(SearchResultCell.self, forCellReuseIdentifier: SearchResultCell.identifier)
        return tv
    }()

    private let headerView = FavoritesHeaderView()
    private let headerHeight: CGFloat = 250

    var playAllButton: UIButton { headerView.playButton }

    let emptyView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    private let emptyIconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "heart")
        iv.tintColor = AppColor.onSurfaceVariant
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "좋아요한 곡이 없습니다"
        label.font = AppFont.bodyLarge
        label.textColor = AppColor.onSurfaceVariant
        label.textAlignment = .center
        return label
    }()

    override func setupHierarchy() {
        addSubview(tableView)
        addSubview(emptyView)
        [emptyIconView, emptyLabel].forEach { emptyView.addSubview($0) }
        tableView.tableHeaderView = headerView
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = tableView.bounds.width
        guard width > 0 else { return }
        if headerView.frame.width != width || headerView.frame.height != headerHeight {
            headerView.frame = CGRect(x: 0, y: 0, width: width, height: headerHeight)
            tableView.tableHeaderView = headerView
        }
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

    func configureHeader(count: Int, totalDurationMs: Int) {
        headerView.configure(count: count, totalDurationMs: totalDurationMs)
    }
}
