//
//  FrameHeaderCodec.swift
//  RSocketSwift
//
//  Created by wsyed1  on 10/27/20.
//

import Foundation
import NIO

public class FrameHeaderCodec {
//    let headerSize = Integer.BYTES + Short.BYTES
    
    /** (I)gnore flag: a value of 0 indicates the protocol can't ignore this frame */
    public static  var FLAGS_I: Int = 0b10_0000_0000
    /** (M)etadata flag: a value of 1 indicates the frame contains metadata */
    public static  var FLAGS_M: Int = 0b01_0000_0000
    /**
     * (F)ollows: More fragments follow this fragment (in case of fragmented REQUEST_x or PAYLOAD
     * frames)
     */
    public static var FLAGS_F: Int = 0b00_1000_0000
    /** (C)omplete: bit to indicate stream completion ({@link Subscriber#onComplete()}) */
    public static var FLAGS_C: Int = 0b00_0100_0000
    /** (N)ext: bit to indicate payload or metadata present ({@link Subscriber#onNext(Object)}) */
    public static var FLAGS_N: Int = 0b00_0010_0000
    public static var DISABLE_FRAME_TYPE_CHECK = "io.rsocket.frames.disableFrameTypeCheck";
    private static var FRAME_FLAGS_MASK = 0b0000_0011_1111_1111
    private static var FRAME_TYPE_BITS = 6
    private static var FRAME_TYPE_SHIFT = 16 - FRAME_TYPE_BITS
    private static var disableFrameTypeCheck: Bool = false {
        didSet {
            if !DISABLE_FRAME_TYPE_CHECK.isEmpty {
                disableFrameTypeCheck = true
            }
        }
    }
    
    public static func hasMetaData(_ byteBuf: ByteBuffer) -> Bool {
        return true
    }
    
    public static func flags( byteBuf: inout ByteBuffer) -> Int {
        //TODO
        return 0
    }
    
    public static func size() -> Int {
        return 6
    }
    
    static func encodeStreamZero (_ allocator: ByteBufferAllocator,
                                  frameType: FrameTypeClass,
                              flags: Int) -> ByteBuffer {
        return encode(allocator, streamId: 0, frameType: frameType, flags: flags)
     }
     
    public static func encode(_ allocator: ByteBufferAllocator,
                              streamId: Int,
                              frameType: FrameTypeClass,
                              flags: Int) -> ByteBuffer {
        if !frameType.canHaveMetaData() && (flags & FLAGS_M) == FLAGS_M {
            fatalError("bad value for metadata flag")
        }
        
        let typeAndFlagsShort: Int16 = Int16(frameType.getEncodedType() << FRAME_TYPE_SHIFT) | Int16(flags)
        let typeAndFlagsInt: Int = Int(typeAndFlagsShort)
        
        let fullCapacity = streamId + typeAndFlagsInt
        var buffer = allocator.buffer(capacity: fullCapacity)
        buffer.writeInteger(streamId)
        buffer.moveWriterIndex(to: streamId)
        buffer.writeInteger(typeAndFlagsInt)
        buffer.moveWriterIndex(to: typeAndFlagsInt)
        
        return buffer
    }
    
    public static func frameType(_ byteBuf: inout ByteBuffer) throws -> FrameType {
        byteBuf.moveReaderIndex(to: 0)
        byteBuf.moveReaderIndex(forwardBy: 4)
        let typeAndFlags = byteBuf.readerIndex & 0xFFFF
        var result = try? FrameTypeClass.fromEncodedType(encodedType: typeAndFlags
            >> FrameHeaderCodec.FRAME_TYPE_SHIFT)
        
        if FrameType.Payload == result {
            let flags = typeAndFlags & FrameHeaderCodec.FRAME_FLAGS_MASK
            
            let complete = FrameHeaderCodec.FLAGS_C == (flags & FrameHeaderCodec.FLAGS_C)
            let next = FrameHeaderCodec.FLAGS_N == (flags & FrameHeaderCodec.FLAGS_N)
            if next && complete {
                result = FrameType.NextComplete
            } else if complete {
                result = FrameType.Complete
            } else if next {
                result = FrameType.Next
            } else {
                 throw NSException(name: NSExceptionName(rawValue: "IllegalArgumentException"), reason: "Payload must set either or both of NEXT and COMPLETE.", userInfo:nil) as! Error
            }
        }
        
        byteBuf.moveReaderIndex(to: 0)
        
        return result!
    }
        
   public static func ensureFrameType (frametype: FrameType, byteBuf: inout ByteBuffer) {
        if !FrameHeaderCodec.disableFrameTypeCheck {
            let typeInFrame = try? frameType(&byteBuf)
            
            if typeInFrame != frametype {
                assertionFailure("expected " + "\(frametype)" + ", but saw " + "\(String(describing: typeInFrame))")
            }
        }
    }
    
}
