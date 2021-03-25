# RSocket-Swift
rsocket-swift is an implementation of the RSocket protocol in Swift. It's an **alpha** version and still under active development.
**Do not use it in a production environment!**

## Strategy
In phase one, the plan is to focus on the client APIs along with support for the following features

### Transport
- [ ] WebSocket

### Interaction Model
- [ ] Request/Response

In the following phases, the plan is to implement the server APIs along with support for 

- All interaction models. 
- Leasing and flow control.


## Dependencies

- SwiftNIO - Async IO library on iOS
- Combine - Reactive-streams implementation
- Swift-concurrency - Concurrency support in Swift
