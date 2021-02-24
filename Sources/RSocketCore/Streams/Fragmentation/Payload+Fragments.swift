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

extension Payload {
    internal func fragments(
        mtu: Int32,
        firstFragmentAdditionalOffset: FrameOffset
    ) -> (initialFragment: Payload, followingFragments: [Payload]) {
        let frameMtu = Int(mtu - Constants.frameHeaderOffset)
        let frameWithMetadataMtu = Int(mtu - Constants.frameHeaderOffsetWithMetadata)

        let initialFragment: Payload
        var followingFragments: [Payload] = []
        /// The data which is remaining after creating initial fragment
        var remainingData = data

        if let metadata = metadata {
            // set initial fragment with metadata
            let initialFrameMtu = frameWithMetadataMtu - firstFragmentAdditionalOffset.numberOfBytes
            if initialFrameMtu >= metadata.count {
                // initial fragment contains all of the metadata
                let initialFrameMetadata = metadata.prefix(initialFrameMtu)
                let remainingMtu = initialFrameMtu - initialFrameMetadata.count
                if remainingMtu > 0 {
                    // initial fragment has metadata and data
                    let initialFrameData = remainingData.prefix(remainingMtu)
                    remainingData = remainingData.dropFirst(remainingMtu)
                    initialFragment = Payload(metadata: initialFrameMetadata, data: initialFrameData)
                } else {
                    // initial fragment is metadata only
                    initialFragment = Payload(metadata: initialFrameMetadata, data: Data())
                }
            } else {
                // metadata is bigger than initial fragment has to be carried over to fragments
                let initialFrameMetadata = metadata.prefix(initialFrameMtu)
                initialFragment = Payload(metadata: initialFrameMetadata, data: Data())

                // add rest of metadata as following fragments
                let remainingMetadata = metadata.dropFirst(initialFrameMtu)
                let metadataFragments = remainingMetadata.split(maxLength: frameWithMetadataMtu)
                for (index, metadataFragment) in metadataFragments.enumerated() {
                    let isLastMetadataFragment = index == metadataFragments.count - 1
                    if isLastMetadataFragment {
                        let remainingMtu = frameWithMetadataMtu - metadataFragment.count
                        if remainingMtu > 0 {
                            // last fragment has metadata and data
                            let fragmentData = remainingData.prefix(remainingMtu)
                            remainingData = remainingData.dropFirst(remainingMtu)
                            followingFragments.append(Payload(metadata: metadataFragment, data: fragmentData))
                        } else {
                            // last fragment is metadata only
                            followingFragments.append(Payload(metadata: metadataFragment, data: Data()))
                        }
                    } else {
                        // fragment is metadata only because metadata fragments follow
                        followingFragments.append(Payload(metadata: metadataFragment, data: Data()))
                    }
                }
            }
        } else {
            // set initial fragment with data only
            let initialFrameMtu = frameMtu - firstFragmentAdditionalOffset.numberOfBytes
            let initialFrameData = remainingData.prefix(initialFrameMtu)
            remainingData = remainingData.dropFirst(initialFrameMtu)
            initialFragment = Payload(data: initialFrameData)
        }

        if !remainingData.isEmpty {
            followingFragments += remainingData.split(maxLength: frameMtu).map { Payload(data: $0) }
        }

        return (initialFragment, followingFragments)
    }
}

private extension Collection where Index: Strideable {
    func split(maxLength: Index.Stride) -> [SubSequence] {
        stride(from: startIndex, to: endIndex, by: maxLength)
            .map { self[$0..<Swift.min($0.advanced(by: maxLength), endIndex)] }
    }
}
