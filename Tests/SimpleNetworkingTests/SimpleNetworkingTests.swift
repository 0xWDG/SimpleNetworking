@testable import SimpleNetworking
import XCTest

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

    func testPutRequestFillsHTTPBodyWithRawData() async {
        let body = Data(#"{"name":"Updated"}"#.utf8)
        networking.set(mockData: [
            "https://wesleydegroot.nl/api/update": .init(
                data: "{}",
                response: nil,
                statusCode: 200,
                error: nil
            )
        ])

        let response = await networking.request(
            path: "/api/update",
            method: .put(body)
        )

        XCTAssertEqual(response.request.httpMethod, "PUT")
        XCTAssertEqual(response.request.httpBody, body)
        XCTAssertEqual(response.request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func testPutRequestFillsHTTPBodyWithJSONDictionary() async throws {
        networking.set(mockData: [
            "https://wesleydegroot.nl/api/update": .init(
                data: "{}",
                response: nil,
                statusCode: 200,
                error: nil
            )
        ])

        let response = await networking.request(
            path: "/api/update",
            method: .put(["id": "123", "name": "Updated"])
        )

        let body = try XCTUnwrap(response.request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: String])
        XCTAssertEqual(json, ["id": "123", "name": "Updated"])
    }

    func testConfigurationInitializesAnIsolatedClient() async {
        let networking = SimpleNetworking(configuration: .init(
            serverURL: "https://example.com",
            userAgent: "SimpleNetworkingTests",
            authorization: "test-token",
            headers: [.init(name: "X-Client", value: "isolated")]
        ))
        networking.set(mockData: [
            "https://example.com/health": .init(data: "ok", response: nil, error: nil)
        ])

        let response = await networking.request(path: "/health", method: .get)

        XCTAssertEqual(response.request.value(forHTTPHeaderField: "User-Agent"), "SimpleNetworkingTests")
        XCTAssertEqual(response.request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
        XCTAssertEqual(response.request.value(forHTTPHeaderField: "X-Client"), "isolated")
        XCTAssertEqual(response.string, "ok")
    }

    func testRequestBuilderAppliesRequestScopedSettings() async {
        let networking = SimpleNetworking(configuration: .init(
            serverURL: "https://example.com",
            headers: [.init(name: "X-Client", value: "default")]
        ))
        networking.set(mockData: [
            "https://example.com/users?page=2": .init(data: "[]", response: nil, error: nil)
        ])
        let request = SimpleNetworking.Request(
            path: "/users",
            method: .get,
            query: ["page": "2"],
            headers: [.init(name: "X-Client", value: "request")],
            timeout: 12,
            cachePolicy: .reloadIgnoringLocalCacheData
        )

        let response = await networking.execute(request)

        XCTAssertEqual(response.request.url?.absoluteString, "https://example.com/users?page=2")
        XCTAssertEqual(response.request.value(forHTTPHeaderField: "X-Client"), "request")
        XCTAssertEqual(response.request.timeoutInterval, 12)
        XCTAssertEqual(response.request.cachePolicy, .reloadIgnoringLocalCacheData)
    }

    func testRequestBuilderSupportsCustomMethodsAndRawBodies() async {
        let networking = SimpleNetworking(configuration: .init(serverURL: "https://example.com"))
        networking.set(mockData: [
            "https://example.com/documents": .init(data: "", response: nil, error: nil)
        ])
        let body = Data("payload".utf8)
        let request = SimpleNetworking.Request(
            path: "/documents",
            method: "PROPFIND",
            body: body,
            headers: [.init(name: "Content-Type", value: "text/plain")]
        )

        let response = await networking.execute(request)

        XCTAssertEqual(response.request.httpMethod, "PROPFIND")
        XCTAssertEqual(response.request.httpBody, body)
        XCTAssertEqual(response.request.value(forHTTPHeaderField: "Content-Type"), "text/plain")
    }

    func testMockedDownloadWritesTheDestinationAndReportsProgress() async throws {
        let networking = SimpleNetworking(configuration: .init(serverURL: "https://example.com"))
        networking.set(mockData: [
            "https://example.com/archive": .init(data: "downloaded", response: nil, error: nil)
        ])
        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let recorder = ProgressRecorder()

        defer { try? FileManager.default.removeItem(at: destinationURL) }
        let response = await networking.download(path: "/archive", to: destinationURL) { progress in
            Task { await recorder.append(progress) }
        }

        XCTAssertNil(response.error)
        XCTAssertEqual(try String(contentsOf: destinationURL), "downloaded")
        let updates = await recorder.values()
        XCTAssertEqual(updates.last?.fractionCompleted, 1)
    }

    func testFileBackedUploadKeepsTheRequestBodyOutOfMemory() async throws {
        let sourceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".txt")
        try Data("large file contents".utf8).write(to: sourceURL)
        defer { try? FileManager.default.removeItem(at: sourceURL) }

        let networking = SimpleNetworking(configuration: .init(serverURL: "https://example.com"))
        networking.set(mockData: [
            "https://example.com/upload": .init(data: "ok", response: nil, error: nil)
        ])
        let file = try SimpleNetworking.FileBackedMultipartUploadData.File(
            fileURL: sourceURL,
            name: "document"
        )
        let upload = SimpleNetworking.FileBackedMultipartUploadData(
            file: file,
            parameters: ["description": "A document"]
        )
        let recorder = ProgressRecorder()

        let response = await networking.upload(path: "/upload", fileUploadData: upload) { progress in
            Task { await recorder.append(progress) }
        }

        XCTAssertEqual(response.string, "ok")
        XCTAssertNil(response.request.httpBody)
        let contentType = response.request.value(forHTTPHeaderField: "Content-Type")
        XCTAssertEqual(contentType?.hasPrefix("multipart/form-data"), true)
        let progress = await recorder.values().last
        XCTAssertEqual(progress?.fractionCompleted, 1)
    }

    func testUploadTransferPublishesProgress() async {
        let networking = SimpleNetworking(configuration: .init(serverURL: "https://example.com"))
        networking.set(mockData: [
            "https://example.com/upload": .init(data: "ok", response: nil, error: nil)
        ])
        let uploadData = SimpleNetworking.MultipartUploadData(
            file: .init(data: Data("contents".utf8), name: "file", filename: "file.txt")
        )

        let transfer = networking.uploadTransfer(path: "/upload", uploadData: uploadData)
        var updates: [SimpleNetworking.TransferProgress] = []
        for await progress in transfer.progress {
            updates.append(progress)
        }
        let response = await transfer.response.value

        XCTAssertEqual(response.string, "ok")
        XCTAssertEqual(updates.last?.fractionCompleted, 1)
    }

    func testHTTPFailureContainsDiagnostics() async {
        let networking = SimpleNetworking(configuration: .init(serverURL: "https://example.com"))
        let url = URL(string: "https://example.com/missing")!
        networking.set(mockData: [
            url.absoluteString: .init(
                data: "not found",
                response: HTTPURLResponse(
                    url: url,
                    statusCode: 404,
                    httpVersion: nil,
                    headerFields: ["X-Request-ID": "abc"]
                ),
                statusCode: 404,
                error: nil
            )
        ])

        let response = await networking.request(path: "/missing", method: .get)

        XCTAssertFalse(response.isSuccess)
        XCTAssertEqual(response.networkingError?.kind, .httpStatus)
        XCTAssertEqual(response.networkingError?.statusCode, 404)
        XCTAssertEqual(response.networkingError?.bodySnippet, "not found")
        XCTAssertEqual(response.networkingError?.responseHeaders.first?.name, "X-Request-ID")
    }

    func testThrowingDecodeReportsDiagnostics() async {
        struct Model: Decodable { let id: Int }

        let networking = SimpleNetworking(configuration: .init(serverURL: "https://example.com"))
        networking.set(mockData: [
            "https://example.com/invalid-json": .init(data: "not json", response: nil, error: nil)
        ])
        let response = await networking.request(path: "/invalid-json", method: .get)

        XCTAssertThrowsError(try response.decode(Model.self)) { error in
            let networkingError = error as? SimpleNetworking.NetworkingError
            XCTAssertEqual(networkingError?.kind, .decoding)
            XCTAssertEqual(networkingError?.bodySnippet, "not json")
        }
        XCTAssertNil(response.decoded() as Model?)
    }

}

private actor ProgressRecorder {
    private var storage: [SimpleNetworking.TransferProgress] = []

    func append(_ progress: SimpleNetworking.TransferProgress) {
        storage.append(progress)
    }

    func values() -> [SimpleNetworking.TransferProgress] {
        storage
    }
}
