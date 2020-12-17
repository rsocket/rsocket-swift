//
//  KeepAliveFrameCodec.swift
//  RSocketSwift
//
//  Created by npatil5  on 11/9/20.
//

import Foundation
import NIO

public class KeepAliveFrameCodec {
    
    /**
      * (R)espond: Set by the sender of the KEEPALIVE, to which the responder MUST reply with a
      * KEEPALIVE without the R flag set
      */
    public static let FLAGS_KEEPALIVE_R = 0b00_1000_0000;

    public static let LAST_POSITION_MASK: UInt64 = 0x8000000000000000
    
    public static func encode(_ allocator: ByteBufferAllocator,
                              respond: Bool,
                              lastPosition: Int,
                              data: ByteBuffer) -> ByteBuffer {
        let flags = respond ? KeepAliveFrameCodec.FLAGS_KEEPALIVE_R : 0
        var header = FrameHeaderCodec.encodeStreamZero(allocator, frameType: FrameType.KeepAlive.frameTypeValue, flags: flags)
        var lp = 0
        if lastPosition > 0 {
            lp |= lastPosition
        }
        
        header.writeInteger(lp)
        
        return FrameBodyCodec.encode(allocator, header: header, metadata: nil, hasMetadata: false, data: data)
    }
    
    public static func respondFlag(byteBuf: inout ByteBuffer) -> Bool {
        FrameHeaderCodec.ensureFrameType(frametype: FrameType.KeepAlive, byteBuf: &byteBuf)
        let flags = FrameHeaderCodec.flags(byteBuf: &byteBuf)
        return (flags & FLAGS_KEEPALIVE_R) == FLAGS_KEEPALIVE_R
    }
    
    public static func lastPosition(byteBuf: inout ByteBuffer) -> UInt64 {
        FrameHeaderCodec.ensureFrameType(frametype: FrameType.KeepAlive, byteBuf: &byteBuf)
        byteBuf.moveReaderIndex(to: 0)
        byteBuf.moveReaderIndex(forwardBy: FrameHeaderCodec.size())
        let l: UInt64 = UInt64(byteBuf.readerIndex)
        byteBuf.moveReaderIndex(to: 0)
        return l
    }

    public static func data(byteBuf: inout ByteBuffer) -> ByteBuffer {
        FrameHeaderCodec.ensureFrameType(frametype: FrameType.KeepAlive, byteBuf: &byteBuf)
        byteBuf.moveReaderIndex(to: 0)
        byteBuf.moveReaderIndex(forwardBy: FrameHeaderCodec.size() + 8) //Long.BYTES
        let slice = byteBuf.slice()
        byteBuf.moveReaderIndex(to: 0)
        return slice
    }
}
