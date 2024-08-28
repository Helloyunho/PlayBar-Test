//
//  Converters.swift
//  PlayBar-Test
//
//  Created by Helloyunho on 2024/8/28.
//
import Foundation

func timeToOffset(_ time: Double, speed: Double) -> CGFloat {
    CGFloat(time) / 10.0 * speed
}

func offsetToTime(_ offset: CGFloat, speed: Double) -> Double {
    return Double(offset * 10.0 / speed)
}
