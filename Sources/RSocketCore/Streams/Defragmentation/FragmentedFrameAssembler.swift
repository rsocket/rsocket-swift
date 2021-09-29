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

import NIOCore

internal enum FragmentationResult: Equatable {
    case complete(Frame)
    case incomplete
    case error(reason: String)
}

internal struct FragmentedFrameAssembler {
    private var fragments: Fragments?

    internal mutating func process(frame: Frame) -> FragmentationResult {
        switch frame.body {
        case .requestResponse, .requestFnf, .requestStream, .requestChannel:
            return processInitialFragment(frame: frame)

        case let .payload(body):
            switch (body.isNext, body.isCompletion) {
            case (true, _):
                guard var fragments = fragments else {
                    return processInitialFragment(frame: frame)
                }
                fragments.additionalFragments.append(body.payload)
                fragments.isCompletion = body.isCompletion
                guard body.isCompletion || !body.fragmentFollows else {
                    self.fragments = fragments
                    return .incomplete
                }
                switch fragments.buildFrame() {
                case let .success(completedFrame):
                    self.fragments = nil
                    return .complete(completedFrame)
                case let .error(reason: reason):
                    return .error(reason: reason)
                }

            case (false, true):
                guard fragments == nil else {
                    return .error(reason: "Got (C)omplete only frame but there is a current set of fragments to extend")
                }
                return .complete(frame)

            case (false, false):
                return .error(reason: "A payload frame must not have both (C)omplete and (N)ext empty (false)")
            }

        case .cancel:
            fragments = nil
            return .complete(frame)

        case .setup, .lease, .keepalive, .requestN, .error, .metadataPush, .resume, .resumeOk, .ext:
            guard fragments == nil else {
                return .error(reason: "Current set of fragments is not complete")
            }
            return .complete(frame)
        }
    }

    private mutating func processInitialFragment(frame: Frame) -> FragmentationResult {
        guard fragments == nil else {
            return .error(reason: "Current set of fragments is not complete")
        }
        if frame.body.fragmentsFollows {
            fragments = Fragments(initialFrame: frame)
            return .incomplete
        } else {
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
        var metadata: ByteBuffer? = initialPayload.metadata
        var data: ByteBuffer = initialPayload.data
        for fragment in additionalFragments {
            if var metadataFragment = fragment.metadata {
                guard data.readableBytes == 0 else {
                    return .error(reason: "Fragment has metadata even though previous fragments had data")
                }
                if metadata == nil {
                    // previous fragments didn't have metadata or data
                    metadata = metadataFragment
                } else {
                    metadata?.writeBuffer(&metadataFragment)
                }
            }
            var fragmentData = fragment.data
            data.writeBuffer(&fragmentData)
        }
        let newPayload = Payload(metadata: metadata, data: data)

        // build assembled frame
        switch initialFrame.body {
        case .requestResponse:
            let newFrame = RequestResponseFrameBody(payload: newPayload)
                .asFrame(withStreamId: initialFrame.streamId)
            return .success(newFrame)

        case .requestFnf:
            let newFrame = RequestFireAndForgetFrameBody(payload: newPayload)
                .asFrame(withStreamId: initialFrame.streamId)
            return .success(newFrame)

        case let .requestStream(body):
            let newFrame = RequestStreamFrameBody(
                initialRequestN: body.initialRequestN,
                payload: newPayload
            ).asFrame(withStreamId: initialFrame.streamId)
            return .success(newFrame)

        case let .requestChannel(body):
            let newFrame = RequestChannelFrameBody(
                isCompleted: isCompletion,
                initialRequestN: body.initialRequestN,
                payload: newPayload
            ).asFrame(withStreamId: initialFrame.streamId)
            return .success(newFrame)

        case .payload:
            let newFrame = PayloadFrameBody(
                isCompletion: isCompletion,
                isNext: true, // only frames that have isNext can be fragmented
                payload: newPayload
            ).asFrame(withStreamId: initialFrame.streamId)
            return .success(newFrame)

        default:
            // Only those frame types above can be fragmented
            // Thus the FragmentedFrameAssembler will never instantiate this with a different frame type
            return .error(reason: "Unsupported initial frame")
        }
    }
}
