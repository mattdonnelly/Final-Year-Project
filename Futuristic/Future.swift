//
//  Future.swift
//  Futuristic
//
//  Created by Matt Donnelly on 15/02/2015.
//  Copyright (c) 2015 Matt Donnelly. All rights reserved.
//

import Foundation

public func liftF<A, B>(f: A -> B) -> Future<A> -> Future<B> {
    return { $0.map { res in f(res) } }
}

public func zip<A, B>(f1: Future<A>, f2: Future<B>) -> Future<(A, B)> {
    let future = Future<(A, B)>()
    
    f1.onComplete { result1 in
        switch result1 {
        case .Failure(let err):
            future.complete(.Failure(err))
        case .Success(let boxedValue1):
            f2.onComplete { result2 in
                switch result2 {
                case .Failure(let err):
                    future.complete(.Failure(err))
                case .Success(let boxedValue2):
                  future.complete(Result((boxedValue1.value, boxedValue2.value)))
                }
            }
        }
    }
    
    return future
}

public class Future<T> {
    
    public var result: Result<T>?

    private var completionHandlers: [Result<T> -> Void] = []
    
    public var isCompleted: Bool {
        return self.result != nil
    }
    
    public var isPending: Bool {
        return self.result == nil
    }
    
    public var isSuccess: Bool {
        if let result = self.result {
            return result.isSuccess
        }
        return false
    }
    
    public var isFailure: Bool {
        if let result = self.result {
            return result.isFailure
        }
        return false
    }

    internal init() { }
    
    public convenience init(queue: dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), f: () -> T) {
        self.init(queue: queue, f: { Result(f()) })
    }
    
    public init(queue: dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), f: () -> Result<T>) {
        dispatch_async(queue) {
            self.complete(f())
        }
    }

    public func onComplete(callback: Result<T> -> Void) -> Future {
        if let result = self.result {
            callback(result)
        } else {
            self.completionHandlers.append(callback)
        }
        
        return self
    }
    
    public func onSuccess(callback: T -> Void) -> Future {
        return self.onComplete {
            if let value = $0.value {
                callback(value)
            }
        }
    }
    
    public func onFailure(callback: NSError -> Void) -> Future {
        return self.onComplete {
            if let error = $0.error {
                callback(error)
            }
        }
    }

    public func flatMap<U>(transform: T -> Future<U>) -> Future<U> {
        let future = Future<U>()
        
        self.onComplete() { value in
            let newFuture: Future<U>
            
            switch value {
            case .Success(let box):
                newFuture = transform(box.value)
            case .Failure(let error):
                newFuture = Future<U>()
                newFuture.complete(.Failure(error))
            }
            
            newFuture.onComplete() { value in
                future.complete(value)
            }
        }

        return future
    }
    
    public func tryFlatMap<U>(transform: Result<T> -> Future<U>) -> Future<U> {
        let future = Future<U>()
        
        self.onComplete() { value1 in
            let newFuture = transform(value1)
            newFuture.onComplete() { value2 in
                future.complete(value2)
            }
        }

        return future
    }
    
    public func map<U>(transform: T -> U) -> Future<U> {
        let future = Future<U>()
        
        self.onSuccess { _ in
            future.complete(self.result!.map(transform))
            return
        }

        return future
    }
    
    public func tryMap<U>(transform: Result<T> -> Result<U>) -> Future<U> {
        let future = Future<U>()
        
        self.onComplete{ value in
            future.complete(transform(value))
        }

        return future
    }
    
    public func wait(timeout: dispatch_time_t = DISPATCH_TIME_FOREVER) -> Future<T> {
        let sem = dispatch_semaphore_create(0)
        
        self.onComplete { _ in
            dispatch_semaphore_signal(sem)
            return
        }
        
        dispatch_semaphore_wait(sem, timeout)
        
        return self
    }
    
    internal func complete(result: Result<T>) {
        if self.isCompleted {
            return
        }

        self.result = result
        
        for callback in self.completionHandlers {
            callback(self.result!)
        }
        
        self.completionHandlers.removeAll(keepCapacity: false)
    }
}
