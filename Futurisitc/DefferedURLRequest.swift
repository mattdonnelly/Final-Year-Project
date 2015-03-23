//
//  DefferedURLRequest.swift
//  Futurisitc
//
//  Created by Matt Donnelly on 23/03/2015.
//  Copyright (c) 2015 Matt Donnelly. All rights reserved.
//

import Foundation

class DefferedURLRequest {

    class func requestWithURL(URL: NSURL) -> Future<NSData> {
        let promise = Promise<NSData>()
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(URL, completionHandler: { data, response, error in
            if error == nil {
                promise.resolve(data)
            }
            else {
                promise.reject(error)
            }
        })
        
        task.resume()
        
        return promise.future
    }

}
