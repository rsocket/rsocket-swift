import XCTest
@testable import RSocket

final class RSocketTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(RSocket().text, "Hello, World!")
    }
}
