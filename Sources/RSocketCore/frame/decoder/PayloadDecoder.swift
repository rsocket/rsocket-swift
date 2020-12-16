//
//  PayloadDecoder.swift
//  CNIOAtomics
//
//  Created by wsyed1  on 10/27/20.
//

import Foundation
import NIO

public protocol PayloadDecoderProtocol {
    var defaultPayloadDecoder: PayloadDecoder { get set }
    var zeroCopyPayloadDecoder: PayloadDecoder { get set }
}

public class PayloadDecoder: PayloadDecoderProtocol {
    public var defaultPayloadDecoder: PayloadDecoder = DefaultPayloadDecoder()
    public var zeroCopyPayloadDecoder: PayloadDecoder = ZeroCopyPayloadDecoder()
}
