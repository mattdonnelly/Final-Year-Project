//
//  Promise.swift
//  Futurisitc
//
//  Created by Matt Donnelly on 15/02/2015.
//  Copyright (c) 2015 Matt Donnelly. All rights reserved.
//

import Foundation

public class Future<T> {
    
    public var result: Result<T>?

    public var isCompleted: Bool = false
    
    var successCallbacks: [T -> Void] = []
    var failureCallbacks: [NSError -> Void] = []
    var completeCallbacks: [Result<T> -> Void] = []
    
    internal init() { }
    
    public convenience init(f: () -> Result<T>) {
        self.init(queue: NSOperationQueue.mainQueue(), f)
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

    public func then<U>(transform: T -> Future<U>) -> Future<U> {
        let future = Future<U>()
        
        self.onComplete() { value in
            let newFuture: Future<U> = {
                switch value {
                case .Success(let wrapper):
                    return transform(wrapper())
                case .Failure(let error):
                    let newFuture = Future<U>()
                    newFuture.complete(.Failure(error))
                    return newFuture
                }
            }()
            
            newFuture.onComplete() { value in
                future.complete(value)
            }
        }

        return future
    }
    
    public func thenTry<U>(transform: Result<T> -> Future<U>) -> Future<U> {
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
            future.complete(value.then(transform))
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
    
    internal func complete(result: Result<T>) {
        if self.isCompleted {
            return
        }

        self.isCompleted = true
        self.result = result
        
        switch (result) {
        case .Success(let wrappedValue):
            for callback in self.successCallbacks {
                callback(wrappedValue())
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