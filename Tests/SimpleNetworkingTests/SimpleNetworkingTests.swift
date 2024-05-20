import XCTest
@testable import SimpleNetworking

final class SimpleNetworkingTests: XCTestCase {
    let networking = SimpleNetworking.shared

    func testSetup() {
        networking.set(serverURL: "https://wesleydegroot.nl")
        networking.set(encoding: .json) // .plain, .json, .graphQL
    }

    func testSimpleHTTPCall() async {
         let response = await networking.request(
            path: "/sitemap.xml",
            method: .get
        )

        XCTAssert(response.string?.contains("schemas/sitemap") ?? false)
    }

    func testSimpleMockedHTTPCall() async {
        networking.set(mockData: [
            "https://wesleydegroot.nl/": .init(
                data: "OVERRIDE",
                response: .init(
                    url: .init(string: "https://wesleydegroot.nl/")!, // swiftlint:disable:this force_unwrapping
                    mimeType: "text/html",
                    expectedContentLength: 8,
                    textEncodingName: "utf-8"
                ),
                statusCode: 200, // Int: If omitted, 200 is used
                error: nil
            )
        ])

        let response = await networking.request(
            path: "/",
            method: .get
        )

        XCTAssert(response.string?.contains("OVERRIDE") ?? false)
    }
}
