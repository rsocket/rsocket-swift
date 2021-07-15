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


/// This SHOULD be a US-ASCII string that includes the Internet media type specified in RFC 2045.
/// Many are registered with IANA such as CBOR.
///
/// If you want to use a MIME Type which is not defined on `MIMEType`, it is recommended to add a static property trough an extension:
/// ```
/// extension MIMEType {
///     static let png = MIMEType(rawValue: "image/png")
/// }
/// ```
/// This allows to use `.png` (i.e. implicit member expression) in a context where the type can be inferred e.g:
/// ```
/// let config = ClientConfiguration
///     .mobileToServer
///     .set(\.encoding.data, to: .png)
/// ```
public struct MIMEType: RawRepresentable, Hashable {
    public private(set) var rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public extension MIMEType {
    /// default is currently `MIMEType.applicationOctetStream`
    static let `default` = applicationOctetStream
}

// All well-know MIME Types as defined in the RSocket Well-known MIME Types Extensions specification
public extension MIMEType {
    static let applicationAvro = Self(rawValue: "application/avro")
    static let applicationCbor = Self(rawValue: "application/cbor")
    static let applicationGraphql = Self(rawValue: "application/graphql")
    static let applicationGzip = Self(rawValue: "application/gzip")
    static let applicationJavascript = Self(rawValue: "application/javascript")
    static let applicationJson = Self(rawValue: "application/json")
    static let applicationOctetStream = Self(rawValue: "application/octet-stream")
    static let applicationPdf = Self(rawValue: "application/pdf")
    static let applicationVndApacheThriftBinary = Self(rawValue: "application/vnd.apache.thrift.binary")
    static let applicationVndGoogleProtobuf = Self(rawValue: "application/vnd.google.protobuf")
    static let applicationXml = Self(rawValue: "application/xml")
    static let applicationZip = Self(rawValue: "application/zip")
    static let audioAac = Self(rawValue: "audio/aac")
    static let audioMp3 = Self(rawValue: "audio/mp3")
    static let audioMp4 = Self(rawValue: "audio/mp4")
    static let audioMpeg3 = Self(rawValue: "audio/mpeg3")
    static let audioMpeg = Self(rawValue: "audio/mpeg")
    static let audioOgg = Self(rawValue: "audio/ogg")
    static let audioOpus = Self(rawValue: "audio/opus")
    static let audioVorbis = Self(rawValue: "audio/vorbis")
    static let imageBmp = Self(rawValue: "image/bmp")
    static let imageGif = Self(rawValue: "image/gif")
    static let imageHeicSequence = Self(rawValue: "image/heic-sequence")
    static let imageHeic = Self(rawValue: "image/heic")
    static let imageHeifSequence = Self(rawValue: "image/heif-sequence")
    static let imageHeif = Self(rawValue: "image/heif")
    static let imageJpeg = Self(rawValue: "image/jpeg")
    static let imagePng = Self(rawValue: "image/png")
    static let imageTiff = Self(rawValue: "image/tiff")
    static let multipartMixed = Self(rawValue: "multipart/mixed")
    static let textCss = Self(rawValue: "text/css")
    static let textCsv = Self(rawValue: "text/csv")
    static let textHtml = Self(rawValue: "text/html")
    static let textPlain = Self(rawValue: "text/plain")
    static let textXml = Self(rawValue: "text/xml")
    static let videoH264 = Self(rawValue: "video/H264")
    static let videoH265 = Self(rawValue: "video/H265")
    static let videoVp8 = Self(rawValue: "video/VP8")
    static let applicationXHessian = Self(rawValue: "application/x-hessian")
    static let applicationXJavaObject = Self(rawValue: "application/x-java-object")
    static let applicationCloudeventsJson = Self(rawValue: "application/cloudevents+json")
    static let applicationXCapnp = Self(rawValue: "application/x-capnp")
    static let applicationXFlatbuffers = Self(rawValue: "application/x-flatbuffers")
    static let messageXRSocketMimeTypeV0 = Self(rawValue: "message/x.rsocket.mime-type.v0")
    static let messageXRSocketAcceptMimeTypesV0 = Self(rawValue: "message/x.rsocket.accept-mime-types.v0")
    static let messageXRSocketAuthenticationV0 = Self(rawValue: "message/x.rsocket.authentication.v0")
    static let messageXRSocketTracingZipkinV0 = Self(rawValue: "message/x.rsocket.tracing-zipkin.v0")
    static let messageXRSocketRoutingV0 = Self(rawValue: "message/x.rsocket.routing.v0")
    static let messageXRSocketCompositeMetadataV0 = Self(rawValue: "message/x.rsocket.composite-metadata.v0")
}
