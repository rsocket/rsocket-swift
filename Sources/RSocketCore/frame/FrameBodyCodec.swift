//
//  FrameBodyCodec.swift
//  RSocketSwift
//
//  Created by wsyed1  on 10/27/20.
//

import Foundation
import NIO

public class FrameBodyCodec {
    private static let frameLengthMask =  0xFFFFFF
    
    public static func dataWithoutMarking(byteBuf: ByteBuffer, hasMetadata: Bool) -> ByteBuffer {
        return ByteBuffer(string: "")
    }
  
    public static func metadataWithoutMarking(byteBuf: ByteBuffer) -> ByteBuffer {
        return ByteBuffer(string: "")
    }
    
    public static func encode(_ allocator: ByteBufferAllocator,
                         header: ByteBuffer,
                         metadata: ByteBuffer?,
                         hasMetadata: Bool,
                         data: ByteBuffer?) -> ByteBuffer {
        var header = header
        let addData: Bool
        if let data = data {
            if (data.writerIndex - data.readerIndex) > 0 {
                addData = true
            } else {
               //data.release() // No equivalent function in Swift
                addData = false
            }
        } else {
            addData = false
        }
        
        let addMetadata: Bool
        
        if hasMetadata, let metadata = metadata {
            if (metadata.writerIndex - metadata.readerIndex) > 0 {
                addMetadata = true
            } else {
                //metadata.release() // No equivalent function in Swift
                addMetadata = false
            }
        } else {
            addMetadata = false
        }
        
        if hasMetadata {
            let length = metadata!.readableBytes
            encodeLength(&header, length: length)
        }
        
        var data = data!
        var metadata = metadata!
        var compositeByteBuffer: ByteBuffer
        
        if addMetadata && addData {
            
           compositeByteBuffer = ByteBufferAllocator().buffer(capacity: 3)
            
            compositeByteBuffer.writeBuffer(&header)
            compositeByteBuffer.moveWriterIndex(to: header.capacity)
            compositeByteBuffer.writeBuffer(&data)
            compositeByteBuffer.moveWriterIndex(to: data.capacity)
            compositeByteBuffer.writeBuffer(&metadata)
            compositeByteBuffer.moveWriterIndex(to: metadata.capacity)
            
            return compositeByteBuffer
        } else if addMetadata {
        
            compositeByteBuffer = ByteBufferAllocator().buffer(capacity: 2)
            
            compositeByteBuffer.writeBuffer(&header)
            compositeByteBuffer.moveWriterIndex(to: header.capacity)
            compositeByteBuffer.writeBuffer(&metadata)
            compositeByteBuffer.moveWriterIndex(to: metadata.capacity)
            
            return compositeByteBuffer
        } else if addData {
            
            compositeByteBuffer = ByteBufferAllocator().buffer(capacity: 2)
            
            compositeByteBuffer.writeBuffer(&header)
            compositeByteBuffer.moveWriterIndex(to: header.capacity)
            compositeByteBuffer.writeBuffer(&data)
            compositeByteBuffer.moveWriterIndex(to: data.capacity)
            
            return compositeByteBuffer
        } else {
            return header
        }
    }
}

private extension FrameBodyCodec {
    static func encodeLength(_ byteBuf: inout ByteBuffer, length: Int) {
        if (length & frameLengthMask) != 0 {
            assertionFailure("Length is larger than 24 bits")
        } else {
            byteBuf.writeInteger(length >> 16)
            byteBuf.writeInteger(length >> 8)
            byteBuf.writeInteger(length)
        }
    }
}

