/*
 * Copyright 2015-present the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

public struct WellKnownMIMETypeCode: RawRepresentable, Hashable {
    /// rawValue is guaranteed to be between 0 and 127.
    public var rawValue: UInt8
    public init?(rawValue: UInt8) {
        guard rawValue & 0b1000_0000 == 0 else { return nil }
        self.rawValue = rawValue
    }
}

extension WellKnownMIMETypeCode: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: UInt8) {
        guard let value = Self(rawValue: value) else {
            fatalError("Well Know MIME Type Codes are only allowed to be between 0 and 127.")
        }
        self = value
    }
}

public extension WellKnownMIMETypeCode {
    static let applicationAvro: Self = 0x00 
    static let applicationCbor: Self = 0x01 
    static let applicationGraphql: Self = 0x02 
    static let applicationGzip: Self = 0x03 
    static let applicationJavascript: Self = 0x04 
    static let applicationJson: Self = 0x05 
    static let applicationOctetStream: Self = 0x06 
    static let applicationPdf: Self = 0x07 
    static let applicationVndApacheThriftBinary: Self = 0x08 
    static let applicationVndGoogleProtobuf: Self = 0x09 
    static let applicationXml: Self = 0x0A 
    static let applicationZip: Self = 0x0B 
    static let audioAac: Self = 0x0C 
    static let audioMp3: Self = 0x0D 
    static let audioMp4: Self = 0x0E 
    static let audioMpeg3: Self = 0x0F 
    static let audioMpeg: Self = 0x10 
    static let audioOgg: Self = 0x11 
    static let audioOpus: Self = 0x12 
    static let audioVorbis: Self = 0x13 
    static let imageBmp: Self = 0x14 
    static let imageGif: Self = 0x15 
    static let imageHeicSequence: Self = 0x16 
    static let imageHeic: Self = 0x17 
    static let imageHeifSequence: Self = 0x18 
    static let imageHeif: Self = 0x19 
    static let imageJpeg: Self = 0x1A 
    static let imagePng: Self = 0x1B 
    static let imageTiff: Self = 0x1C 
    static let multipartMixed: Self = 0x1D 
    static let textCss: Self = 0x1E 
    static let textCsv: Self = 0x1F 
    static let textHtml: Self = 0x20 
    static let textPlain: Self = 0x21 
    static let textXml: Self = 0x22 
    static let videoH264: Self = 0x23 
    static let videoH265: Self = 0x24 
    static let videoVp8: Self = 0x25 
    static let applicationXHessian: Self = 0x26 
    static let applicationXJavaObject: Self = 0x27 
    static let applicationCloudeventsJson: Self = 0x28 
    static let applicationXCapnp: Self = 0x29 
    static let applicationXFlatbuffers: Self = 0x2A 
    static let messageXRSocketMimeTypeV0: Self = 0x7A 
    static let messageXRSocketAcceptMimeTypesV0: Self = 0x7b 
    static let messageXRSocketAuthenticationV0: Self = 0x7C 
    static let messageXRSocketTracingZipkinV0: Self = 0x7D 
    static let messageXRSocketRoutingV0: Self = 0x7E 
    static let messageXRSocketCompositeMetadataV0: Self = 0x7F 
}

public extension MIMEType {
    static let wellKnownMIMETypes: [(WellKnownMIMETypeCode, MIMEType)] = [
        (.applicationAvro, .applicationAvro),
        (.applicationCbor, .applicationCbor),
        (.applicationGraphql, .applicationGraphql),
        (.applicationGzip, .applicationGzip),
        (.applicationJavascript, .applicationJavascript),
        (.applicationJson, .applicationJson),
        (.applicationOctetStream, .applicationOctetStream),
        (.applicationPdf, .applicationPdf),
        (.applicationVndApacheThriftBinary, .applicationVndApacheThriftBinary),
        (.applicationVndGoogleProtobuf, .applicationVndGoogleProtobuf),
        (.applicationXml, .applicationXml),
        (.applicationZip, .applicationZip),
        (.audioAac, .audioAac),
        (.audioMp3, .audioMp3),
        (.audioMp4, .audioMp4),
        (.audioMpeg3, .audioMpeg3),
        (.audioMpeg, .audioMpeg),
        (.audioOgg, .audioOgg),
        (.audioOpus, .audioOpus),
        (.audioVorbis, .audioVorbis),
        (.imageBmp, .imageBmp),
        (.imageGif, .imageGif),
        (.imageHeicSequence, .imageHeicSequence),
        (.imageHeic, .imageHeic),
        (.imageHeifSequence, .imageHeifSequence),
        (.imageHeif, .imageHeif),
        (.imageJpeg, .imageJpeg),
        (.imagePng, .imagePng),
        (.imageTiff, .imageTiff),
        (.multipartMixed, .multipartMixed),
        (.textCss, .textCss),
        (.textCsv, .textCsv),
        (.textHtml, .textHtml),
        (.textPlain, .textPlain),
        (.textXml, .textXml),
        (.videoH264, .videoH264),
        (.videoH265, .videoH265),
        (.videoVp8, .videoVp8),
        (.applicationXHessian, .applicationXHessian),
        (.applicationXJavaObject, .applicationXJavaObject),
        (.applicationCloudeventsJson, .applicationCloudeventsJson),
        (.applicationXCapnp, .applicationXCapnp),
        (.applicationXFlatbuffers, .applicationXFlatbuffers),
        (.messageXRSocketMimeTypeV0, .messageXRSocketMimeTypeV0),
        (.messageXRSocketAcceptMimeTypesV0, .messageXRSocketAcceptMimeTypesV0),
        (.messageXRSocketAuthenticationV0, .messageXRSocketAuthenticationV0),
        (.messageXRSocketTracingZipkinV0, .messageXRSocketTracingZipkinV0),
        (.messageXRSocketRoutingV0, .messageXRSocketRoutingV0),
        (.messageXRSocketCompositeMetadataV0, .messageXRSocketCompositeMetadataV0),
    ]
}


