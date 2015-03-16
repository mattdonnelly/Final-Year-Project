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

func filterRepos(a: Future<JSON>) -> Future<[Repository]> {
    return a.map {
        let optionalFiltered = $0["items"].array?.filter {
            let star_count = $0["stargazers_count"].integer!
            return star_count > 1000
        }
        
        if let filtered = optionalFiltered {
            return .Success(filtered)
        }
        else {
            return .Failure(NSError())
        }
    }
}

func countRepos(a: Future<[JSON]>) -> Future<Int> {
    return a.map {
        .Success($0.count)
    }
    .onSuccess {
        println("Number of Swift repos with 1000+ stars: " + String($0))
    }
    .onFailure {
        println($0)
    }
}

let promise = Promise<NSData>()

promise.future |> parseJSON >>> filterRepos >>> countRepos

startRequest(promise)
