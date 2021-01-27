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
import NIOHTTP1
import RSocketCore

public final class WebSocketClientTransport: ClientTransport {
    var httpHeaders = HTTPHeaders()
    let url: URL

   public init(url: URL) {
        self.url = url
    }

    public convenience init(url: String) {
        self.init(url: URL(string: url)!)
    }

    /**
     HTTP headers are not case sensitive, and here as we are
     setting the key: value as String will make case sensitive,
     should we write custom implementation to make headers, not case sensitive?
     */
    public func setHeaders(headers: [String: String]) {
        for (key, value) in headers {
            httpHeaders.add(name: key, value: value)
        }
    }
}
