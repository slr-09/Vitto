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

    private let streakSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "연속 청취일"
        label.font = AppFont.h4
        label.textColor = AppColor.onSurfaceVariant
        return label
    }()

    private let streakCard: UIView = {
        let view = UIView()
        view.layer.cornerRadius = AppSpacing.Radius.lg
        view.backgroundColor = AppColor.surfaceVariant.withAlphaComponent(0.4)
        return view
    }()

    private let streakValueLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.displayXL
        label.textColor = AppColor.onBackground
        label.textAlignment = .center
        label.text = "0일"
        return label
    }()

    private let streakCaptionLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bodySmall
        label.textColor = AppColor.onSurfaceVariant
        label.textAlignment = .center
        label.text = "꾸준히 음악을 들은 날"
        return label
    }()

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

    private let genreBubbleChartView = GenreBubbleChartView()

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
        [titleLabel, totalTimeSectionLabel, totalTimeCard, streakSectionLabel, streakCard, sectionLabel, genreCard, emptyLabel].forEach {
            contentStack.addArrangedSubview($0)
        }
        totalTimeCard.addSubview(totalTimeView)
        streakCard.addSubview(streakValueLabel)
        streakCard.addSubview(streakCaptionLabel)
        genreCard.addSubview(genreBubbleChartView)
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
        streakValueLabel.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview().inset(AppSpacing.xl)
        }
        streakCaptionLabel.snp.makeConstraints {
            $0.top.equalTo(streakValueLabel.snp.bottom).offset(AppSpacing.xs)
            $0.horizontalEdges.bottom.equalToSuperview().inset(AppSpacing.xl)
        }
        genreBubbleChartView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(300)
        }
    }

    override func setupStyles() {
        contentStack.setCustomSpacing(AppSpacing.xs, after: titleLabel)
        contentStack.setCustomSpacing(AppSpacing.md, after: totalTimeSectionLabel)
        contentStack.setCustomSpacing(AppSpacing.lg, after: totalTimeCard)
        contentStack.setCustomSpacing(AppSpacing.md, after: streakSectionLabel)
        contentStack.setCustomSpacing(AppSpacing.lg, after: streakCard)
        contentStack.setCustomSpacing(AppSpacing.md, after: sectionLabel)
        genreCard.isHidden = true
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

        output.streakDays
            .drive(onNext: { [weak self] days in
                self?.streakValueLabel.text = "\(days)일"
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
        genreCard.isHidden = items.isEmpty
        emptyLabel.isHidden = !items.isEmpty
        genreBubbleChartView.configure(with: items)
    }
}
