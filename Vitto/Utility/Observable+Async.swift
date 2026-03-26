//
//  Observable+Async.swift
//  Vitto
//
//  Created by 가은 on 3/26/26.
//

import RxSwift

extension Observable {
    static func async(_ work: @escaping () async throws -> Element) -> Observable<Element> {
        return Observable.create { observer in
            let task = Task {
                do {
                    let result = try await work()
                    // 작업 도중 취소 확인
                    try Task.checkCancellation()
                    
                    observer.onNext(result)
                    observer.onCompleted()
                } catch {
                    // 취소가 아닌 경우
                    if !(error is CancellationError) {
                        observer.onError(error)
                    }
                }
            }
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
}
