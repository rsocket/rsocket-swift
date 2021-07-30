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

struct Route<Key: Hashable, Handler> {
    var key: Key
    var handler: Handler
    init(_ key: Key, handler: () -> Handler) {
        self.key = key
        self.handler = handler()
    }
}

protocol RequestResponseHandler {
    func requestResponse(payload: Payload, responderStream: UnidirectionalStream) throws -> Cancellable
}

struct TableRouter<Key: Hashable> {
    var getKey: (Payload, ConnectionEncoding) throws -> Key
    var requestResponseRoutes: [Key: RequestResponseHandler]
}

extension TableRouter {
    static func firstRoutingTag() -> TableRouter<String> {
        .init(
            getKey: { (payload, connectionEncoding) in
                guard let metadata = payload.metadata else {
                    throw Error.invalid(message: "can not route request without metadata")
                }
                let decoder = RoutingDecoder()
                let route = try decoder.decode(from: metadata)

                guard let tag = route.tags.first else {
                    throw Error.invalid(message: "can not route request because routing metadata contains no tags")
                }
                return tag
            },
            requestResponseRoutes: [:]
        )
    }
}

extension TableRouter: RequestResponseHandler {
    func requestResponse(payload: Payload, responderStream: UnidirectionalStream) throws -> Cancellable {
        let encoding = ConnectionEncoding.default // TODO: we need to get the actual encoding from somewhere

        let key = try getKey(payload, encoding)
        guard let handler = requestResponseRoutes[key] else {
            throw Error.invalid(message: "\(key) is not a valid route")
        }
        return try handler.requestResponse(payload: payload, responderStream: responderStream)
    }
}


extension Error {
    init(_ genericError: Swift.Error) {
        if let knowError = genericError as? Error {
            self = knowError
        } else {
            self = Error.applicationError(message: genericError.localizedDescription)
        }
    }
}
