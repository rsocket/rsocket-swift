//
//  FrameLengthCodec.swift
//  RSocketSwift
//
//  Created by npatil5  on 11/9/20.
//

import Foundation
import NIO

public class FrameLengthCodec {

    public static var FRAME_LENGTH_MASK = 0xFFFFFF
    public static var FRAME_LENGTH_SIZE = 3

    private static func encodeLength(byteBuf: inout ByteBuffer, length: Int) throws {
        if (length & ~FRAME_LENGTH_MASK) != 0 {
            throw NSException(name: NSExceptionName(rawValue: "IllegalArgumentException"), reason: "Length is larger than 24 bits", userInfo:nil) as! Error
        }
        // Write each byte separately in reverse order, this mean we can write 1 << 23 without
        // overflowing.
        byteBuf.writeInteger(length >> 16)
        byteBuf.writeInteger(length >> 8)
        byteBuf.writeInteger(length)
    }
    
    private static func decodeLength(byteBuf: inout ByteBuffer) -> Int {
        var length = (byteBuf.readInteger()! & 0xFF) << 16
        length |= (byteBuf.readInteger()! & 0xFF) << 8
        length |= byteBuf.readInteger()! & 0xFF
        return length
    }
  
    public static func encode(_ allocator: ByteBufferAllocator,
                             length: Int,
                             frame: inout ByteBuffer) -> ByteBuffer {
        var buffer = allocator.buffer(capacity: 1)
        try? encodeLength(byteBuf: &buffer, length: length)
        var compositeByteBuffer = allocator.buffer(capacity: 2)
        
        compositeByteBuffer.writeBuffer(&buffer)
        compositeByteBuffer.moveWriterIndex(to: buffer.capacity)
        compositeByteBuffer.writeBuffer(&frame)
        compositeByteBuffer.moveWriterIndex(to: frame.capacity)
        
        return compositeByteBuffer
        
    }
    
    public static func length(byteBuf: inout ByteBuffer) -> Int {
        byteBuf.moveReaderIndex(to: 0)
        let length = decodeLength(byteBuf: &byteBuf)
        byteBuf.moveReaderIndex(to: 0)
        return length
    }
    
    public static func frame(byteBuf: inout ByteBuffer) -> ByteBuffer {
        byteBuf.moveReaderIndex(to: 0)
        byteBuf.moveReaderIndex(forwardBy: 3)
        let slice = byteBuf.slice()
        byteBuf.moveReaderIndex(to: 0)
        return slice
    }
}
 
