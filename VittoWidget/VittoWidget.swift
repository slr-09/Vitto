//
//  VittoWidget.swift
//  VittoWidget
//
//  Created by 가은 on 4/6/26.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct Top100Entry: TimelineEntry {
    let date: Date
    let songs: [Top100Song]
}

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    /// 위젯 로딩 중 표시할 placeholder
    func placeholder(in context: Context) -> Top100Entry {
        Top100Entry(date: Date(), songs: [])
    }

    /// 위젯 갤러리 미리보기용 스냅샷
    func getSnapshot(in context: Context, completion: @escaping (Top100Entry) -> ()) {
        let songs = UserDefaults.groupShared.top100Songs
        completion(Top100Entry(date: Date(), songs: songs))
    }

    /// 매 정각마다 갱신되는 타임라인 생성
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let now = Date()
        let songs = UserDefaults.groupShared.top100Songs
        let entry = Top100Entry(date: now, songs: songs)

        let nextHour = Calendar.current.dateInterval(of: .hour, for: now)!.end
        let timeline = Timeline(entries: [entry], policy: .after(nextHour))
        completion(timeline)
    }
}

// MARK: - Widget View

struct VittoWidgetEntryView: View {
    var entry: Top100Entry

    @Environment(\.widgetFamily) var family

    /// 위젯 사이즈별 표시 곡 수
    private var songCount: Int {
        switch family {
        case .systemSmall, .systemMedium: return 3
        default: return 3
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Top 100")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(Self.timeFormatter.string(from: entry.date) + " 업데이트")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .padding(.bottom, 6)

            if entry.songs.isEmpty {
                Spacer()
                Text("앱을 실행하면 차트가 표시됩니다")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                let songs = Array(entry.songs.prefix(songCount))

                ForEach(Array(songs.enumerated()), id: \.element.musicID) { index, song in
                    HStack(spacing: 8) {
                        Text("\(song.rank)")
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 20, alignment: .center)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(song.title)
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)
                            Text(song.artist)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 3)

                    if index < songs.count - 1 {
                        Divider()
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }
}

struct VittoWidget: Widget {
    let kind: String = "VittoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                VittoWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                VittoWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Vitto Top 100")
        .description("실시간 Top 100 차트를 확인하세요.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    VittoWidget()
} timeline: {
    Top100Entry(date: .now, songs: [
        Top100Song(rank: 1, musicID: "1", title: "APT.", artist: "ROSÉ & Bruno Mars", artworkUrl: ""),
        Top100Song(rank: 2, musicID: "2", title: "Die With A Smile", artist: "Lady Gaga & Bruno Mars", artworkUrl: ""),
        Top100Song(rank: 3, musicID: "3", title: "Espresso", artist: "Sabrina Carpenter", artworkUrl: ""),
    ])
}

#Preview(as: .systemMedium) {
    VittoWidget()
} timeline: {
    Top100Entry(date: .now, songs: [
        Top100Song(rank: 1, musicID: "1", title: "APT.", artist: "ROSÉ & Bruno Mars", artworkUrl: ""),
        Top100Song(rank: 2, musicID: "2", title: "Die With A Smile", artist: "Lady Gaga & Bruno Mars", artworkUrl: ""),
        Top100Song(rank: 3, musicID: "3", title: "Espresso", artist: "Sabrina Carpenter", artworkUrl: ""),
        Top100Song(rank: 4, musicID: "4", title: "Birds of a Feather", artist: "Billie Eilish", artworkUrl: ""),
        Top100Song(rank: 5, musicID: "5", title: "That's So True", artist: "Gracie Abrams", artworkUrl: ""),
    ])
}
