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

extension Frame {
    internal func splitIntoFragmentsIfNeeded(mtu: Int32) -> [Frame] {
        switch body {
        case let .requestResponse(body):
            let (initialFragment, followingFragments) = body.payload.fragments(
                mtu: mtu,
                firstFragmentAdditionalOffset: .requestResponse
            )
            guard !followingFragments.isEmpty else { return [self] }
            let initialBody = RequestResponseFrameBody(payload: initialFragment)
            return initialBody.createFrames(
                withFollowingFragments: followingFragments,
                streamId: header.streamId,
                lastFragmentShouldCompleteStream: false
            )

        case let .requestFnf(body):
            let (initialFragment, followingFragments) = body.payload.fragments(
                mtu: mtu,
                firstFragmentAdditionalOffset: .requestFnf
            )
            guard !followingFragments.isEmpty else { return [self] }
            let initialBody = RequestFireAndForgetFrameBody(payload: initialFragment)
            return initialBody.createFrames(
                withFollowingFragments: followingFragments,
                streamId: header.streamId,
                lastFragmentShouldCompleteStream: false
            )

        case let .requestStream(body):
            let (initialFragment, followingFragments) = body.payload.fragments(
                mtu: mtu,
                firstFragmentAdditionalOffset: .requestStream
            )
            guard !followingFragments.isEmpty else { return [self] }
            let initialBody = RequestStreamFrameBody(
                initialRequestN: body.initialRequestN,
                payload: initialFragment
            )
            return initialBody.createFrames(
                withFollowingFragments: followingFragments,
                streamId: header.streamId,
                lastFragmentShouldCompleteStream: false
            )

        case let .requestChannel(body):
            let (initialFragment, followingFragments) = body.payload.fragments(
                mtu: mtu,
                firstFragmentAdditionalOffset: .requestChannel
            )
            guard !followingFragments.isEmpty else { return [self] }
            let initialBody = RequestChannelFrameBody(
                isCompleted: false, // if the channel is already completed is sent on the last fragment
                initialRequestN: body.initialRequestN,
                payload: initialFragment
            )
            return initialBody.createFrames(
                withFollowingFragments: followingFragments,
                streamId: header.streamId,
                lastFragmentShouldCompleteStream: body.isCompleted
            )

        case let .payload(body):
            let (initialFragment, followingFragments) = body.payload.fragments(
                mtu: mtu,
                firstFragmentAdditionalOffset: .payload
            )
            guard !followingFragments.isEmpty else { return [self] }
            let initialBody = PayloadFrameBody(
                isCompletion: false, // if the payload completes the stream it is sent on the last fragment
                isNext: true,
                payload: initialFragment
            )
            return initialBody.createFrames(
                withFollowingFragments: followingFragments,
                streamId: header.streamId,
                lastFragmentShouldCompleteStream: body.isCompletion
            )

        default:
            return [self]
        }
    }
}

private extension FrameBodyBoundToStream {
    func createFrames(
        withFollowingFragments fragments: [Payload],
        streamId: StreamID,
        lastFragmentShouldCompleteStream: Bool
    ) -> [Frame] {
        precondition(!fragments.isEmpty)
        return [
            Frame(
                header: header(withStreamId: streamId, additionalFlags: .fragmentFollows),
                body: body()
            )
        ] + fragments.enumerated().map { index, fragment in
            let isLastFragment = index == fragments.count - 1
            let isFragmentCompletion = lastFragmentShouldCompleteStream && isLastFragment
            let fragmentBody = PayloadFrameBody(
                isCompletion: isFragmentCompletion,
                isNext: false,
                payload: fragment
            )
            return Frame(
                header: fragmentBody.header(
                    withStreamId: streamId,
                    additionalFlags: isLastFragment ? [] : .fragmentFollows
                ),
                body: fragmentBody.body()
            )
        }
    }
}
