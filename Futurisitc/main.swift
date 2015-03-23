//
//  main.swift
//  Futurisitc
//
//  Created by Matt Donnelly on 15/02/2015.
//  Copyright (c) 2015 Matt Donnelly. All rights reserved.
//

import Foundation

typealias Repository = JSON

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

func printComplete(sem: dispatch_semaphore_t)(a: Future<Int>) -> Future<Int> {
    return a.onSuccess {
        println("Number of Swift repos with 1000+ stars: " + String($0))
    }
    .onFailure {
        println($0)
    }
    .onSuccess { _ in
        dispatch_semaphore_signal(sem)
        return
    }
}


func main() {

}

let sem = dispatch_semaphore_create(0)

let requestURL = NSURL(string: "https://api.github.com/search/repositories?q=language:swift&sort=stars&order=desc")

DefferedURLRequest.requestWithURL(requestURL!) |> parseJSON
                                               >>> filterRepos(1000)
                                               >>> countRepos
                                               >>> printComplete(sem)

dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
