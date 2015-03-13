//
//  Arrows.swift
//  Futurisitc
//
//  Created by Matt Donnelly on 13/03/2015.
//  Copyright (c) 2015 Matt Donnelly. All rights reserved.
//

import Foundation

infix operator |>  { }
infix operator >>> { }
infix operator *** { }
infix operator &&& { }

/** 
 *  A -> [f] -> B
 */
func |> <A, B>(param: @autoclosure () -> A, f: A -> B) -> B {
    return f(param())
}

/**
 *  A -> [f] -> B -> [g] -> C
 */
func >>> <A, B, C>(f: Future<A> -> Future<B>, g: Future<B> -> Future<C>) -> (Future<A> -> Future<C>) {
    return { g(f($0)) }
}

/**
 *  A -> [f] -> C
 *  B -> [g] -> D
 */
func *** <A, B, C, D>(f: Future<A> -> Future<B>, g: Future<C> -> Future<D>) -> ((Future<A>, Future<C>) -> (Future<B>, Future<D>)) {
    return { (f($0), g($1)) }
}

/**
 *  A ---> [f] -> B
 *     |
 *      -> [g] -> C
 */
func &&& <A, B, C>(f: Future<A> -> Future<B>, g: Future<A> -> Future<C>) -> (Future<A> -> (Future<B>, Future<C>)) {
    return { (f($0), g($0)) }
}

/**
 *  A -> [f] -> C
 *  B --------> B
 */
func first<A, B, C>(f: Future<A> -> Future<C>) -> ((Future<A>, Future<B>) -> (Future<C>, Future<B>)) {
    return { (f($0), $1) }
}

/**
 *  A --------> A
 *  B -> [f] -> C
 */
func second<A, B, C>(f: Future<B> -> Future<C>) -> ((Future<A>, Future<B>) -> (Future<A>, Future<C>)) {
    return { ($0, f($1)) }
}
