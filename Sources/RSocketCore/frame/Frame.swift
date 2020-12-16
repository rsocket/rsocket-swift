//
//  Frame.swift
//  RSocketSwift
//
//  Created by Nathany, Sumit on 21/10/20.
//  Copyright © 2020 Mint.com. All rights reserved.
//

import Foundation

private let FlagsMask: Int = 1023
private let FrameTypeShift: Int = 10

protocol Frame {
	var streamId: Int { get }
}

