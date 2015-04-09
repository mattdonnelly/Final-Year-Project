//
//  Future.swift
//  Futuristic
//
//  Created by Matt Donnelly on 15/02/2015.
//  Copyright (c) 2015 Matt Donnelly. All rights reserved.
//

import Foundation

public func future<T>(task: () -> Result<T>) -> Future<T> {
    return future(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), task)
}

public func future<T>(queue: dispatch_queue_t, task: () -> Result<T>) -> Future<T> {
    let promise = Promise<T>()
    
    dispatch_async(queue) {
        let result = task()
        switch result {
        case .Success(let box):
            promise.resolve(box.value)
        case .Failure(let error):
            promise.reject(error)
        }
    }
    
    return promise.future
}

public class Future<T> {
    
    public var result: Result<T>?

    public var isCompleted: Bool = false
    
    var successCallbacks: [T -> Void] = []
    var failureCallbacks: [NSError -> Void] = []
    var completeCallbacks: [Result<T> -> Void] = []
    
    internal init() { }
    
    public convenience init(f: () -> Result<T>) {
        self.init(queue: NSOperationQueue.mainQueue(), f: f)
    }
    
    public init(queue: NSOperationQueue, f: () -> Result<T>) {
        queue.addOperationWithBlock() {
            self.complete(f())
        }
    }

    public func onComplete(callback: Result<T> -> Void) -> Future {
        if self.isCompleted {
            callback(self.result!)
        } else {
            self.completeCallbacks.append(callback)
        }
        
        return self
    }
    
    public func onSuccess(callback: T -> Void) -> Future {
        if self.isCompleted {
            if let value = self.result?.value {
                callback(value)
            }
        } else {
            self.successCallbacks.append(callback)
        }
        
        return self
    }
    
    public func onFailure(callback: NSError -> Void) -> Future {
        if self.isCompleted {
            if let error = self.result?.error {
                callback(error)
            }
        } else {
            self.failureCallbacks.append(callback)
        }
        
        return self
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
    
    public func map<U>(transform: T -> Result<U>) -> Future<U> {
        let future = Future<U>()
        
        self.onComplete { value in
            future.complete(value.flatMap(transform))
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
    
    public func zip<U>(f: Future<U>) -> Future<(T,U)> {
        let promise = Promise<(T,U)>()
        
        self.onComplete { result in
            switch result {
            case .Failure(let err):
                promise.reject(err)
            case .Success(let box1):
                f.onComplete { result2 in
                    switch result2 {
                    case .Failure(let err):
                        promise.reject(err)
                    case .Success(let box2):
                        let resultTuple = (box1.value, box2.value)
                        promise.resolve(resultTuple)
                    }
                }
            }
            return
        }
        
        return promise.future
    }
    
    public func wait(timeout: dispatch_time_t = DISPATCH_TIME_FOREVER) -> Future<T> {
        let sem = dispatch_semaphore_create(0)
        
        self.onSuccess { _ in
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

        self.isCompleted = true
        self.result = result
        
        switch (result) {
        case .Success(let box):
            for callback in self.successCallbacks {
                callback(box.value)
            }
        case .Failure(let error):
            for callback in self.failureCallbacks {
                callback(error)
            }
        }
        
        for callback in self.completeCallbacks {
            callback(self.result!)
        }
        
        self.successCallbacks.removeAll(keepCapacity: false)
        self.failureCallbacks.removeAll(keepCapacity: false)
        self.completeCallbacks.removeAll(keepCapacity: false)
    }
}