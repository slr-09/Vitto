import UIKit
import RxSwift
import RxCocoa

final class PlaylistDetailViewController: BaseViewController {

    private let detailView = PlaylistDetailView()
    private let viewModel: PlaylistDetailViewModel

    init(playlist: Playlist) {
        self.viewModel = PlaylistDetailViewModel(playlist: playlist)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = detailView
    }

    override func setupAppearance() {
        super.setupAppearance()
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func bind() {
        let itemSelected = detailView.tableView.rx.modelSelected(Music.self).asObservable()

        let input = PlaylistDetailViewModel.Input(
            viewDidLoad: Observable.just(()),
            itemSelected: itemSelected
        )

        let output = viewModel.transform(input: input)

        output.playlistName
            .drive(onNext: { [weak self] name in
                let titleLabel = UILabel()
                titleLabel.font = AppFont.displayMD
                titleLabel.text = name
                titleLabel.textColor = AppColor.onBackground
                titleLabel.textAlignment = .center
                self?.navigationItem.titleView = titleLabel
            })
            .disposed(by: disposeBag)

        output.songs
            .drive(detailView.tableView.rx.items(
                cellIdentifier: SearchResultCell.identifier,
                cellType: SearchResultCell.self
            )) { [weak self] _, music, cell in
                cell.configure(with: music)
                cell.onMoreButtonTapped = {
                    guard let self else { return }
                    MusicActionSheetPresenter.show(for: music, from: self, disposeBag: self.disposeBag)
                }
            }
            .disposed(by: disposeBag)

        output.songs
            .drive(onNext: { [weak self] songs in
                self?.detailView.updateEmptyState(isEmpty: songs.isEmpty)
            })
            .disposed(by: disposeBag)
    }

}
