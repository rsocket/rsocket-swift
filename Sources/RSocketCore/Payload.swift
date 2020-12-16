//
//  Payload.swift
//  CNIOAtomics
//
//  Created by wsyed1  on 10/27/20.
//

import Foundation
import NIO

typealias SwiftNIOByteBuff = Int

public protocol Payload {
    /**
    * Returns whether the payload has metadata, useful for tell if metadata is empty or not present.
    - Returns: whether payload has non-null (possibly empty) metadata
    */
    func hasMetaData() -> Bool
    
    /**
    * Returns a slice Payload metadata. Always non-null, check {@link #hasMetadata()} to differentiate null from "".
    - Returns: payload metadata.
    */
    func sliceMetaData() -> ByteBuffer
    
    /**
    * Returns the Payload data. Always non-null.
    - Returns: payload data.
    */
    func sliceData() -> ByteBuffer
    
    /**
    * Returns the Payloads' data without slicing if possible. This is not safe and editing this could effect the payload. It is recommended to call sliceData().
     - Returns: data as a bytebuf or slice of the data
    */
    func data() -> ByteBuffer
    
    /**
    * Returns the Payloads' metadata without slicing if possible. This is not safe and editing this could effect the payload. It is recommended to call sliceMetadata().
    - Returns: metadata as a bytebuf or slice of the metadata
    */
    func metaData() -> ByteBuffer
    
    // NOTE:- functions like retain, touch, release might not be neeeded in Swift as the ARC automatically manages the reference count in Swift. Adding a TODO to double check if this is needed
}

extension Payload {
    func getMetadata() -> SwiftNIOByteBuff {
        return sliceMetaData().readableBytes
    }
    
    func getData() -> SwiftNIOByteBuff {
        return sliceData().readableBytes
    }
    
    func getMetadataUtf8() -> String.UTF8View {
        return "\(sliceMetaData().readableBytes)".utf8
    }
    
    func getDataUtf8() -> String.UTF8View {
        return "\(sliceData().readableBytes)".utf8
    }
}
