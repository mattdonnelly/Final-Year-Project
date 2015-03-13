//
//  Promise.swift
//  Futurisitc
//
//  Created by Matt Donnelly on 09/03/2015.
//  Copyright (c) 2015 Matt Donnelly. All rights reserved.
//

import Foundation

public class Promise<T> {
    public let future: Future<T> = Future()
    
    public init() { }
    
    public init(_ future: Future<T>) {
        self.future = future
    }
    
    public func resolve(value: T) {
        future.complete(Result(value))
    }
    
    public func reject(error: NSError) {
        future.complete(.Failure(error))
    }
}
