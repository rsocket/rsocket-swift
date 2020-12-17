//
//  ErrorFrameCodec.swift
//  RSocketSwift
//
//  Created by npatil5  on 10/29/20.
//

import Foundation
import NIO

public class ErrorFrameCodec {
    
    // defined zero stream id error codes
    public static let INVALID_SETUP = 0x00000001
    public static let UNSUPPORTED_SETUP = 0x00000002
    public static let REJECTED_SETUP = 0x00000003
    public static let REJECTED_RESUME = 0x00000004
    public static let CONNECTION_ERROR = 0x00000101
    public static let CONNECTION_CLOSE = 0x00000102
    // defined non-zero stream id error codes
    public static let APPLICATION_ERROR = 0x00000201
    public static let REJECTED = 0x00000202
    public static let CANCELED = 0x00000203
    public static let INVALID = 0x00000204
    // defined user-allowed error codes range
    public static let MIN_USER_ALLOWED_ERROR_CODE = 0x00000301
    public static let MAX_USER_ALLOWED_ERROR_CODE = 0xFFFFFFFE
    
    public static func encode(_ allocator: ByteBufferAllocator,streamId: Int, data: ByteBuffer, rSocketException: RSocketErrorException? = nil) throws -> ByteBuffer {
        var data = data
        var header = FrameHeaderCodec.encode(allocator, streamId: streamId, frameType: FrameType.Error.frameTypeValue, flags: 0)
        
        let errorCode = rSocketException?.getErrorCode() ?? APPLICATION_ERROR
            
        header.writeInteger(errorCode)
        
        var compositeByteBuffer = ByteBufferAllocator().buffer(capacity: header.capacity + data.capacity)
        compositeByteBuffer.writeBuffer(&header)
        compositeByteBuffer.moveWriterIndex(to: header.capacity)
        compositeByteBuffer.writeBuffer(&data)
        compositeByteBuffer.moveWriterIndex(to: data.capacity)
        
        return compositeByteBuffer
        
    }
    
    public static func encode(_ allocator: ByteBufferAllocator, streamId: Int, rSocketException: RSocketErrorException? = nil) throws -> ByteBuffer {
        
        let message = rSocketException?.getMessage()
        var byteBuffer = ByteBufferAllocator().buffer(capacity: message?.count ?? 0)
        byteBuffer.writeString(message ?? "")
       
        return try encode(allocator, streamId: streamId, data: byteBuffer, rSocketException: rSocketException)
    }

    public static func errorCode( byteBuf: inout ByteBuffer) -> Int {
        
        byteBuf.moveReaderIndex(to: 0)
        byteBuf.moveReaderIndex(to: FrameHeaderCodec.size())
        let i = byteBuf.readInteger(as: Int.self)
        byteBuf.moveReaderIndex(to: 0)
        return i!
    }
    
    public static func data( byteBuf: inout ByteBuffer) -> ByteBuffer {
        
        byteBuf.moveReaderIndex(to: 0)
        byteBuf.moveReaderIndex(to: FrameHeaderCodec.size() + 4)
        let slice = byteBuf.slice()
        byteBuf.moveReaderIndex(to: 0)
        return slice
    }
    
    public static func dataUtf8(byteBuf: inout ByteBuffer) -> String {
        return "\(data(byteBuf: &byteBuf))"
    }
    
}

