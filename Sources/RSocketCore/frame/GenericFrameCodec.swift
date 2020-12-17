//
//  GenericFrameCodec.swift
//  RSocketSwift
//
//  Created by wsyed1  on 10/27/20.
//

import Foundation
import NIO


public class GenericFrameCodec {
    init() {}

    public static func data(byteBuf: inout ByteBuffer) -> ByteBuffer {
        let hasMetaData = FrameHeaderCodec.hasMetaData(byteBuf)
        let idx = byteBuf.readerIndex
        byteBuf.moveReaderIndex(to: 0)
        byteBuf.moveReaderIndex(forwardBy: FrameHeaderCodec.size())
        let data = FrameBodyCodec.dataWithoutMarking(byteBuf: byteBuf, hasMetadata: hasMetaData)
        byteBuf.moveReaderIndex(forwardBy: idx)
        
        return data
    }
    
    public static func metadata(byteBuf: inout ByteBuffer) -> ByteBuffer? {
        let hasMetaData = FrameHeaderCodec.hasMetaData(byteBuf)
        
        guard hasMetaData else { return nil }
        
        byteBuf.moveReaderIndex(to: 0)
        byteBuf.moveReaderIndex(forwardBy: FrameHeaderCodec.size())
        let metaData = FrameBodyCodec.metadataWithoutMarking(byteBuf: byteBuf)
        byteBuf.moveReaderIndex(to: 0)
        
        return metaData
    }
    
    public static func encode(allocator: ByteBufferAllocator,
                              frameType: FrameTypeClass,
                         streamId: Int,
                         fragmentFollows: Bool,
                         metadata: ByteBuffer?,
                         data: ByteBuffer) -> ByteBuffer {
        return encode(allocator,
                      frameType: frameType,
                      streamId: streamId,
                      fragmentFollows: fragmentFollows,
                      complete: false,
                      next: false,
                      requestN: 0,
                      metadata: metadata,
                      data: data)
        
    }
    
    public static func encode(_ allocator: ByteBufferAllocator,
                              frameType: FrameTypeClass,
                              streamId: Int,
                              fragmentFollows: Bool,
                              complete: Bool,
                              next: Bool,
                              requestN: Int,
                              metadata: ByteBuffer?,
                              data: ByteBuffer?) -> ByteBuffer {
        let hasMetadata = metadata != nil
        var flags = 0
        
        if hasMetadata {
            flags = flags | FrameHeaderCodec.FLAGS_M
        }
        
        if fragmentFollows {
            flags = flags | FrameHeaderCodec.FLAGS_F
        }
        
        if complete {
            flags = flags | FrameHeaderCodec.FLAGS_C
        }
        if next {
            flags = flags | FrameHeaderCodec.FLAGS_N
        }
        
        var header = FrameHeaderCodec.encode(allocator,
                                             streamId: streamId,
                                             frameType: frameType,
                                             flags: flags)
        if requestN > 0 {
            header.writeInteger(requestN)
        }
        
        return FrameBodyCodec.encode(allocator,
                                     header: header,
                                     metadata: metadata,
                                     hasMetadata: hasMetadata,
                                     data: data)
    }
}
