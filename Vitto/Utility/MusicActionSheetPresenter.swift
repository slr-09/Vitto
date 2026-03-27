import UIKit
import RxSwift

enum MusicActionSheetPresenter {

    static func show(for music: Music, from presenter: UIViewController, disposeBag: DisposeBag) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "현재 재생목록에 추가", style: .default) { _ in
            MusicService.shared.addToQueue(music: music)
                .subscribe(onError: { error in
                    print("큐 추가 에러: \(error)")
                })
                .disposed(by: disposeBag)
        })

        alert.addAction(UIAlertAction(title: "플레이리스트에 추가", style: .default) { [weak presenter] _ in
            let picker = PlaylistPickerViewController(music: music)
            presenter?.present(picker, animated: true)
        })

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        presenter.present(alert, animated: true)
    }
}
