//
//  Arrows.swift
//  Futuristic
//
//  Created by Matt Donnelly on 13/03/2015.
//  Copyright (c) 2015 Matt Donnelly. All rights reserved.
//

import Foundation

infix operator |>  { associativity left  precedence 100 }
infix operator <|  { associativity right precedence 100 }
infix operator >>> { associativity left  precedence 150 }
infix operator *** { associativity left  precedence 200 }
infix operator &&& { associativity left  precedence 200 }

/** 
 *  A ──▶ [f] ──▶ B
 */
func |> <A, B>(left: A, right: A -> B) -> B {
    return right(left)
}

/**
 *  B ◀── [f] ◀── A
 */
func <| <A, B>(left: A -> B, right: A) -> B {
    return left(right)
}

/**
 *  A ──▶ [f] ──▶ B ──▶ [g] ──▶ C
 */
func >>> <A, B, C>(f: Future<A> -> Future<B>, g: Future<B> -> Future<C>) -> (Future<A> -> Future<C>) {
    return { g(f($0)) }
}

/**
 *  A ──▶ [f] ──▶ C
 *  B ──▶ [g] ──▶ D
 */
func *** <A, B, C, D>(f: Future<A> -> Future<C>, g: Future<B> -> Future<D>) -> ((Future<A>, Future<B>)) -> (Future<C>, Future<D>) {
    return { (f($0.0), g($0.1)) }
}

/**
 *      ┌──▶ [f] ──▶ B
 *  A ──┤
 *      └──▶ [g] ──▶ C
 */
func &&& <A, B, C>(f: Future<A> -> Future<B>, g: Future<A> -> Future<C>) -> (Future<A> -> (Future<B>, Future<C>)) {
    return { (f($0.0), g($0.0)) }
}

/**
 *  A ──▶ [f] ──▶ C
 *  B ──────────▶ B
 */
func first<A, B, C>(f: Future<A> -> Future<C>) -> ((Future<A>, Future<B>)) -> (Future<C>, Future<B>) {
    return { (f($0.0), $0.1) }
}

/**
 *  A ──────────▶ A
 *  B ──▶ [f] ──▶ C
 */
func second<A, B, C>(f: Future<B> -> Future<C>) -> ((Future<A>, Future<B>)) -> (Future<A>, Future<C>) {
    return { ($0.0, f($0.1)) }
}
