//
//  DefaultPayloadDecoder.swift
//  CNIOAtomics
//
//  Created by wsyed1  on 10/27/20.
//

import Foundation
import NIO

public class DefaultPayloadDecoder: PayloadDecoder {
    public func apply(byteBuf: ByteBuffer) -> Payload {
        var metadataByteBuffer: ByteBuffer?
        var dataByteBuffer: ByteBuffer?
        
        // TODO:- Hardcoded the frametype. Need to read it from `FrameCodeSpec`
        let type: FrameType = FrameType.RequestResponse
        
        switch type {
        case .RequestResponse:
            dataByteBuffer = RequestResponseFrameCodec.data(byteBuf: &dataByteBuffer!)
            metadataByteBuffer = RequestResponseFrameCodec.metadata(byteBuf: &metadataByteBuffer!)
        default: break
        }
        
        var data = ByteBufferAllocator().buffer(capacity: dataByteBuffer!.capacity)
        data.writeInteger(dataByteBuffer!.readableBytes)
//      data.flip(); equivalent on Swift not found
        
        if metadataByteBuffer != nil {
            var metadata = ByteBufferAllocator().buffer(capacity: metadataByteBuffer!.capacity)
            metadata.writeInteger(metadataByteBuffer!.readableBytes)
//          metadata.flip(); equivalent on Swift not found
            return DefaultPayload.create(data: data, metadata: metadata)
            
        }

        return DefaultPayload.create(data: data)
    }
}
