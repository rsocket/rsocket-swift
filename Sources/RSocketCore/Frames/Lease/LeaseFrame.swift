import Foundation

/**
 Lease frames MAY be sent by the client-side or server-side Responders and inform the Requester that it may
 send Requests for a period of time and how many it may send during that duration.
 See Lease Semantics for more information.

 The last received `LEASE` frame overrides all previous `LEASE` frame values.
 */
public struct LeaseFrame {
    /// The header of this frame
    public let header: FrameHeader

    /**
     Time (in milliseconds) for validity of `LEASE` from time of reception

     Value MUST be > `0`.
     */
    public let timeToLive: Int32

    /**
     Number of Requests that may be sent until next `LEASE`

     Value MUST be > `0`.
     */
    public let numberOfRequests: Int32

    /// Optional metadata of this frame
    public let metadata: Data?

    public init(
        header: FrameHeader,
        timeToLive: Int32,
        numberOfRequests: Int32,
        metadata: Data?
    ) {
        self.header = header
        self.timeToLive = timeToLive
        self.numberOfRequests = numberOfRequests
        self.metadata = metadata
    }
}
