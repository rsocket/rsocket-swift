//
//  ZeroCopyPayloadDecoder.swift
//  RSocketSwift
//
//  Created by wsyed1  on 10/27/20.
//

import Foundation
import NIO


public class ZeroCopyPayloadDecoder: PayloadDecoder {
    public func apply(byteBuf: ByteBuffer) -> Payload {
        var m: ByteBuffer?
        var d: ByteBuffer?
        
        let type: FrameType = FrameType.RequestResponse
        
        switch type {
        case .RequestResponse:
            d = RequestResponseFrameCodec.data(byteBuf: &d!)
            m = RequestResponseFrameCodec.metadata(byteBuf: &m!)
        default: break
        }
        
        // In Swift the Automatic Reference Count takes care of retain and release the objects. We do not have to manually keep track of the reference count and hence this ZeroCopyPayloadDecoder might not be applicable.
        return DefaultPayload.create(data: d!) // This is just defaulted to some value to satisfy the return
    }
    
    
}
