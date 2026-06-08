import UIKit
import RxSwift
import RxCocoa

final class FavoritesViewController: BaseViewController {

    private let favoritesView = FavoritesView()
    private let viewModel = FavoritesViewModel()

    override func loadView() {
        view = favoritesView
    }

    override func setupAppearance() {
        super.setupAppearance()
        navigationController?.setNavigationBarHidden(false, animated: false)

    }

    override func bind() {
        let itemSelected = favoritesView.tableView.rx.modelSelected(Music.self).asObservable()

        let input = FavoritesViewModel.Input(
            viewDidLoad: Observable.just(()),
            itemSelected: itemSelected,
            playAllTapped: favoritesView.playAllButton.rx.tap.asObservable(),
            shuffleTapped: favoritesView.shuffleButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.songs
            .drive(favoritesView.tableView.rx.items(
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
                let totalMs = songs.reduce(0) { $0 + $1.totalDurationMs }
                self?.favoritesView.configureHeader(count: songs.count, totalDurationMs: totalMs)
                self?.favoritesView.updateEmptyState(isEmpty: songs.isEmpty)
            })
            .disposed(by: disposeBag)
    }
}
