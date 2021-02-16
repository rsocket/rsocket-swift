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

import Foundation

internal enum FragmentationResult {
    case complete(Frame)
    case incomplete
    case error(reason: String)
}

internal struct FragmentedFrameAssembler {
    private var fragments: Fragments?

    internal mutating func process(frame: Frame) -> FragmentationResult {
        switch frame.body {
        case let .requestResponse(body):
            guard fragments == nil else {
                return .error(reason: "Current set of fragments is not complete")
            }
            if body.fragmentsFollow {
                fragments = Fragments(initialFrame: frame)
                return .incomplete
            } else {
                return .complete(frame)
            }

        case let .requestFnf(body):
            guard fragments == nil else {
                return .error(reason: "Current set of fragments is not complete")
            }
            if body.fragmentsFollow {
                fragments = Fragments(initialFrame: frame)
                return .incomplete
            } else {
                return .complete(frame)
            }

        case let .requestStream(body):
            guard fragments == nil else {
                return .error(reason: "Current set of fragments is not complete")
            }
            if body.fragmentsFollow {
                fragments = Fragments(initialFrame: frame)
                return .incomplete
            } else {
                return .complete(frame)
            }

        case let .requestChannel(body):
            guard fragments == nil else {
                return .error(reason: "Current set of fragments is not complete")
            }
            if body.fragmentsFollow {
                fragments = Fragments(initialFrame: frame)
                return .incomplete
            } else {
                return .complete(frame)
            }

        case let .payload(body):
            if body.isNext {
                guard fragments == nil else {
                    return .error(reason: "Current set of fragments is not complete")
                }
                if body.fragmentsFollow {
                    fragments = Fragments(initialFrame: frame)
                    return .incomplete
                } else {
                    return .complete(frame)
                }
            } else {
                guard var fragments = fragments else {
                    return .error(reason: "There is no current set of fragments to extend")
                }
                fragments.additionalFragments.append(body.payload)
                fragments.isCompletion = body.isCompletion
                if body.fragmentsFollow {
                    self.fragments = fragments
                    return .incomplete
                } else {
                    switch fragments.buildFrame() {
                    case let .success(completedFrame):
                        self.fragments = nil
                        return .complete(completedFrame)
                    case let .error(reason: reason):
                        return .error(reason: reason)
                    }
                }
            }

        case .setup, .lease, .keepalive, .requestN, .cancel, .error, .metadataPush, .resume, .resumeOk, .ext:
            guard fragments == nil else {
                return .error(reason: "Current set of fragments is not complete")
            }
            return .complete(frame)
        }
    }
}

private enum FrameBuildResult {
    case success(Frame)
    case error(reason: String)
}

private struct Fragments {
    var initialFrame: Frame
    var additionalFragments: [Payload] = []
    var isCompletion: Bool = false

    func buildFrame() -> FrameBuildResult {
        // get initial payload
        let initialPayload: Payload
        switch initialFrame.body {
        case let .requestResponse(body): initialPayload = body.payload
        case let .requestFnf(body): initialPayload = body.payload
        case let .requestStream(body): initialPayload = body.payload
        case let .requestChannel(body): initialPayload = body.payload
        case let .payload(body): initialPayload = body.payload
        default:
            // Only those frame types above can be fragmented
            // Thus the FragmentedFrameAssembler will never instantiate this with a different frame type
            return .error(reason: "Unsupported initial frame")
        }

        // concatenate fragments
        var metadata: Data? = initialPayload.metadata
        var data: Data = initialPayload.data
        for fragment in additionalFragments {
            if let metadataFragment = fragment.metadata {
                guard data.isEmpty else {
                    return .error(reason: "Fragment has metadata even though previous fragments had data")
                }
                if let previousMetadata = metadata {
                    metadata = previousMetadata + metadataFragment
                } else {
                    // previous fragments didn't have metadata or data
                    metadata = metadataFragment
                }
            }
            data += fragment.data
        }
        let newPayload = Payload(metadata: metadata, data: data)

        // build assembled frame
        switch initialFrame.body {
        case .requestResponse:
            let newBody = RequestResponseFrameBody(
                fragmentsFollow: false,
                payload: newPayload
            )
            let newHeader = newBody.header(withStreamId: initialFrame.header.streamId)
            return .success(Frame(header: newHeader, body: .requestResponse(newBody)))

        case .requestFnf:
            let newBody = RequestFireAndForgetFrameBody(
                fragmentsFollow: false,
                payload: newPayload
            )
            let newHeader = newBody.header(withStreamId: initialFrame.header.streamId)
            return .success(Frame(header: newHeader, body: .requestFnf(newBody)))

        case let .requestStream(body):
            let newBody = RequestStreamFrameBody(
                fragmentsFollow: false,
                initialRequestN: body.initialRequestN,
                payload: newPayload
            )
            let newHeader = newBody.header(withStreamId: initialFrame.header.streamId)
            return .success(Frame(header: newHeader, body: .requestStream(newBody)))

        case let .requestChannel(body):
            let newBody = RequestChannelFrameBody(
                fragmentsFollow: false,
                isCompleted: isCompletion,
                initialRequestN: body.initialRequestN,
                payload: newPayload
            )
            let newHeader = newBody.header(withStreamId: initialFrame.header.streamId)
            return .success(Frame(header: newHeader, body: .requestChannel(newBody)))

        case .payload:
            let newBody = PayloadFrameBody(
                fragmentsFollow: false,
                isCompletion: isCompletion,
                isNext: true,
                payload: newPayload
            )
            let newHeader = newBody.header(withStreamId: initialFrame.header.streamId)
            return .success(Frame(header: newHeader, body: .payload(newBody)))

        default:
            // Only those frame types above can be fragmented
            // Thus the FragmentedFrameAssembler will never instantiate this with a different frame type
            return .error(reason: "Unsupported initial frame")
        }
    }
}
