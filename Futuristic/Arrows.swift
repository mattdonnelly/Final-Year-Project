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
infix operator ~   { associativity right precedence 120 }
infix operator >>> { associativity left  precedence 150 }
infix operator *** { associativity left  precedence 200 }
infix operator &&& { associativity left  precedence 200 }

/** 
 *  A ──▶ [f] ──▶ B
 */
func |> <A, B>(value: A, transform: A -> B) -> B {
    return transform(value)
}

/**
 *  B ◀── [f] ◀── A
 */
func <| <A, B>(transform: A -> B, value: A) -> B {
    return transform(value)
}

/**
 *  A ──▶ [f] ──▶ B ──▶ [g] ──▶ C
 */
func >>> <A, B, C>(f: A -> B, g: B -> C) -> (A -> C) {
    return { g(f($0)) }
}

/**
 *  A ──▶ lift(f) ──▶ B ──▶ [g] ──▶ C
 */
func ~ <A, B, C>(f: A -> B, g: Future<B> -> Future<C>) -> Future<A> -> Future<C> {
    return liftF(f) >>> g
}

/**
 *  A ──▶ [f] ──▶ C
 *  B ──▶ [g] ──▶ D
 */
func *** <A, B, C, D>(f: A -> C, g: B -> D) -> ((A, B)) -> (C, D) {
    return first(f) >>> second(g)
}

/**
 *      ┌──▶ [f] ──▶ B
 *  A ──┤
 *      └──▶ [g] ──▶ C
 */
func &&& <A, B, C>(f: A -> B, g: A -> C) -> (A -> (B, C)) {
    func duplicate(value: A) -> (A, A) {
        return (value, value)
    }
    
    return duplicate >>> (f *** g)
}

/**
 *  A ──▶ [f] ──▶ C
 *  B ──────────▶ B
 */
func first<A, B, C>(f: A -> C) -> ((A, B)) -> (C, B) {
    return { (f($0.0), $0.1) }
}

func swap<A, B>(pair: (A, B)) -> (B, A) {
    return (pair.1, pair.0)
}

/**
 *  A ──────────▶ A
 *  B ──▶ [f] ──▶ C
 */
func second<A, B, C>(f: B -> C) -> ((A, B)) -> (A, C) {
    return swap >>> first(f) >>> swap
}
