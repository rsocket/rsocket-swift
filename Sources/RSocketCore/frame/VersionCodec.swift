//
//  VersionCodec.swift
//  RSocketSwift
//
//  Created by npatil5  on 11/4/20.
//

import Foundation

public class VersionCodec {
    public static func encode(major: Int, minor: Int) -> Int {
        return (major << 16) | (minor & 0xFFFF)
    }
    public static func major(version: Int) -> Int {
        return version >> 16 & 0xFFFF
    }
    public static func minor(version: Int) -> Int {
        return version  & 0xFFFF
    }
    public static func toString(version: Int) -> String {
        return "\(major(version: version))" + "." + "\(minor(version: version))"
     }
}
