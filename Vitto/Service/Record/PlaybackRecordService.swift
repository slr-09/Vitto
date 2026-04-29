import CoreData
import RxSwift
import RxCocoa

final class PlaybackRecordService {

    static let shared = PlaybackRecordService()

    var recordFinalized: Observable<Void> { _recordFinalized.asObservable() }
    private let _recordFinalized = PublishRelay<Void>()

    private let stack = CoreDataStack.shared
    private let weatherService = WeatherService.shared
    private let disposeBag = DisposeBag()
    private init() {}

    // MARK: - 기록 생성/종료

    /// 재생 시작 시 호출 — PlaybackRecord를 생성하고 반환
    func startRecord(music: Music, mood: WeatherCategory) -> PlaybackRecord {
        let ctx = stack.context
        let musicEntity = MusicEntity.findOrCreate(from: music, in: ctx)

        let record = PlaybackRecord(
            entity: NSEntityDescription.entity(forEntityName: "PlaybackRecord", in: ctx)!,
            insertInto: ctx
        )
        record.id = UUID()
        record.music = musicEntity
        record.startedAt = Date()
        record.moodRawValue = mood.rawValue

        stack.saveContext()
        attachWeather(to: record)
        return record
    }

    /// 날씨 정보를 비동기로 조회하여 record에 저장 (실패 시 무시)
    private func attachWeather(to record: PlaybackRecord) {
        weatherService.fetchCurrentWeather()
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, snapshot in
                record.weatherCondition = snapshot.condition
                record.weatherTemperature = snapshot.temperature
                owner.stack.saveContext()
            } onError: { owner, error in
                print("[PlaybackRecordService] 날씨 저장 실패 : \(error.localizedDescription)")
            }
            .disposed(by: disposeBag)
    }

    /// 재생 종료 시 호출 — 완청률, 스킵 여부 계산 후 저장
    /// isPreview가 true이면 미리듣기 길이 기준으로 판정
    func endRecord(_ record: PlaybackRecord, listenedMs: Int, totalMs: Int, isPreview: Bool = false) {
        record.listenedDurationMs = Int32(listenedMs)

        let rate = totalMs > 0 ? Float(listenedMs) / Float(totalMs) : 0
        record.completionRate = min(rate, 1.0)

        if isPreview {
            // 미리듣기: 미리듣기 길이 대비 80% 이상 들으면 완청, 50% 미만이면 스킵
            record.isCompleted = rate >= 0.8
            record.isSkipped = rate < 0.5
            print(record)
        } else {
            // 정식 재생: 기존 기준
            record.isCompleted = rate >= 0.9
            record.isSkipped = listenedMs < 30_000
        }

        stack.saveContext()
        _recordFinalized.accept(())
    }

    // MARK: - 쿼리: 무드 기반

    /// 특정 무드에서 스킵하지 않고 들은 곡 조회
    func songs(forMood mood: WeatherCategory) -> Observable<[Music]> {
        Observable<[Music]>.async { [weak self] in
            guard let self else { return [] }
            let ctx = self.stack.newBackgroundContext()

            return try await ctx.perform {
                let request = NSFetchRequest<PlaybackRecord>(entityName: "PlaybackRecord")
                request.predicate = NSPredicate(
                    format: "moodRawValue == %@ AND isSkipped == NO",
                    mood.rawValue
                )
                request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
                request.relationshipKeyPathsForPrefetching = ["music"]

                let records = try ctx.fetch(request)
                return self.uniqueSongs(from: records)
            }
        }
        .observe(on: MainScheduler.instance)
    }

    // MARK: - 쿼리: 날씨 기반

    /// 최근 N일간 특정 날씨에서 스킵하지 않고 들은 곡을 재생 횟수 기준으로 반환
    func songsForWeather(
        _ weather: WeatherCategory,
        days: Int = 30,
        limit: Int = 20
    ) -> Observable<[(music: Music, playCount: Int)]> {
        Observable<[(music: Music, playCount: Int)]>.async { [weak self] in
            guard let self else { return [] }
            let ctx = self.stack.newBackgroundContext()

            return try await ctx.perform {
                let request = NSFetchRequest<PlaybackRecord>(entityName: "PlaybackRecord")
                let cutoffDate = DateManager.shared.daysAgo(days)
                request.predicate = NSPredicate(
                    format: "isSkipped == NO AND startedAt >= %@ AND moodRawValue == %@",
                    cutoffDate as NSDate,
                    weather.rawValue
                )
                request.relationshipKeyPathsForPrefetching = ["music"]

                let records = try ctx.fetch(request)
                return self.rankByPlayCount(records: records, limit: limit)
            }
        }
        .observe(on: MainScheduler.instance)
    }

    // MARK: - 쿼리: 가장 많이 들은 곡

    /// 완청 횟수 기준 상위 곡 (반복 재생 탐지)
    func mostPlayedSongs(limit: Int = 20) -> Observable<[(music: Music, playCount: Int)]> {
        Observable<[(music: Music, playCount: Int)]>.async { [weak self] in
            guard let self else { return [] }
            let ctx = self.stack.newBackgroundContext()

            return try await ctx.perform {
                let request = NSFetchRequest<PlaybackRecord>(entityName: "PlaybackRecord")
                request.predicate = NSPredicate(format: "isSkipped == NO")
                request.relationshipKeyPathsForPrefetching = ["music"]

                let records = try ctx.fetch(request)
                return self.rankByPlayCount(records: records, limit: limit)
            }
        }
        .observe(on: MainScheduler.instance)
    }

    // MARK: - 쿼리: 시간대 기반

    /// 최근 N일간 특정 시간대에 스킵하지 않고 들은 곡을 재생 횟수 기준으로 반환
    func songsForTimePeriod(
        _ period: TimePeriod,
        days: Int = 30,
        limit: Int = 20
    ) -> Observable<[(music: Music, playCount: Int)]> {
        Observable<[(music: Music, playCount: Int)]>.async { [weak self] in
            guard let self else { return [] }
            let ctx = self.stack.newBackgroundContext()

            return try await ctx.perform {
                let request = NSFetchRequest<PlaybackRecord>(entityName: "PlaybackRecord")
                let cutoffDate = DateManager.shared.daysAgo(days)
                request.predicate = NSPredicate(
                    format: "isSkipped == NO AND startedAt >= %@",
                    cutoffDate as NSDate
                )
                request.relationshipKeyPathsForPrefetching = ["music"]

                let records = try ctx.fetch(request)
                return self.rankByPlayCount(records: records, period: period, limit: limit)
            }
        }
        .observe(on: MainScheduler.instance)
    }

    // MARK: - 쿼리: 장르별 선호도

    /// 완청률이 높은 상위 장르 목록
    func topGenres(limit: Int = 10) -> Observable<[(genre: String, avgCompletionRate: Float, playCount: Int)]> {
        Observable<[(genre: String, avgCompletionRate: Float, playCount: Int)]>.async { [weak self] in
            guard let self else { return [] }
            let ctx = self.stack.newBackgroundContext()

            return try await ctx.perform {
                let request = NSFetchRequest<PlaybackRecord>(entityName: "PlaybackRecord")
                request.predicate = NSPredicate(format: "isSkipped == NO")
                request.relationshipKeyPathsForPrefetching = ["music"]

                let records = try ctx.fetch(request)

                var genreStats: [String: (totalRate: Float, count: Int)] = [:]
                for record in records {
                    let genres = record.music?.genres ?? []
                    for genre in genres where !genre.isEmpty {
                        let existing = genreStats[genre] ?? (0, 0)
                        genreStats[genre] = (existing.totalRate + record.completionRate, existing.count + 1)
                    }
                }

                return genreStats
                    .map { (genre: $0.key, avgCompletionRate: $0.value.totalRate / Float($0.value.count), playCount: $0.value.count) }
                    .sorted { $0.playCount > $1.playCount }
                    .prefix(limit)
                    .map { $0 }
            }
        }
        .observe(on: MainScheduler.instance)
    }

    // MARK: - Private Helpers

    /// 시간대 필터링 → musicID별 그룹핑 → 재생 횟수 정렬 → 상위 limit개만 toMusic() 변환
    private func rankByPlayCount(
        records: [PlaybackRecord],
        period: TimePeriod,
        limit: Int
    ) -> [(music: Music, playCount: Int)] {
        // 시간대 필터 + musicID별 카운트 (MusicEntity 참조만 유지, 변환은 아직 안 함)
        var countMap: [String: (entity: MusicEntity, count: Int)] = [:]
        for record in records {
            guard let date = record.startedAt,
                  period.containsHour(DateManager.shared.hour(from: date)),
                  let entity = record.music,
                  let id = entity.musicID else { continue }

            let existing = countMap[id, default: (entity, 0)]
            countMap[id] = (existing.entity, existing.count + 1)
        }

        // 정렬 후 상위 limit개에 대해서만 toMusic() 실행
        return countMap.values
            .sorted { $0.count > $1.count }
            .prefix(limit)
            .map { (music: $0.entity.toMusic(), playCount: $0.count) }
    }

    /// musicID별 그룹핑 → 재생 횟수 정렬 → 상위 limit개만 toMusic() 변환
    private func rankByPlayCount(
        records: [PlaybackRecord],
        limit: Int
    ) -> [(music: Music, playCount: Int)] {
        var countMap: [String: (entity: MusicEntity, count: Int)] = [:]
        for record in records {
            guard let entity = record.music,
                  let id = entity.musicID else { continue }

            let existing = countMap[id, default: (entity, 0)]
            countMap[id] = (existing.entity, existing.count + 1)
        }

        return countMap.values
            .sorted { $0.count > $1.count }
            .prefix(limit)
            .map { (music: $0.entity.toMusic(), playCount: $0.count) }
    }

    /// PlaybackRecord 배열에서 중복 없는 Music 배열 추출
    private func uniqueSongs(from records: [PlaybackRecord]) -> [Music] {
        var seen = Set<String>()
        var result: [Music] = []
        for record in records {
            guard let entity = record.music, let id = entity.musicID, !seen.contains(id) else { continue }
            seen.insert(id)
            result.append(entity.toMusic())
        }
        return result
    }
}
