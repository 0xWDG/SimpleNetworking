import XCTest
@testable import SimpleNetworking

final class PropertyWrapperTests: XCTestCase {
    // swiftlint:disable:previous type_body_length
    let networking = SimpleNetworking.shared

    override func setUp() async throws {
        networking.set(serverURL: "https://wesleydegroot.nl")
        networking.set(encoding: .json)
    }

    // MARK: - @Get Tests

    func testGetPropertyWrapper() async {
        let getWrapper = SimpleNetworking.Get("/sitemap.xml")
        let response = await getWrapper.execute()

        XCTAssertNotNil(response)
        XCTAssert(response.string?.contains("schemas/sitemap") ?? false)
    }

    func testGetPropertyWrapperWithMock() async {
        networking.set(mockData: [
            "https://wesleydegroot.nl/test": .init(
                data: "GET RESPONSE",
                response: .init(
                    url: .init(string: "https://wesleydegroot.nl/test")!, // swiftlint:disable:this force_unwrapping
                    mimeType: "text/html",
                    expectedContentLength: 12,
                    textEncodingName: "utf-8"
                ),
                statusCode: 200,
                error: nil
            )
        ])

        let getWrapper = SimpleNetworking.Get("/test")
        let response = await getWrapper.execute()

        XCTAssertEqual(response.string, "GET RESPONSE")
        XCTAssertEqual(response.statuscode, 200)
    }

    // MARK: - @Post Tests

    func testPostPropertyWrapper() async {
        networking.set(mockData: [
            "https://wesleydegroot.nl/api/post": .init(
                data: "{\"status\":\"success\"}",
                response: .init(
                    url: .init(string: "https://wesleydegroot.nl/api/post")!, // swiftlint:disable:this force_unwrapping
                    mimeType: "application/json",
                    expectedContentLength: 20,
                    textEncodingName: "utf-8"
                ),
                statusCode: 200,
                error: nil
            )
        ])

        let postWrapper = SimpleNetworking.Post("/api/post")
        let response = await postWrapper.execute(["key": "value"])

        XCTAssertNotNil(response)
        XCTAssertEqual(response.statuscode, 200)
        XCTAssert(response.string?.contains("success") ?? false)
    }

    func testPostPropertyWrapperWithoutData() async {
        networking.set(mockData: [
            "https://wesleydegroot.nl/api/post": .init(
                data: "{\"status\":\"created\"}",
                response: .init(
                    url: .init(string: "https://wesleydegroot.nl/api/post")!, // swiftlint:disable:this force_unwrapping
                    mimeType: "application/json",
                    expectedContentLength: 20,
                    textEncodingName: "utf-8"
                ),
                statusCode: 200,
                error: nil
            )
        ])

        let postWrapper = SimpleNetworking.Post("/api/post")
        let response = await postWrapper.execute()

        XCTAssertNotNil(response)
        XCTAssertEqual(response.statuscode, 200)
    }

    // MARK: - @Put Tests

    func testPutPropertyWrapper() async {
        networking.set(mockData: [
            "https://wesleydegroot.nl/api/update": .init(
                data: "{\"status\":\"updated\"}",
                response: .init(
                    url: .init(string: "https://wesleydegroot.nl/api/update")!,
                    // swiftlint:disable:previous force_unwrapping
                    mimeType: "application/json",
                    expectedContentLength: 21,
                    textEncodingName: "utf-8"
                ),
                statusCode: 200,
                error: nil
            )
        ])

        let putWrapper = SimpleNetworking.Put("/api/update")
        let response = await putWrapper.execute(["id": "123", "name": "Updated"])

        XCTAssertNotNil(response)
        XCTAssertEqual(response.statuscode, 200)
        XCTAssert(response.string?.contains("updated") ?? false)
    }

    // MARK: - @Delete Tests

    func testDeletePropertyWrapper() async {
        networking.set(mockData: [
            "https://wesleydegroot.nl/api/delete": .init(
                data: "{\"status\":\"deleted\"}",
                response: .init(
                    url: .init(string: "https://wesleydegroot.nl/api/delete")!,
                    // swiftlint:disable:previous force_unwrapping
                    mimeType: "application/json",
                    expectedContentLength: 21,
                    textEncodingName: "utf-8"
                ),
                statusCode: 200,
                error: nil
            )
        ])

        let deleteWrapper = SimpleNetworking.Delete("/api/delete")
        let response = await deleteWrapper.execute(["id": "123"])

        XCTAssertNotNil(response)
        XCTAssertEqual(response.statuscode, 200)
        XCTAssert(response.string?.contains("deleted") ?? false)
    }

    // MARK: - @Upload Tests

    func testUploadPropertyWrapper() async {
        networking.set(mockData: [
            "https://wesleydegroot.nl/api/upload": .init(
                data: "{\"status\":\"uploaded\",\"file_id\":\"abc123\"}",
                response: .init(
                    url: .init(string: "https://wesleydegroot.nl/api/upload")!,
                    // swiftlint:disable:previous force_unwrapping
                    mimeType: "application/json",
                    expectedContentLength: 45,
                    textEncodingName: "utf-8"
                ),
                statusCode: 200,
                error: nil
            )
        ])

        let fileUpload = SimpleNetworking.FileUpload(
            data: Data("Test file content".utf8),
            name: "file",
            filename: "test.txt",
            mimeType: "text/plain"
        )

        let uploadData = SimpleNetworking.MultipartUploadData(
            file: fileUpload,
            parameters: ["user_id": "456"]
        )

        let uploadWrapper = SimpleNetworking.Upload("/api/upload")
        let response = await uploadWrapper.execute(uploadData)

        XCTAssertNotNil(response)
        XCTAssertEqual(response.statuscode, 200)
        XCTAssert(response.string?.contains("uploaded") ?? false)
    }

    // MARK: - @SimpleNetworkingWrapper Tests

    func testSimpleNetworkingWrapperGet() async {
        networking.set(mockData: [
            "https://wesleydegroot.nl/wrapper/test": .init(
                data: "WRAPPER GET",
                response: .init(
                    url: .init(string: "https://wesleydegroot.nl/wrapper/test")!,
                    // swiftlint:disable:previous force_unwrapping
                    mimeType: "text/html",
                    expectedContentLength: 11,
                    textEncodingName: "utf-8"
                ),
                statusCode: 200,
                error: nil
            )
        ])

        let wrapper = SimpleNetworking.SimpleNetworkingWrapper(.get, "/wrapper/test")
        let response = await wrapper.execute()

        XCTAssertNotNil(response)
        XCTAssertEqual(response.string, "WRAPPER GET")
        XCTAssertEqual(response.statuscode, 200)
    }

    func testSimpleNetworkingWrapperPost() async {
        networking.set(mockData: [
            "https://wesleydegroot.nl/wrapper/post": .init(
                data: "{\"status\":\"wrapper_post\"}",
                response: .init(
                    url: .init(string: "https://wesleydegroot.nl/wrapper/post")!,
                    // swiftlint:disable:previous force_unwrapping
                    mimeType: "application/json",
                    expectedContentLength: 27,
                    textEncodingName: "utf-8"
                ),
                statusCode: 200,
                error: nil
            )
        ])

        let wrapper = SimpleNetworking.SimpleNetworkingWrapper(.post(nil), "/wrapper/post")
        let response = await wrapper.execute(["key": "value"])

        XCTAssertNotNil(response)
        XCTAssertEqual(response.statuscode, 200)
        XCTAssert(response.string?.contains("wrapper_post") ?? false)
    }

    func testSimpleNetworkingWrapperPut() async {
        networking.set(mockData: [
            "https://wesleydegroot.nl/wrapper/put": .init(
                data: "{\"status\":\"wrapper_put\"}",
                response: .init(
                    url: .init(string: "https://wesleydegroot.nl/wrapper/put")!,
                    // swiftlint:disable:previous force_unwrapping
                    mimeType: "application/json",
                    expectedContentLength: 26,
                    textEncodingName: "utf-8"
                ),
                statusCode: 200,
                error: nil
            )
        ])

        let wrapper = SimpleNetworking.SimpleNetworkingWrapper(.put(nil), "/wrapper/put")
        let response = await wrapper.execute(["id": "123"])

        XCTAssertNotNil(response)
        XCTAssertEqual(response.statuscode, 200)
        XCTAssert(response.string?.contains("wrapper_put") ?? false)
    }

    func testSimpleNetworkingWrapperDelete() async {
        networking.set(mockData: [
            "https://wesleydegroot.nl/wrapper/delete": .init(
                data: "{\"status\":\"wrapper_delete\"}",
                response: .init(
                    url: .init(string: "https://wesleydegroot.nl/wrapper/delete")!,
                    // swiftlint:disable:previous force_unwrapping
                    mimeType: "application/json",
                    expectedContentLength: 30,
                    textEncodingName: "utf-8"
                ),
                statusCode: 200,
                error: nil
            )
        ])

        let wrapper = SimpleNetworking.SimpleNetworkingWrapper(.delete(nil), "/wrapper/delete")
        let response = await wrapper.execute(["id": "123"])

        XCTAssertNotNil(response)
        XCTAssertEqual(response.statuscode, 200)
        XCTAssert(response.string?.contains("wrapper_delete") ?? false)
    }

    // MARK: - Property Wrapper Metadata Tests

    func testPropertyWrapperPath() {
        let getWrapper = SimpleNetworking.Get("/test/path")

        XCTAssertEqual(getWrapper.path, "/test/path")
    }

    func testPropertyWrapperNetworkingInstance() {
        let postWrapper = SimpleNetworking.Post("/test/post")

        XCTAssertNotNil(postWrapper.networking)
    }

    // MARK: - Actual Property Wrapper Syntax Tests (@)

    func testGetPropertyWrapperWithAtSyntaxInClass() async {
        class TestService {
            @SimpleNetworking.Get("/sitemap.xml")
            var sitemap: SimpleNetworking.NetworkResponse?
        }

        let service = TestService()
        let response = await service.$sitemap.execute()

        XCTAssertNotNil(response)
        XCTAssert(response.string?.contains("schemas/sitemap") ?? false)
    }

    func testPostPropertyWrapperWithAtSyntaxInClass() async {
        networking.set(mockData: [
            "https://wesleydegroot.nl/api/create": .init(
                data: "{\"id\":\"123\",\"status\":\"created\"}",
                response: .init(
                    url: .init(string: "https://wesleydegroot.nl/api/create")!,
                    // swiftlint:disable:previous force_unwrapping
                    mimeType: "application/json",
                    expectedContentLength: 30,
                    textEncodingName: "utf-8"
                ),
                statusCode: 200,
                error: nil
            )
        ])

        class TestService {
            @SimpleNetworking.Post("/api/create")
            var createItem: SimpleNetworking.NetworkResponse?
        }

        let service = TestService()
        let response = await service.$createItem.execute(["name": "Test Item"])

        XCTAssertNotNil(response)
        XCTAssertEqual(response.statuscode, 200)
        XCTAssert(response.string?.contains("created") ?? false)
    }

    func testPropertyWrapperWithAtSyntaxInStruct() async {
        networking.set(mockData: [
            "https://wesleydegroot.nl/api/data": .init(
                data: "{\"data\":\"value\"}",
                response: .init(
                    url: .init(string: "https://wesleydegroot.nl/api/data")!, // swiftlint:disable:this force_unwrapping
                    mimeType: "application/json",
                    expectedContentLength: 17,
                    textEncodingName: "utf-8"
                ),
                statusCode: 200,
                error: nil
            )
        ])

        struct TestService {
            @SimpleNetworking.Get("/api/data")
            var data: SimpleNetworking.NetworkResponse?

            mutating func fetchData() async -> SimpleNetworking.NetworkResponse {
                return await $data.execute()
            }
        }

        var service = TestService()
        let response = await service.fetchData()

        XCTAssertNotNil(response)
        XCTAssertEqual(response.statuscode, 200)
        XCTAssert(response.string?.contains("value") ?? false)
    }

    func testMultiplePropertyWrappersInSameClass() async {
        networking.set(mockData: [
            "https://wesleydegroot.nl/api/users": .init(
                data: "[{\"id\":\"1\",\"name\":\"User 1\"}]",
                response: .init(
                    url: .init(string: "https://wesleydegroot.nl/api/users")!,
                    // swiftlint:disable:previous force_unwrapping
                    mimeType: "application/json",
                    expectedContentLength: 32,
                    textEncodingName: "utf-8"
                ),
                statusCode: 200,
                error: nil
            ),
            "https://wesleydegroot.nl/api/posts": .init(
                data: "[{\"id\":\"1\",\"title\":\"Post 1\"}]",
                response: .init(
                    url: .init(string: "https://wesleydegroot.nl/api/posts")!,
                    // swiftlint:disable:previous force_unwrapping
                    mimeType: "application/json",
                    expectedContentLength: 33,
                    textEncodingName: "utf-8"
                ),
                statusCode: 200,
                error: nil
            )
        ])

        class APIService {
            @SimpleNetworking.Get("/api/users")
            var users: SimpleNetworking.NetworkResponse?

            @SimpleNetworking.Get("/api/posts")
            var posts: SimpleNetworking.NetworkResponse?
        }

        let api = APIService()
        let usersResponse = await api.$users.execute()
        let postsResponse = await api.$posts.execute()

        XCTAssertNotNil(usersResponse)
        XCTAssertNotNil(postsResponse)
        XCTAssert(usersResponse.string?.contains("User 1") ?? false)
        XCTAssert(postsResponse.string?.contains("Post 1") ?? false)
    }
}
// swiftlint:disable:this file_length
