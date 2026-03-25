import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class PlaylistPickerViewController: BaseViewController {

    private let music: Music
    private var playlists: [Playlist] = []
    private var playlistEntities: [PlaylistEntity] = []

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "플레이리스트에 추가"
        label.font = AppFont.h2
        label.textColor = AppColor.onBackground
        return label
    }()

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.rowHeight = 56
        tv.register(PlaylistPickerCell.self, forCellReuseIdentifier: PlaylistPickerCell.identifier)
        return tv
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "플레이리스트가 없습니다.\nPlaylist 탭에서 먼저 생성해 주세요."
        label.font = AppFont.bodyMedium
        label.textColor = AppColor.onSurfaceVariant
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    init(music: Music) {
        self.music = music
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupHierarchy() {
        view.addSubview(titleLabel)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
    }

    override func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(AppSpacing.lg)
            $0.leading.equalToSuperview().inset(AppSpacing.screenHorizontal)
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(AppSpacing.md)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        emptyLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.screenHorizontal)
        }
    }

    override func bind() {
        playlistEntities = PlaylistService.shared.fetchAllPlaylistEntities()
        playlists = playlistEntities.map { $0.toPlaylist() }

        emptyLabel.isHidden = !playlists.isEmpty
        tableView.isHidden = playlists.isEmpty

        Observable.just(playlists)
            .bind(to: tableView.rx.items(
                cellIdentifier: PlaylistPickerCell.identifier,
                cellType: PlaylistPickerCell.self
            )) { _, playlist, cell in
                cell.configure(with: playlist)
            }
            .disposed(by: disposeBag)

        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self else { return }
                let entity = self.playlistEntities[indexPath.row]
                PlaylistService.shared.addSong(self.music, to: entity)
                self.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
    }
}
