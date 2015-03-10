//
//  main.swift
//  Futurisitc
//
//  Created by Matt Donnelly on 15/02/2015.
//  Copyright (c) 2015 Matt Donnelly. All rights reserved.
//

import Foundation

let sem = dispatch_semaphore_create(0)

let promise1 = Promise<Int>()

promise1.future.onSuccess{ res in
        println(res)
    }
    .then { res -> Future<Int> in
        let promise2 = Promise<Int>()
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
    
        dispatch_after(delayTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            promise2.resolve(2)
            dispatch_semaphore_signal(sem)
        }
    
        return promise2.future
    }
    .onSuccess { res2 in
        println(res2)
    }

promise1.resolve(1)

dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
