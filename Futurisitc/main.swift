//
//  main.swift
//  Futurisitc
//
//  Created by Matt Donnelly on 15/02/2015.
//  Copyright (c) 2015 Matt Donnelly. All rights reserved.
//

import Foundation

func step1(a: Future<Int>) -> Future<Bool> {
    return a.map {
        return .Success($0 & 1 == 0)
    }
}

func step2(a: Future<Bool>) -> Future<String> {
    return a.map {
        if $0 {
            return .Success("Even")
        }
        else {
            return .Success("Odd")
        }
    }
    .onSuccess {
        println($0)
    }
}

let sem = dispatch_semaphore_create(0)

let promise1 = Promise<Int>()

promise1.future |> (step1 >>> step2)

let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))

dispatch_after(delayTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
    promise1.resolve(2)
    dispatch_semaphore_signal(sem)
}

dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
