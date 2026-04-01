import UIKit
import RxSwift
import RxCocoa

final class Top100DetailViewController: BaseViewController {

    private let detailView = PlaylistDetailView()
    private let viewModel: Top100DetailViewModel

    init(songs: [Music]) {
        self.viewModel = Top100DetailViewModel(songs: songs)
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

        let titleLabel = UILabel()
        titleLabel.font = AppFont.displayMD
        titleLabel.text = "Top 100"
        titleLabel.textColor = AppColor.onBackground
        titleLabel.textAlignment = .center
        navigationItem.titleView = titleLabel
    }

    override func bind() {
        let itemSelected = detailView.tableView.rx.modelSelected(Music.self).asObservable()

        let input = Top100DetailViewModel.Input(
            viewDidLoad: Observable.just(()),
            itemSelected: itemSelected
        )

        let output = viewModel.transform(input: input)

        output.songs
            .drive(detailView.tableView.rx.items(
                cellIdentifier: SearchResultCell.identifier,
                cellType: SearchResultCell.self
            )) { [weak self] index, music, cell in
                cell.configure(with: music, rank: index + 1)
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
