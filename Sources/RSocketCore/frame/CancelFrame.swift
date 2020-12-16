//
//  CancelFrame.swift
//  RSocketSwift
//
//  Created by Nathany, Sumit on 21/10/20.
//

import Foundation
import NIO

public class CancelFrame: Frame {
    let frame: FrameType
	var streamId: Int

    init(frame: FrameType, streamId: Int) {
		self.frame = frame
		self.streamId = streamId

	}
    
    public func encode( allocator: ByteBufferAllocator, streamId: Int) -> ByteBuffer {
        return FrameHeaderCodec.encode(allocator, streamId: streamId, frameType: FrameType.Cancel.frameTypeValue, flags: 0)
    }
}
