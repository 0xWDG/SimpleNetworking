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

    // MARK: - File Upload Tests

    func testFileUploadInitialization() {
        // Test basic file upload initialization
        let testData = Data("Test file content".utf8)
        let fileUpload = SimpleNetworking.FileUpload(
            data: testData,
            name: "file",
            filename: "test.txt",
            mimeType: "text/plain"
        )

        XCTAssertEqual(fileUpload.name, "file")
        XCTAssertEqual(fileUpload.filename, "test.txt")
        XCTAssertEqual(fileUpload.mimeType, "text/plain")
        XCTAssertEqual(fileUpload.data, testData)
    }

    func testFileUploadFromFileURL() throws {
        // Create a temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test.txt")
        let testContent = "Hello, World!"
        try testContent.write(to: fileURL, atomically: true, encoding: .utf8)

        defer {
            try? FileManager.default.removeItem(at: fileURL)
        }

        // Test file upload from URL
        let fileUpload = try SimpleNetworking.FileUpload(
            fileURL: fileURL,
            name: "document"
        )

        XCTAssertEqual(fileUpload.name, "document")
        XCTAssertEqual(fileUpload.filename, "test.txt")
        XCTAssertEqual(fileUpload.mimeType, "text/plain")
        XCTAssertEqual(String(data: fileUpload.data, encoding: .utf8), testContent)
    }

    func testFileUploadMimeTypeDetection() throws {
        // Test various file extensions and their MIME types
        let tempDir = FileManager.default.temporaryDirectory

        let testCases: [(String, String)] = [
            ("test.jpg", "image/jpeg"),
            ("test.png", "image/png"),
            ("test.pdf", "application/pdf"),
            ("test.json", "application/json"),
            ("test.zip", "application/zip")
        ]

        var createdFiles: [URL] = []

        for (filename, expectedMimeType) in testCases {
            let fileURL = tempDir.appendingPathComponent(filename)
            try "test".write(to: fileURL, atomically: true, encoding: .utf8)
            createdFiles.append(fileURL)

            let fileUpload = try SimpleNetworking.FileUpload(
                fileURL: fileURL,
                name: "file"
            )

            XCTAssertEqual(fileUpload.mimeType, expectedMimeType, "MIME type for \(filename)")
        }

        // Clean up all created files
        for fileURL in createdFiles {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    func testMultipartUploadDataWithSingleFile() {
        let testData = Data("Test content".utf8)
        let fileUpload = SimpleNetworking.FileUpload(
            data: testData,
            name: "file",
            filename: "test.txt"
        )

        let uploadData = SimpleNetworking.MultipartUploadData(
            file: fileUpload,
            parameters: ["key": "value"]
        )

        XCTAssertEqual(uploadData.files.count, 1)
        XCTAssertEqual(uploadData.parameters["key"], "value")
    }

    func testMultipartUploadDataWithMultipleFiles() {
        let file1 = SimpleNetworking.FileUpload(
            data: Data("Content 1".utf8),
            name: "file1",
            filename: "test1.txt"
        )

        let file2 = SimpleNetworking.FileUpload(
            data: Data("Content 2".utf8),
            name: "file2",
            filename: "test2.txt"
        )

        let uploadData = SimpleNetworking.MultipartUploadData(
            files: [file1, file2],
            parameters: ["param1": "value1", "param2": "value2"]
        )

        XCTAssertEqual(uploadData.files.count, 2)
        XCTAssertEqual(uploadData.parameters.count, 2)
    }

    func testFileUploadWithMockedResponse() async {
        // Setup mock response
        networking.set(mockData: [
            "https://example.com/upload": .init(
                data: "{\"status\":\"success\",\"file_id\":\"123\"}",
                response: .init(
                    url: .init(string: "https://example.com/upload")!,
                    // swiftlint:disable:previous force_unwrapping
                    mimeType: "application/json",
                    expectedContentLength: 100,
                    textEncodingName: "utf-8"
                ),
                statusCode: 200,
                error: nil
            )
        ])

        // Create file upload
        let fileUpload = SimpleNetworking.FileUpload(
            data: Data("Test file".utf8),
            name: "file",
            filename: "test.txt",
            mimeType: "text/plain"
        )

        let uploadData = SimpleNetworking.MultipartUploadData(
            file: fileUpload,
            parameters: ["user_id": "456"]
        )

        // Perform upload
        let response = await networking.upload(
            path: "https://example.com/upload",
            uploadData: uploadData
        )

        XCTAssertEqual(response.statuscode, 200)
        XCTAssertNotNil(response.string)
        XCTAssert(response.string?.contains("success") ?? false)
    }

    func testBoundaryGeneration() {
        let boundary1 = networking.generateBoundary()
        let boundary2 = networking.generateBoundary()

        XCTAssertTrue(boundary1.hasPrefix("Boundary-"))
        XCTAssertTrue(boundary2.hasPrefix("Boundary-"))
        XCTAssertNotEqual(boundary1, boundary2, "Boundaries should be unique")
    }

    func testFileUploadError_FileNotFound() {
        let nonExistentURL = URL(fileURLWithPath: "/tmp/nonexistent_file.txt")

        XCTAssertThrowsError(try SimpleNetworking.FileUpload(
            fileURL: nonExistentURL,
            name: "file"
        )) { error in
            if let uploadError = error as? SimpleNetworking.FileUploadError {
                switch uploadError {
                case .fileNotFound:
                    XCTAssertTrue(true, "Correct error thrown")
                default:
                    XCTFail("Wrong error type")
                }
            } else {
                XCTFail("Wrong error type")
            }
        }
    }

    func testFileUploadError_InvalidURL() {
        let httpURL = URL(string: "https://example.com/file.txt")!
        // swiftlint:disable:previous force_unwrapping

        XCTAssertThrowsError(try SimpleNetworking.FileUpload(
            fileURL: httpURL,
            name: "file"
        )) { error in
            if let uploadError = error as? SimpleNetworking.FileUploadError {
                switch uploadError {
                case .invalidFileURL:
                    XCTAssertTrue(true, "Correct error thrown")
                default:
                    XCTFail("Wrong error type")
                }
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
}
