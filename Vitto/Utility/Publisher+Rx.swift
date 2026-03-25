import Combine
import RxSwift

extension Publisher {
    func asObservable() -> Observable<Output> {
        Observable.create { observer in
            let cancellable = self.sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        observer.onError(error)
                    } else {
                        observer.onCompleted()
                    }
                },
                receiveValue: { value in
                    observer.onNext(value)
                }
            )
            return Disposables.create { cancellable.cancel() }
        }
    }
}
