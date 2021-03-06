//
//  main.swift
//  Futuristic
//
//  Created by Matt Donnelly on 15/02/2015.
//  Copyright (c) 2015 Matt Donnelly. All rights reserved.
//

import Foundation

typealias Repository = JSON

func parseJSON(a: NSData) -> JSON {
    return JSON(a)
}

func filterRepos(count: Int)(json: JSON) -> [Repository] {
    return json["items"].array!.filter {
        let star_count = $0["stargazers_count"].integer!
        return star_count > count
    }
}

func countRepos(repos: [Repository]) -> Int {
    return repos.count
}

let requestURL = NSURL(string: "https://api.github.com/search/repositories?q=language:swift&sort=stars&order=desc")

let future = DeferredURLRequest.requestWithURL(requestURL!) ~> (parseJSON
                                                            >>> filterRepos(1000)
                                                            >>> countRepos)
future.onSuccess {
    println("Number of Swift repos with 1000+ stars: " + String($0))
}
.onFailure {
    println($0)
}

future.wait()

