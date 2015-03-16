//
//  main.swift
//  Futurisitc
//
//  Created by Matt Donnelly on 15/02/2015.
//  Copyright (c) 2015 Matt Donnelly. All rights reserved.
//

import Foundation

typealias Repository = JSON

func startRequest(promise: Promise<NSData>) {
    let sem = dispatch_semaphore_create(0)
    
    let requestURL = NSURL(string: "https://api.github.com/search/repositories?q=language:swift&sort=stars&order=desc")
    let task = NSURLSession.sharedSession().dataTaskWithURL(requestURL!, completionHandler: { data, response, error in
        if error == nil {
            promise.resolve(data)
        }
        else {
            promise.reject(error)
        }
        
        dispatch_semaphore_signal(sem)
    })
    
    task.resume()
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
}

func parseJSON(a: Future<NSData>) -> Future<JSON> {
    return a.map { res in .Success(JSON(res)) }
}

func filterRepos(count: Int)(a: Future<JSON>) -> Future<[Repository]> {
    return a.map {
        let optionalFiltered = $0["items"].array?.filter {
            let star_count = $0["stargazers_count"].integer!
            return star_count > count
        }
        
        if let filtered = optionalFiltered {
            return .Success(filtered)
        }
        else {
            let userInfo = [
                NSLocalizedDescriptionKey: NSLocalizedString("Repo filter failed", comment: ""),
                NSLocalizedFailureReasonErrorKey: NSLocalizedString("Could not unwrap optional value", comment: ""),
                NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Check request data", comment: "")
            ]
            return .Failure(NSError(domain: "com.mattdonnelly.demo", code: 1, userInfo: userInfo))
        }
    }
}

func countRepos(a: Future<[JSON]>) -> Future<Int> {
    return a.map { .Success($0.count) }
}

let promise = Promise<NSData>()

let countFuture = promise.future |> parseJSON >>> filterRepos(1000) >>> countRepos

countFuture.onSuccess {
    println("Number of Swift repos with 1000+ stars: " + String($0))
}
.onFailure {
    println($0)
}

startRequest(promise)
