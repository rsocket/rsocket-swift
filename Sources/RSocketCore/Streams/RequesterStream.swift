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

final internal class RequesterStream {
    private let id: StreamID
    private var fragmentedFrameAssembler = FragmentedFrameAssembler()
    private var terminationBehaviour: TerminationBehaviour
    internal let output: UnidirectionalStream
    internal weak var delegate: StreamDelegate?

    internal init(
        id: StreamID,
        terminationBehaviour: TerminationBehaviour,
        output: UnidirectionalStream,
        delegate: StreamDelegate? = nil
    ) {
        self.id = id
        self.terminationBehaviour = terminationBehaviour
        self.output = output
        self.delegate = delegate
    }

    internal func receive(frame: Frame) {
        switch fragmentedFrameAssembler.process(frame: frame) {
        case .incomplete:
            break
        case let .complete(completeFrame):
            if let error = completeFrame.forward(to: output) {
                send(frame: error.asFrame(withStreamId: id))
            } else {
                if terminationBehaviour.shouldTerminateAfterResponderSent(frame) {
                    delegate?.terminate(streamId: id)
                }
            }
        case let .error(reason):
            if !frame.header.flags.contains(.ignore) {
                send(frame: Error.connectionError(message: reason).asFrame(withStreamId: id))
            }
        }
    }
}

extension RequesterStream: StreamAdapterDelegate {
    internal func send(frame: Frame) {
        delegate?.send(frame: frame)
        if terminationBehaviour.shouldTerminateAfterRequesterSent(frame) {
            delegate?.terminate(streamId: id)
        }
    }
}
