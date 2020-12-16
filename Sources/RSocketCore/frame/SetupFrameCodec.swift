//
//  SetupFrameCodec.swift
//  RSocketSwift
//
//  Created by npatil5  on 11/4/20.
//

import Foundation
import NIO


public class SetupFrameCodec {
    
    /**
     * A flag used to indicate that the client requires connection resumption, if possible (the frame
     * contains a Resume Identification Token)
     */
    public static var FLAGS_RESUME_ENABLE = 0b00_1000_0000
    /** A flag used to indicate that the client will honor LEASE sent by the server */
    public static var FLAGS_WILL_HONOR_LEASE = 0b00_0100_0000
    public static var CURRENT_VERSION = VersionCodec.encode(major: 1, minor: 0)
    private static var VERSION_FIELD_OFFSET = FrameHeaderCodec.size()
    private static var KEEPALIVE_INTERVAL_FIELD_OFFSET = VERSION_FIELD_OFFSET + 4
    private static var KEEPALIVE_MAX_LIFETIME_FIELD_OFFSET = KEEPALIVE_INTERVAL_FIELD_OFFSET + 4
    private static var VARIABLE_DATA_OFFSET = KEEPALIVE_MAX_LIFETIME_FIELD_OFFSET + 4
    
    
    public static func encode(_ allocator: ByteBufferAllocator,
                              lease: Bool,
                              keepaliveInterval: Int,
                              maxLifetime: Int,
                              metadataMimeType: String,
                              dataMimeType: String,
                              setupPayload: Payload) -> ByteBuffer {
      
        //TODO: resumeToken: Unpooled.EMPTY_BUFFER :- have to fine equivalent in swiftNIO
        var resumeToken = ByteBuffer.init()
        
        return encode(allocator, lease: lease, keepaliveInterval: keepaliveInterval, maxLifetime: maxLifetime, resumeToken: &resumeToken, metadataMimeType: metadataMimeType, dataMimeType: dataMimeType, setupPayload: setupPayload)
        
    }
    
    public static func encode(_ allocator: ByteBufferAllocator,
                              lease: Bool,
                              keepaliveInterval: Int,
                              maxLifetime: Int,
                              resumeToken: inout ByteBuffer,
                              metadataMimeType: String,
                              dataMimeType: String,
                              setupPayload: Payload) -> ByteBuffer {
        
        let data: ByteBuffer = setupPayload.sliceData()
        let hasMetadata: Bool = setupPayload.hasMetaData()
        let metaData: ByteBuffer? = hasMetadata ? setupPayload.sliceMetaData() : nil
        
        var flags = 0
        
        if resumeToken.readableBytes > 0 {
            flags |= FLAGS_RESUME_ENABLE
        }
        
        if lease {
            flags |= FLAGS_WILL_HONOR_LEASE
        }
        
        if hasMetadata {
            flags |= FrameHeaderCodec.FLAGS_M
        }
        
        var header = FrameHeaderCodec.encodeStreamZero(allocator, frameType: FrameType.Setup.frameTypeValue, flags: flags)
        header.writeInteger(CURRENT_VERSION)
        header.writeInteger(keepaliveInterval)
        header.writeInteger(maxLifetime)

        if (flags & FLAGS_RESUME_ENABLE) != 0 {
            resumeToken.moveReaderIndex(to: 0)
            header.writeInteger(resumeToken.readableBytes)
            header.writeBuffer(&resumeToken)
            resumeToken.moveReaderIndex(to: 0)
        }
        
       //TODO find the equivalent of ByteBufUtil.utf8Bytes in Swift NIO
       /* // Write metadata mime-type
        int length = ByteBufUtil.utf8Bytes(metadataMimeType);
        header.writeByte(length);
        ByteBufUtil.writeUtf8(header, metadataMimeType);

        // Write data mime-type
        length = ByteBufUtil.utf8Bytes(dataMimeType);
        header.writeByte(length);
        ByteBufUtil.writeUtf8(header, dataMimeType);*/

    
        return FrameBodyCodec.encode(allocator, header: header, metadata: metaData, hasMetadata: hasMetadata, data: data)
    }
    
    public static func version(byteBuf: inout ByteBuffer) -> Int {
        FrameHeaderCodec.ensureFrameType(frametype: FrameType.Setup, byteBuf: &byteBuf)
        byteBuf.moveReaderIndex(to: 0)
        byteBuf.moveReaderIndex(forwardBy: SetupFrameCodec.VERSION_FIELD_OFFSET)
        let version = byteBuf.readerIndex
        return version
    }
 
    public static func humanReadableVersion(byteBuf: inout ByteBuffer) -> String {
        let encodedVersion = version(byteBuf: &byteBuf)
        return "\(VersionCodec.major(version: encodedVersion))" + "." + "\(VersionCodec.minor(version: encodedVersion))"
    }
    
    public static func isSupportedVersion(byteBuf: inout ByteBuffer) -> Bool {
        return CURRENT_VERSION == version(byteBuf: &byteBuf)
    }
    
    public static func resumeTokenLength(byteBuf: inout ByteBuffer) -> Int {
        //TODO Cross check the functionality
        byteBuf.moveReaderIndex(to: 0)
        byteBuf.moveReaderIndex(forwardBy: VARIABLE_DATA_OFFSET)
        let tokenLength = byteBuf.readerIndex & 0xFFFF
        byteBuf.moveReaderIndex(to: 0)
        return tokenLength
    }

    public static func keepAliveInterval(byteBuf: inout ByteBuffer) -> Int {
        byteBuf.moveReaderIndex(to: 0)
        byteBuf.moveReaderIndex(forwardBy: KEEPALIVE_INTERVAL_FIELD_OFFSET)
        let keepAliveInterval = byteBuf.readInteger(as: Int.self)!
        byteBuf.moveReaderIndex(to: 0)
        return keepAliveInterval
    }
  
    public static func keepAliveMaxLifetime(byteBuf: inout ByteBuffer) -> Int {
        byteBuf.moveReaderIndex(to: 0)
        byteBuf.moveReaderIndex(forwardBy: KEEPALIVE_MAX_LIFETIME_FIELD_OFFSET)
        let keepAliveMaxLifetime = byteBuf.readInteger(as: Int.self)!
        byteBuf.moveReaderIndex(to: 0)
        return keepAliveMaxLifetime
    }

    public static func honorLease(byteBuf: inout ByteBuffer) -> Bool {
        return FLAGS_WILL_HONOR_LEASE & FrameHeaderCodec.flags(byteBuf: &byteBuf) == FLAGS_WILL_HONOR_LEASE
    }
    
    public static func resumeEnabled(byteBuf: inout ByteBuffer) -> Bool {
        return FLAGS_RESUME_ENABLE & FrameHeaderCodec.flags(byteBuf: &byteBuf) == FLAGS_RESUME_ENABLE
    }
    
    public static func metadata(byteBuf: inout ByteBuffer) -> ByteBuffer? {
        let hasMetadata = FrameHeaderCodec.hasMetaData(byteBuf)
        if !hasMetadata {
            return nil
        }
        byteBuf.moveReaderIndex(to: 0)
        skipToPayload(byteBuf: &byteBuf)
        let metadata = FrameBodyCodec.metadataWithoutMarking(byteBuf: byteBuf)
        byteBuf.moveReaderIndex(to: 0)
        return metadata
    }
    
    public static func data(byteBuf: inout ByteBuffer) -> ByteBuffer {
        let hasMetadata = FrameHeaderCodec.hasMetaData(byteBuf)
        byteBuf.moveReaderIndex(to: 0)
        skipToPayload(byteBuf: &byteBuf)
        let data = FrameBodyCodec.dataWithoutMarking(byteBuf: byteBuf, hasMetadata: hasMetadata)
        byteBuf.moveReaderIndex(to: 0)
        return data
    }
    
    public static func bytesToSkipToMimeType(byteBuf: inout ByteBuffer) -> Int {
        var bytesToSkip = VARIABLE_DATA_OFFSET
        if (FLAGS_RESUME_ENABLE & FrameHeaderCodec.flags(byteBuf: &byteBuf)) == FLAGS_RESUME_ENABLE {
            bytesToSkip += resumeTokenLength(byteBuf: &byteBuf) + 2 //Short.BYTES = 2
            
        }
        return bytesToSkip
    }
    
    public static func skipToPayload(byteBuf: inout ByteBuffer) {
        
        //TODO Cross check the functionality
        let skip = bytesToSkipToMimeType(byteBuf: &byteBuf)
        byteBuf.moveReaderIndex(forwardBy: skip)
        var length = byteBuf.readerIndex
        byteBuf.moveReaderIndex(to: skip + 1)
        byteBuf.moveReaderIndex(forwardBy: length)
        length = byteBuf.readerIndex
        byteBuf.moveReaderIndex(to: length + 1)
        
    }
}

