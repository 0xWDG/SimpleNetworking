import Foundation
import XCTest
@testable import SimpleNetworking

final class CookieTests: XCTestCase {
    private var networking: SimpleNetworking!

    override func setUp() {
        super.setUp()

        networking = SimpleNetworking()
        networking.set(serverURL: "https://example.com")
        networking.cookie(reset: true)
    }

    func testStoredCookieIsSentAsRequestHeader() async {
        XCTAssertTrue(networking.cookie(domain: "example.com", path: "/", name: "session", value: "abc123"))

        networking.set(mockData: [
            "https://example.com/profile": .init(
                data: "{}",
                response: nil,
                statusCode: 200,
                error: nil
            )
        ])

        let response = await networking.request(path: "/profile", method: .get)

        XCTAssertEqual(response.request.value(forHTTPHeaderField: "Cookie"), "session=abc123")
    }

    func testResponseCookiesAreSaved() {
        guard let url = URL(string: "https://example.com/profile"),
              let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Set-Cookie": "session=updated; Path=/"]
              ) else {
            XCTFail("Unable to create HTTPURLResponse")
            return
        }

        networking.saveCookies(from: response)

        XCTAssertEqual(networking.cookieSnapshot().first?.name, "session")
        XCTAssertEqual(networking.cookieSnapshot().first?.value, "updated")
    }
}
