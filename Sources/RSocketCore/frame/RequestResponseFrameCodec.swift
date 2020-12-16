//
//  RequestResponseFrameCodec.swift
//  CNIOAtomics
//
//  Created by wsyed1  on 10/27/20.
//

import Foundation
import NIO


public class RequestResponseFrameCodec {
    init() {}

    public static func data(byteBuf: inout ByteBuffer) -> ByteBuffer {
        return GenericFrameCodec.data(byteBuf: &byteBuf)
    }
    
    public static func metadata(byteBuf: inout ByteBuffer) -> ByteBuffer {
        return GenericFrameCodec.metadata(byteBuf: &byteBuf)!
    }
    
    public static func encode(_ allocator: ByteBufferAllocator,
                              streamId: Int,
                              fragmentFollows: Bool,
                              metadata: ByteBuffer?,
                              data: ByteBuffer) -> ByteBuffer {
        return GenericFrameCodec.encode(allocator: allocator, frameType: FrameType.RequestResponse.frameTypeValue, streamId: streamId, fragmentFollows: fragmentFollows, metadata: metadata, data: data)
    }
}
