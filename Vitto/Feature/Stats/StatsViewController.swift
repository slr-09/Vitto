import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class StatsViewController: BaseViewController {

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = AppSpacing.md
        return stack
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Stats"
        label.font = AppFont.displayLG
        label.textColor = AppColor.onBackground
        return label
    }()

    private let totalTimeSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "이번 주 총 들은 시간"
        label.font = AppFont.h4
        label.textColor = AppColor.onSurfaceVariant
        return label
    }()

    private let totalTimeCard: UIView = {
        let view = UIView()
        view.layer.cornerRadius = AppSpacing.Radius.lg
        view.backgroundColor = AppColor.surfaceVariant.withAlphaComponent(0.4)
        return view
    }()

    private let totalTimeView = AnimatedTimeView()

    private let sectionLabel: UILabel = {
        let label = UILabel()
        label.text = "이번 주 많이 들은 장르"
        label.font = AppFont.h4
        label.textColor = AppColor.onSurfaceVariant
        return label
    }()

    private let genreCard: UIView = {
        let view = UIView()
        view.layer.cornerRadius = AppSpacing.Radius.lg
        view.backgroundColor = AppColor.surfaceVariant.withAlphaComponent(0.4)
        return view
    }()

    private let genreStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = AppSpacing.lg
        return stack
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "이번 주 재생 기록이 없어요"
        label.font = AppFont.bodyMedium
        label.textColor = AppColor.onSurfaceVariant
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    // MARK: - Properties

    private let viewModel = StatsViewModel()

    // MARK: - Setup

    override func setupHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        [titleLabel, totalTimeSectionLabel, totalTimeCard, sectionLabel, genreCard, emptyLabel].forEach {
            contentStack.addArrangedSubview($0)
        }
        totalTimeCard.addSubview(totalTimeView)
        genreCard.addSubview(genreStack)
    }

    override func setupConstraints() {
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
        contentStack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(AppSpacing.screenHorizontal)
            $0.width.equalToSuperview().offset(-AppSpacing.screenHorizontal * 2)
        }
        totalTimeView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(AppSpacing.xl)
        }
        genreStack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(AppSpacing.xl)
        }
    }

    override func setupStyles() {
        contentStack.setCustomSpacing(AppSpacing.xs, after: titleLabel)
        contentStack.setCustomSpacing(AppSpacing.md, after: totalTimeSectionLabel)
        contentStack.setCustomSpacing(AppSpacing.lg, after: totalTimeCard)
        contentStack.setCustomSpacing(AppSpacing.md, after: sectionLabel)
    }

    // MARK: - Bind

    override func bind() {
        let input = StatsViewModel.Input(
            viewDidLoad: Observable.just(()),
            recordDidFinalize: PlaybackRecordService.shared.recordFinalized.asObservable()
        )
        let output = viewModel.transform(input: input)

        output.totalListenedMs
            .drive(onNext: { [weak self] ms in
                self?.totalTimeView.update(to: ms)
            })
            .disposed(by: disposeBag)

        output.topGenres
            .drive(onNext: { [weak self] items in
                self?.renderGenreRows(items)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Render

    private func renderGenreRows(_ items: [GenreRankItem]) {
        genreStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        genreCard.isHidden = items.isEmpty
        emptyLabel.isHidden = !items.isEmpty

        for item in items {
            let row = GenreRankRowView()
            row.configure(with: item)
            genreStack.addArrangedSubview(row)
        }
    }
}

// MARK: - GenreRankRowView

private final class GenreRankRowView: BaseView {

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.h2
        label.textColor = AppColor.onBackground
        return label
    }()

    private let percentLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.h3
        label.textAlignment = .right
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    private let barBackground: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.surfaceContainerHighest
        view.layer.cornerRadius = 6
        view.clipsToBounds = true
        return view
    }()

    private let barFill: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 6
        return view
    }()

    private var barFillWidthConstraint: Constraint?

    override func setupHierarchy() {
        [nameLabel, percentLabel, barBackground].forEach { addSubview($0) }
        barBackground.addSubview(barFill)
    }

    override func setupConstraints() {
        nameLabel.snp.makeConstraints {
            $0.leading.top.equalToSuperview()
        }

        percentLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalTo(nameLabel)
        }

        barBackground.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalTo(nameLabel.snp.bottom).offset(12)
            $0.bottom.equalToSuperview()
            $0.height.equalTo(12)
        }

        barFill.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            barFillWidthConstraint = $0.width.equalTo(barBackground).multipliedBy(0.0).constraint
        }
    }

    func configure(with item: GenreRankItem) {
        let color = rankColor(for: item.rank)
        nameLabel.text = item.name
        percentLabel.text = "\(Int((item.ratio * 100).rounded()))%"
        percentLabel.textColor = color
        barFill.backgroundColor = color

        barFillWidthConstraint?.deactivate()
        barFill.snp.makeConstraints {
            barFillWidthConstraint = $0.width.equalTo(barBackground).multipliedBy(item.ratio).constraint
        }
    }

    private func rankColor(for rank: Int) -> UIColor {
        switch rank {
        case 1: return AppColor.primaryRose
        case 2: return AppColor.secondary
        case 3: return AppColor.tertiary
        default: return AppColor.onSurfaceVariant
        }
    }
}
