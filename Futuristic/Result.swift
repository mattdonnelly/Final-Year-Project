//
//  Result.swift
//  Futuristic
//
//  Created by Matt Donnelly on 23/02/2015.
//  Copyright (c) 2015 Matt Donnelly. All rights reserved.
//

import Foundation

public class Box<T> {
    public let value: T
    public init(value: T) { self.value = value }
}

public enum Result<T> {
    case Success(Box<T>)
    case Failure(NSError)
    
    public init(_ value: T) {
        self = .Success(Box(value: value))
    }
    
    public var isSuccess: Bool {
        switch self {
        case .Success(_):
            return true
        case .Failure(_):
            return false
        }
    }
    
    public var isFailure: Bool {
        return !self.isSuccess
    }
    
    public var value: T? {
        switch self {
        case .Success(let box):
            return box.value
        default:
            return nil
        }
    }
    
    public var error: NSError? {
        switch self {
        case .Failure(let error):
            return error
        default:
            return nil
        }
    }
    
    public func map<U>(f: T -> U) -> Result<U> {
        switch self {
        case Success(let box):
            return Result<U>(f(box.value))
        case Failure(let error):
            return .Failure(error)
        }
    }

    public func flatMap<U>(f: T -> Result<U>) -> Result<U> {
        switch self {
        case Success(let box):
            return f(box.value)
        case Failure(let error):
            return .Failure(error)
        }
    }
}
