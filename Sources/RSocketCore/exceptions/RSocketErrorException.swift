//
//  RSocketErrorException.swift
//  RSocketSwift
//
//  Created by npatil5  on 10/29/20.
//

import Foundation


public class RSocketErrorException : NSException {
    
    private static let serialVersionUID = -1628781753426267554

    private static let MIN_ERROR_CODE = 0x00000001

    private static let MAX_ERROR_CODE = 0xFFFFFFFE

    private let errorCode: Int
    private let message: String
    
   public init(errorCode: Int, message: String = "")  throws {
        
        self.errorCode = errorCode
        self.message = message
        if errorCode > RSocketErrorException.MAX_ERROR_CODE && errorCode < RSocketErrorException.MIN_ERROR_CODE {
            throw NSException(name: NSExceptionName("IllegalArgumentException"), reason: "Allowed errorCode value should be in range [0x00000001-0xFFFFFFFE]", userInfo: nil) as! Error
        }
        super.init(name: NSExceptionName(""), reason: "", userInfo: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func getErrorCode() -> Int {
      return errorCode
    }
    
    public func getMessage() -> String {
        return message
    }
    
    public func toString() -> String {
        return "\(String(describing: self)) \(errorCode) \(message)"
    }
}
