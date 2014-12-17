//
//  EnumHackExtensions.swift
//  OneSound
//
//  Created by adam on 7/21/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import Foundation
/*
extension FBSessionState : Equatable {
}
public func ==(lhs: FBSessionState, rhs: FBSessionState) -> Bool {
    let intVal1 = reflect(lhs)[0].1.value as UInt32
    let intVal2 = reflect(rhs)[0].1.value as UInt32
    return intVal1 == intVal2
}*/

/*
extension FrontViewPosition : Equatable {
}
public func ==(lhs: FrontViewPosition, rhs: FrontViewPosition) -> Bool {
    let intVal1 = reflect(lhs)[0].1.value as UInt32
    let intVal2 = reflect(rhs)[0].1.value as UInt32
    return intVal1 == intVal2
}
*/

extension STKAudioPlayerState : Equatable {
}
public func ==(lhs: STKAudioPlayerState, rhs: STKAudioPlayerState) -> Bool {
    let intVal1 = reflect(lhs)[0].1.value as UInt32
    let intVal2 = reflect(rhs)[0].1.value as UInt32
    return intVal1 == intVal2
}