//
//  FrameType.swift
//  RSocketSwift
//
//  Created by Nathany, Sumit on 21/10/20.
//

import Foundation
import NIO

public enum FrameType {

     public static var allCases: [FrameType] {
        return [.Reserved, .Setup, .Lease, .KeepAlive, .RequestResponse, .RequestFnF, .RequestStream, .RequestChannel, .RequestN, .Cancel, .Payload, .Error, .MetadataPush, .Resume, .ResumeOk, .Next, .Complete, .NextComplete, .Extension]
        }
     // Reserved.
     case Reserved
     
     //CONNECTION
     case Setup
     case Lease
     case KeepAlive
     
     //REQUEST
     case RequestResponse
     case RequestFnF
     case RequestStream
     case RequestChannel
     
     // DURING REQUEST
     case RequestN
     case Cancel
     
     // RESPONSE
     case Payload
     case Error

     // METADATA
     case MetadataPush
     
     // RESUMPTION
     case Resume
     case ResumeOk

     case Next
     case Complete
     case NextComplete
     case Extension
    var frameTypeValue: FrameTypeClass {
        switch self {
            case .Reserved:
                return FrameTypeClass(encodedType: 0x00)
            case .Setup:
                return FrameTypeClass(encodedType: 0x01, flags: Flags.CAN_HAVE_METADATA.rawValue | Flags.CAN_HAVE_DATA.rawValue)
            case .Lease:
                return FrameTypeClass(encodedType: 0x02, flags: Flags.CAN_HAVE_METADATA.rawValue)
            case .RequestResponse:
                return FrameTypeClass(encodedType: 0x04, flags: Flags.CAN_HAVE_DATA.rawValue |                                                      Flags.CAN_HAVE_METADATA.rawValue |
                                                             Flags.IS_FRAGMENTABLE.rawValue |
                                                             Flags.IS_REQUEST_TYPE.rawValue)
                    
        case .KeepAlive:
            return FrameTypeClass(encodedType: 0x03, flags: Flags.CAN_HAVE_DATA.rawValue)
        case .RequestFnF:
            return FrameTypeClass(encodedType: 0x05, flags: Flags.CAN_HAVE_DATA.rawValue |                                                          Flags.CAN_HAVE_METADATA.rawValue |
                                                         Flags.IS_FRAGMENTABLE.rawValue |
                                                         Flags.IS_REQUEST_TYPE.rawValue)
        case .RequestStream:
            return FrameTypeClass(encodedType: 0x06, flags: Flags.CAN_HAVE_METADATA.rawValue |
                                                         Flags.CAN_HAVE_DATA.rawValue |
                                                         Flags.HAS_INITIAL_REQUEST_N.rawValue |
                                                         Flags.IS_FRAGMENTABLE.rawValue |
                                                         Flags.IS_REQUEST_TYPE.rawValue)
        case .RequestChannel:
            return FrameTypeClass(encodedType: 0x07, flags: Flags.CAN_HAVE_METADATA.rawValue |
                                                         Flags.CAN_HAVE_DATA.rawValue |
                                                         Flags.HAS_INITIAL_REQUEST_N.rawValue |
                                                         Flags.IS_FRAGMENTABLE.rawValue |
                                                         Flags.IS_REQUEST_TYPE.rawValue)
        case .RequestN:
            return FrameTypeClass(encodedType: 0x08)
        case .Cancel:
            return FrameTypeClass(encodedType: 0x09)
        case .Payload:
            return FrameTypeClass(encodedType: 0x0A, flags: Flags.CAN_HAVE_DATA.rawValue |                                                          Flags.CAN_HAVE_METADATA.rawValue |
                                                         Flags.IS_FRAGMENTABLE.rawValue)
        case .Error:
            return FrameTypeClass(encodedType: 0x0B, flags: Flags.CAN_HAVE_DATA.rawValue)
        case .MetadataPush:
            return FrameTypeClass(encodedType: 0x0C, flags: Flags.CAN_HAVE_METADATA.rawValue)
        case .Resume:
            return FrameTypeClass(encodedType: 0x0D)
        case .ResumeOk:
            return FrameTypeClass(encodedType: 0x0E)
        case .Extension:
            return FrameTypeClass(encodedType: 0x3F, flags: Flags.CAN_HAVE_DATA.rawValue |                                                          Flags.CAN_HAVE_METADATA.rawValue)
        case .Next:
            return FrameTypeClass(encodedType: 0xA0, flags: Flags.CAN_HAVE_DATA.rawValue |                                                          Flags.CAN_HAVE_METADATA.rawValue |
                                                         Flags.IS_FRAGMENTABLE.rawValue)
        case .Complete:
            return FrameTypeClass(encodedType: 0xB0)
        case .NextComplete:
            return FrameTypeClass(encodedType: 0xC0, flags: Flags.CAN_HAVE_DATA.rawValue |                                                          Flags.CAN_HAVE_METADATA.rawValue |
                                                         Flags.IS_FRAGMENTABLE.rawValue)
        }
    }
     public enum Flags: Int {
         case EMPTY = 0b00000
         case CAN_HAVE_DATA = 0b10000
         case CAN_HAVE_METADATA = 0b01000
         case IS_FRAGMENTABLE = 0b00100
         case IS_REQUEST_TYPE = 0b00010
         case HAS_INITIAL_REQUEST_N = 0b00001
     }
 }

public class FrameTypeClass {
    
    private var encodedType: Int
    private var flags: Int

    init(encodedType: Int) {
        self.encodedType = encodedType
        self.flags = FrameType.Flags.EMPTY.rawValue
    }
    
    init(encodedType: Int, flags: Int) {
        self.encodedType = encodedType
        self.flags = flags
    }
    
    private static var FRAME_TYPES_BY_ENCODED_TYPE : [Int:FrameType] = [:] {
         didSet {
            for frametype in FrameType.allCases {
                FRAME_TYPES_BY_ENCODED_TYPE[frametype.frameTypeValue.getEncodedType()] = frametype
            }
         }
     }
     
   /* func getValues(encodeType: Int) {
        let maxFrameType_Cases = encodeType <= FrameType.allCases.count ? encodeType : FrameType.allCases.count
        var FRAME_TYPES_BY_ENCODED_TYPE : [FrameType] = []
        for i in 0...maxFrameType_Cases {
            FRAME_TYPES_BY_ENCODED_TYPE.append(FrameType.allCases[i])
        }
    }*/
    
    public func getEncodedType() -> Int{
      return encodedType
    }

     public static func fromEncodedType(encodedType: Int) throws -> FrameType {
         let frameType: FrameType? = FRAME_TYPES_BY_ENCODED_TYPE[encodedType]
         guard let frametype =  frameType else {
             throw NSException(name: NSExceptionName(rawValue: "IllegalArgumentException"), reason: "Frame type is unknown : \(encodedType)", userInfo:nil) as! Error
         }
         return frametype
     }
     /**
      * Verifies whether the frame type can have data.
      - Parameter flags: Flags constant.
      - Returns: whether the frame type can have data
      */
    public func canHaveData() -> Bool {
        return FrameType.Flags.CAN_HAVE_DATA.rawValue == (flags & FrameType.Flags.CAN_HAVE_DATA.rawValue)
     }
     
     /**
      * Verifies whether the frame type can have metadata
      - Parameter flags: Flags constant.
      - Returns: whether the frame type can have metadata
      */
    public func canHaveMetaData() -> Bool {
        return FrameType.Flags.CAN_HAVE_METADATA.rawValue == (flags & FrameType.Flags.CAN_HAVE_METADATA.rawValue)
     }
     
     /**
      * Verifies whether the frame type starts with an initial {@code requestN}.
      - Parameter flags: Flags constant.
      - Returns: wether the frame type starts with an initial {@code requestN}
      */
    public func hasInitialRequestN() -> Bool {
        return FrameType.Flags.HAS_INITIAL_REQUEST_N.rawValue == (flags & FrameType.Flags.HAS_INITIAL_REQUEST_N.rawValue)
     }
     
    /**
     Verifies whether the frame type is fragmentable.
     - Parameter flags: Flags constant.
     - Returns: whether the frame type is fragmentable
     */
    public func isFragmentable() -> Bool {
        return FrameType.Flags.IS_FRAGMENTABLE.rawValue == (flags & FrameType.Flags.IS_FRAGMENTABLE.rawValue)
     }
     
     /**
     Verifies whether the frame type is a request type.
     - Parameter flags: Flags constant.
     - Returns: whether the frame type is a request type
     */
    public func isRequestType() -> Bool {
        return FrameType.Flags.IS_REQUEST_TYPE.rawValue == (flags & FrameType.Flags.IS_REQUEST_TYPE.rawValue)
     }
     
}
