import UIKit
import RxSwift
import RxCocoa

final class PlaylistViewController: BaseViewController {

    private let playlistView = PlaylistView()
    private let viewModel = PlaylistViewModel()
    private let createPlaylistRelay = PublishRelay<String>()

    override func loadView() {
        view = playlistView
    }

    override func setupAppearance() {
        super.setupAppearance()
        navigationController?.setNavigationBarHidden(false, animated: false)

        let titleLabel = UILabel()
        titleLabel.font = AppFont.displayMD
        titleLabel.text = "Playlist"
        titleLabel.textColor = AppColor.onBackground
        titleLabel.textAlignment = .center
        navigationItem.titleView = titleLabel

        let addButton = UIButton(type: .system)
        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.tintColor = AppColor.onSurfaceVariant
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addButton)

        addButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.showCreatePlaylistAlert()
            })
            .disposed(by: disposeBag)
    }

    override func bind() {
        let input = PlaylistViewModel.Input(
            viewDidLoad: Observable.just(()),
            createPlaylistTapped: createPlaylistRelay.asObservable(),
            deletePlaylist: Observable.empty()
        )

        let output = viewModel.transform(input: input)

        output.playlists
            .drive(playlistView.collectionView.rx.items(
                cellIdentifier: PlaylistCardCell.identifier,
                cellType: PlaylistCardCell.self
            )) { _, playlist, cell in
                cell.configure(name: playlist.name, songCount: playlist.songs.count)
            }
            .disposed(by: disposeBag)

        output.playlists
            .drive(onNext: { [weak self] playlists in
                self?.playlistView.updateEmptyState(isEmpty: playlists.isEmpty)
            })
            .disposed(by: disposeBag)

        playlistView.collectionView.rx.modelSelected(Playlist.self)
            .subscribe(onNext: { [weak self] playlist in
                let detailVC = PlaylistDetailViewController(playlist: playlist)
                self?.navigationController?.pushViewController(detailVC, animated: true)
            })
            .disposed(by: disposeBag)
    }

    private func showCreatePlaylistAlert() {
        let alert = UIAlertController(
            title: "새 플레이리스트",
            message: "플레이리스트 이름을 입력하세요",
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = "플레이리스트 이름"
        }
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "만들기", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            self?.createPlaylistRelay.accept(name)
        })
        present(alert, animated: true)
    }
}
