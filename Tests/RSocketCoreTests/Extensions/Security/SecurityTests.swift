//
//  SecurityTests.swift
//
//
//  Created by Elyes Ben Salah on 3/2/2023.
//


import XCTest
import NIOCore
@testable import RSocketCore


final class SecurityTests: XCTestCase {
    
    
    func testTest() throws {
        let encoder = AuthenticationEncoder()
        let decoder = AuthenticationDecoder()
        
        var resultEncoder = ByteBuffer()
        let authentication = Authentication(type : .init(rawValue: "kindi"), payload: ByteBuffer(string: "someDataForKindiAuth"))
        try encoder.encode(authentication , into: &resultEncoder)
        let resultDecoder  = try decoder.decode(from: &resultEncoder)
        
        debugPrint(resultDecoder.type)
    }
    
    
    func testBearerAuth() throws {
        let encoder = BearerAuthenticationEncoder()
        let decoder = BearerAuthenticationDecoder()
        
        var resultEncoder = ByteBuffer()
        try encoder.encode("Token",into: &resultEncoder)
        let data = resultEncoder.getBytes(at: 0, length: resultEncoder.readableBytes)!
        debugPrint(data)
        var buffToDecode = ByteBuffer(bytes: data)
        let authRz = try decoder.decode(from: &buffToDecode)
        
        debugPrint("Bearer Auth Decoded \nToken : \(authRz)")

    }

    func testSimpleAuth() throws {
        let encoder = SimpleAuthenticationEncoder()
        let decoder = SimpleAuthenticationDecoder()
        let auth = SimpleAuthentication(username: "LoginasjdjqfjeqfjnqefkqenkqegknqegknqefknqefasjdjqfjeqfjnqefkqenkqegknqegknqegknqefknqefknLoginasjdjqfjeqfjnqefkqenkq", password: "Passwordqqn")
        var resultEncoder = ByteBuffer()
        try encoder.encode(auth,into: &resultEncoder)
        debugPrint(resultEncoder.getBytes(at: 0, length: resultEncoder.readableBytes)!)
        debugPrint(resultEncoder.getString(at: 0, length: resultEncoder.readableBytes)!)
        
        let authRz = try decoder.decode(from: &resultEncoder)
        debugPrint(authRz)

    }
    func testCustomAuth() throws {
        let encoder = CustomAuthenticationEncoder()
        let decoder = CustomAuthenticationDecoder()
        
        var resultEncoder = ByteBuffer()
        let authentication = Authentication(type : .init(rawValue: "kindi"), payload: ByteBuffer(string: "someDataForKindiAuth"))

        try encoder.encode(authentication,into: &resultEncoder)
        let data = resultEncoder.getBytes(at: 0, length: resultEncoder.readableBytes)!
        debugPrint(data)
        var buffToDecode = ByteBuffer(bytes: data)
        var authRz = try decoder.decode(from: &buffToDecode)
        
        debugPrint("Custom Auth Decoded :\nType : \(authRz.type.rawValue)\nData : \(authRz.payload.readString(length: authRz.payload.readableBytes))")

    }
    
    
    func testWellKnowAuthTypes() throws {
        //Simple Auth
        let simpleEncoder = SimpleAuthenticationEncoder()
        let simpleAuth = SimpleAuthentication(username: "LoginasjdjqfjeqfjnqefkqenkqegknqegknqefknqefknLoginasjdjqfjeqfjnqefkqenkqegknqegknqefknqefknLoginasjdjqfjeqfjnqefkqenkqegknqegknqefknqefknLoginasjdjqfjeqfjnqefkqenkqegknqegknqefknqefknLoginasjdjqfjeqfjnqefkqenkqegknqegknqefknqefknLoginasjdjqfjeqfjnqefkqenkq", password: "Passwordqqn")
        var simpleAuthBuffer = ByteBuffer()
        try simpleEncoder.encode(simpleAuth,into: &simpleAuthBuffer)
        let resultSimple = AuthenticationDecoder.isWellKnownAuthType(simpleAuthBuffer)
        
        //Bearer Auth
        let bearerEncoder = BearerAuthenticationEncoder()
        var bearerAuthBuffer = ByteBuffer()
        try bearerEncoder.encode("MyToken",into: &bearerAuthBuffer)
        let bearerResult = AuthenticationDecoder.isWellKnownAuthType(bearerAuthBuffer)

        
        //Custom Auth
        let customEncoder = CustomAuthenticationEncoder()
        var customAuthBuffer = ByteBuffer()
        let auth = Authentication(type : .init(rawValue: "Kindi"), payload : ByteBuffer(string: "SomeDataForKindiAuth"))
        try customEncoder.encodeCustomMetadata(auth, into: &customAuthBuffer)
        let customResult = AuthenticationDecoder.isWellKnownAuthType(customAuthBuffer)

        debugPrint("isWellKnown SimpleAuth : \(resultSimple)")
        debugPrint("isWellKnown BearerAuth : \(bearerResult)")
        debugPrint("isWellKnown CustomAuth : \(!customResult)")
    }
}
