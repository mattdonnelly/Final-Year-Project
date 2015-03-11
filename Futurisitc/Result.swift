//
//  Result.swift
//  Futurisitc
//
//  Created by Matt Donnelly on 23/02/2015.
//  Copyright (c) 2015 Matt Donnelly. All rights reserved.
//

import Foundation

public final class Box<T> {
    public let value: T
    
    public init(_ value: T) {
        self.value = value
    }
}

public enum Result<T> {
    case Success(Box<T>)
    case Failure(NSError)
    
    public init(_ value: T) {
        self = .Success(Box(value))
    }
    
    public var isSuccess: Bool {
        get {
            switch self {
            case .Success(_):
                return true
            case .Failure(_):
                return false
            }
        }
    }
    
    public var isFailure: Bool {
        get {
            return !self.isSuccess
        }
    }
    
    public var value: T? {
        get {
            switch self {
            case .Success(let boxedValue):
                return boxedValue.value
            default:
                return nil
            }
        }
    }
    
    public var error: NSError? {
        get {
            switch self {
            case .Failure(let error):
                return error
            default:
                return nil
            }
        }
    }

    public func then<U>(f: T -> Result<U>) -> Result<U> {
        switch self {
        case Success(let boxedValue):
            return f(boxedValue.value)
        case Failure(let error):
            return .Failure(error)
        }
    }
    
    public func map<U>(f: T -> U) -> Result<U> {
        switch self {
        case Success(let boxedValue):
            return Result<U>(f(boxedValue.value))
        case Failure(let error):
            return .Failure(error)
        }
    }
}
