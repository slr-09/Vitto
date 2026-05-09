import UIKit
import RxSwift
import RxCocoa

final class Top100DetailViewController: BaseViewController {

    private let detailView = PlaylistDetailView()
    private let viewModel = Top100DetailViewModel()
    private let loadMoreRelay = PublishRelay<Void>()

    init() {
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

        let footer = UIActivityIndicatorView(style: .medium)
        footer.color = AppColor.onSurfaceVariant
        footer.frame = CGRect(x: 0, y: 0, width: detailView.tableView.bounds.width, height: 48)
        detailView.tableView.tableFooterView = footer
    }

    override func bind() {
        let input = Top100DetailViewModel.Input(
            viewDidLoad: Observable.just(()),
            itemSelected: detailView.tableView.rx.modelSelected(Music.self).asObservable(),
            loadMore: loadMoreRelay.asObservable()
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

        output.isLoadingMore
            .drive(onNext: { [weak self] isLoading in
                guard let footer = self?.detailView.tableView.tableFooterView as? UIActivityIndicatorView else { return }
                isLoading ? footer.startAnimating() : footer.stopAnimating()
            })
            .disposed(by: disposeBag)

        detailView.tableView.rx.willDisplayCell
            .subscribe(with: self) { owner, event in
                let (_, indexPath) = event
                let totalRows = owner.detailView.tableView.numberOfRows(inSection: 0)
                guard totalRows > 0, indexPath.row >= totalRows - 3 else { return }
                owner.loadMoreRelay.accept(())
            }
            .disposed(by: disposeBag)
    }
}
