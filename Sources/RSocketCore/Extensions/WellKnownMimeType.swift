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
            preconditionFailure("Well Know MIME Type Codes are only allowed to be between 0 and 127.")
        }
        self = value
    }
}

extension MIMEType {
    static let applicationAvro = Self(rawValue: "application/avro") //0x00
    static let applicationCbor = Self(rawValue: "application/cbor") //0x01
    static let applicationGraphql = Self(rawValue: "application/graphql") //0x02
    static let applicationGzip = Self(rawValue: "application/gzip") //0x03
    static let applicationJavascript = Self(rawValue: "application/javascript") //0x04
    static let applicationJson = Self(rawValue: "application/json") //0x05
    static let applicationOctetStream = Self(rawValue: "application/octet-stream") //0x06
    static let applicationPdf = Self(rawValue: "application/pdf") //0x07
    static let applicationVndApacheThriftBinary = Self(rawValue: "application/vnd.apache.thrift.binary") //0x08
    static let applicationVndGoogleProtobuf = Self(rawValue: "application/vnd.google.protobuf") //0x09
    static let applicationXml = Self(rawValue: "application/xml") //0x0A
    static let applicationZip = Self(rawValue: "application/zip") //0x0B
    static let audioAac = Self(rawValue: "audio/aac") //0x0C
    static let audioMp3 = Self(rawValue: "audio/mp3") //0x0D
    static let audioMp4 = Self(rawValue: "audio/mp4") //0x0E
    static let audioMpeg3 = Self(rawValue: "audio/mpeg3") //0x0F
    static let audioMpeg = Self(rawValue: "audio/mpeg") //0x10
    static let audioOgg = Self(rawValue: "audio/ogg") //0x11
    static let audioOpus = Self(rawValue: "audio/opus") //0x12
    static let audioVorbis = Self(rawValue: "audio/vorbis") //0x13
    static let imageBmp = Self(rawValue: "image/bmp") //0x14
    static let imageGif = Self(rawValue: "image/gif") //0x15
    static let imageHeicSequence = Self(rawValue: "image/heic-sequence") //0x16
    static let imageHeic = Self(rawValue: "image/heic") //0x17
    static let imageHeifSequence = Self(rawValue: "image/heif-sequence") //0x18
    static let imageHeif = Self(rawValue: "image/heif") //0x19
    static let imageJpeg = Self(rawValue: "image/jpeg") //0x1A
    static let imagePng = Self(rawValue: "image/png") //0x1B
    static let imageTiff = Self(rawValue: "image/tiff") //0x1C
    static let multipartMixed = Self(rawValue: "multipart/mixed") //0x1D
    static let textCss = Self(rawValue: "text/css") //0x1E
    static let textCsv = Self(rawValue: "text/csv") //0x1F
    static let textHtml = Self(rawValue: "text/html") //0x20
    static let textPlain = Self(rawValue: "text/plain") //0x21
    static let textXml = Self(rawValue: "text/xml") //0x22
    static let videoH264 = Self(rawValue: "video/H264") //0x23
    static let videoH265 = Self(rawValue: "video/H265") //0x24
    static let videoVp8 = Self(rawValue: "video/VP8") //0x25
    static let applicationXHessian = Self(rawValue: "application/x-hessian") //0x26
    static let applicationXJavaObject = Self(rawValue: "application/x-java-object") //0x27
    static let applicationCloudeventsJson = Self(rawValue: "application/cloudevents+json") //0x28
    static let applicationXCapnp = Self(rawValue: "application/x-capnp") //0x29
    static let applicationXFlatbuffers = Self(rawValue: "application/x-flatbuffers") //0x2A
    static let messageXRSocketMimeTypeV0 = Self(rawValue: "message/x.rsocket.mime-type.v0") //0x7A
    static let messageXRSocketAcceptMimeTypesV0 = Self(rawValue: "message/x.rsocket.accept-mime-types.v0") //0x7b
    static let messageXRSocketAuthenticationV0 = Self(rawValue: "message/x.rsocket.authentication.v0") //0x7C
    static let messageXRSocketTracingZipkinV0 = Self(rawValue: "message/x.rsocket.tracing-zipkin.v0") //0x7D
    static let messageXRSocketRoutingV0 = Self(rawValue: "message/x.rsocket.routing.v0") //0x7E
    static let messageXRSocketCompositeMetadataV0 = Self(rawValue: "message/x.rsocket.composite-metadata.v0") //0x7F
}

extension MIMEType {
    static let wellKnownMIMETypes: [(WellKnownMIMETypeCode, MIMEType)] = [
        (0x00, .applicationAvro),
        (0x01, .applicationCbor),
        (0x02, .applicationGraphql),
        (0x03, .applicationGzip),
        (0x04, .applicationJavascript),
        (0x05, .applicationJson),
        (0x06, .applicationOctetStream),
        (0x07, .applicationPdf),
        (0x08, .applicationVndApacheThriftBinary),
        (0x09, .applicationVndGoogleProtobuf),
        (0x0A, .applicationXml),
        (0x0B, .applicationZip),
        (0x0C, .audioAac),
        (0x0D, .audioMp3),
        (0x0E, .audioMp4),
        (0x0F, .audioMpeg3),
        (0x10, .audioMpeg),
        (0x11, .audioOgg),
        (0x12, .audioOpus),
        (0x13, .audioVorbis),
        (0x14, .imageBmp),
        (0x15, .imageGif),
        (0x16, .imageHeicSequence),
        (0x17, .imageHeic),
        (0x18, .imageHeifSequence),
        (0x19, .imageHeif),
        (0x1A, .imageJpeg),
        (0x1B, .imagePng),
        (0x1C, .imageTiff),
        (0x1D, .multipartMixed),
        (0x1E, .textCss),
        (0x1F, .textCsv),
        (0x20, .textHtml),
        (0x21, .textPlain),
        (0x22, .textXml),
        (0x23, .videoH264),
        (0x24, .videoH265),
        (0x25, .videoVp8),
        (0x26, .applicationXHessian),
        (0x27, .applicationXJavaObject),
        (0x28, .applicationCloudeventsJson),
        (0x29, .applicationXCapnp),
        (0x2A, .applicationXFlatbuffers),
        (0x7A, .messageXRSocketMimeTypeV0),
        (0x7b, .messageXRSocketAcceptMimeTypesV0),
        (0x7C, .messageXRSocketAuthenticationV0),
        (0x7D, .messageXRSocketTracingZipkinV0),
        (0x7E, .messageXRSocketRoutingV0),
        (0x7F, .messageXRSocketCompositeMetadataV0),
    ]
}


