# Vitto 🎵

Vitto는 지금의 날씨와 나의 취향에 맞춰 음악을 추천하고,
Apple Music으로 차트 탐색·검색·미리듣기·청취 통계까지 즐길 수 있는 iOS 앱입니다.

<a href="https://apps.apple.com/kr/app/vitto/id6761290475">
  <img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="Download on the App Store" height="40">
</a>

- 👤 **개인 프로젝트**
- 📅 **개발 기간** : 2026.03 ~ 진행 중
- 📱 **지원** : iOS 17.0+ / iPhone 세로 / iPad 세로·가로

</br>

## 🎯 프로젝트 목적

음악을 들을 때의 분위기는 그날의 날씨에 크게 좌우됩니다.
</br>
맑은 날과 비 오는 날에 어울리는 음악이 다르듯, **그 순간에 맞는 음악**을 찾고 싶었습니다.

Vitto는 현재 위치의 날씨와 나의 청취 기록을 함께 읽어,
</br>
수많은 곡 중에서 **지금 이 순간에 어울리는 음악을 먼저 건네는 것**을 목표로 합니다.

</br>

## ✨ 주요 기능

- 🌤️ **날씨 기반 추천** — 현재 위치의 날씨 무드에 어울리는 음악 추천
- 🧩 **위젯** — Top100 차트를 홈 화면 위젯에서 매시간 갱신
- 🔎 **검색** — 곡 검색, 장르별 탐색, 최근 검색어 기록
- 🎧 **미리듣기 플레이어** — 곡 미리듣기 재생 및 잠금화면·제어센터 미디어 컨트롤 연동
- 📂 **플레이리스트** — 나만의 플레이리스트 생성 및 곡 관리
- 📊 **청취 통계** — 재생 기록 기반 청취 시간·장르 분포 시각화

</br>

## 🛠 기술 스택

- **언어 / UI** : Swift, UIKit, SnapKit
- **아키텍처** : MVVM (Input/Output)
- **비동기 / 상태 관리** : RxSwift, RxCocoa
- **음악 / 날씨** : MusicKit, WeatherKit, CoreLocation
- **재생** : AVFoundation, MediaPlayer
- **위젯** : WidgetKit
- **이미지** : Kingfisher
- **로컬 저장** : CoreData
- **의존성 관리** : Swift Package Manager

</br>

## 🏗 프로젝트 구조

기능 단위(Feature)로 모듈을 나누어 구성했습니다.

```
Vitto/
├── Feature/
│   ├── Home/
│   ├── Search/
│   ├── Playlist/
│   ├── Player/
│   ├── Stats/
│   └── TabBar/
├── Service/
├── Model/
├── CoreData/
├── Shared/
├── Common/
├── Utility/
└── Resources/

VittoWidget/
```
