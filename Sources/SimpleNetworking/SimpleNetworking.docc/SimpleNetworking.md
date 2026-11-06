# ``SimpleNetworking``

Make HTTP requests, transfers, and realtime connections with a compact Swift API.

## Overview

SimpleNetworking is a Foundation-based HTTP client for applications and services that need a small, explicit networking layer. It provides traditional GET, POST, PUT, PATCH, and DELETE requests; multipart uploads; file downloads; cookies; response decoding; mocks; Server-Sent Events; and WebSockets.

The library is designed around `async`/`await`. The closure-based request and upload APIs remain available for existing code, but are deprecated in favor of structured concurrency.

### Create a client

Use ``SimpleNetworking/shared`` for simple or legacy call sites:

```swift
let networking = SimpleNetworking.shared
networking.set(serverURL: "https://api.example.com")
```

For new code, prefer an isolated client configured once at creation time. ``SimpleNetworking/Configuration`` is immutable, and the client takes an atomic settings snapshot before each request.

```swift
let networking = SimpleNetworking(configuration: .init(
    serverURL: "https://api.example.com",
    authorization: "access-token",
    headers: [.init(name: "X-App-Version", value: "1.0")]
))
```

> Important: An authorization value is sent as a Bearer token. Supply the token only, without the `Bearer ` prefix.

## Making requests

Use ``SimpleNetworking/request(path:method:encoding:file:line:function:)`` for concise calls. Paths beginning with `/` are resolved against the configured server URL; absolute URLs can be used directly.

```swift
let response = await networking.request(path: "/users", method: .get)

guard response.isSuccess else {
    print(response.networkingError?.localizedDescription ?? "Request failed")
    return
}
```

Request bodies are encoded according to ``SimpleNetworking/POSTEncoding``. JSON is the default. A `Data` value is used as-is; dictionaries and `Encodable` values can be encoded as JSON; `.plain` uses form encoding; and `.graphQL` wraps a query string in a JSON object.

```swift
let response = await networking.request(
    path: "/users",
    method: .post(["display_name": "Taylor"])
)
```

### Per-request settings

Use ``SimpleNetworking/Request`` when one call needs query items, headers, a timeout, cache behavior, or a custom HTTP method. Per-request headers replace matching headers from the client configuration, without changing that configuration.

```swift
let request = SimpleNetworking.Request(
    path: "/users",
    method: .get,
    query: ["page": "2"],
    headers: [.init(name: "X-Request-ID", value: UUID().uuidString)],
    timeout: 15,
    cachePolicy: .reloadIgnoringLocalCacheData
)

let response = await networking.execute(request)
```

For methods not represented by ``SimpleNetworking/HTTPMethod``, pass an uppercase method name and a raw body.

```swift
let request = SimpleNetworking.Request(
    path: "/documents",
    method: "PROPFIND",
    body: Data()
)
let response = await networking.execute(request)
```

## Handling responses and errors

Every operation returns ``SimpleNetworking/NetworkResponse``. It preserves the original `URLRequest`, the `URLResponse`, status code, response headers, data, text representation, parsed JSON dictionary when possible, and received cookies.

``SimpleNetworking/NetworkResponse/isSuccess`` is true only for a 2xx status without a transport error. Non-2xx results are represented by ``SimpleNetworking/NetworkingError`` with a status code, headers, and an error-body snippet (limited to 4 KB).

```swift
let response = await networking.request(path: "/profile", method: .get)

if let error = response.networkingError {
    print(error.kind)            // for example, .httpStatus
    print(error.statusCode ?? 0)
    print(error.bodySnippet ?? "")
}
```

Decode a successful response with the throwing ``SimpleNetworking/NetworkResponse/decode(_:strategy:)`` API. The older ``SimpleNetworking/NetworkResponse/decoded(strategy:file:line:function:)`` convenience returns `nil` on failure and logs diagnostic information.

```swift
struct User: Decodable {
    let id: String
    let displayName: String
}

do {
    let response = await networking.request(path: "/me", method: .get)
    let user: User = try response.decode(strategy: .convertFromSnakeCase)
    print(user.displayName)
} catch let error as SimpleNetworking.NetworkingError {
    print(error.localizedDescription)
}
```

## Uploading and downloading files

Use ``SimpleNetworking/upload(path:uploadData:file:line:function:)`` with ``SimpleNetworking/MultipartUploadData`` for small in-memory uploads.

```swift
let file = SimpleNetworking.FileUpload(
    data: Data("Hello".utf8),
    name: "document",
    filename: "hello.txt",
    mimeType: "text/plain"
)
let upload = SimpleNetworking.MultipartUploadData(file: file)
let response = await networking.upload(path: "/upload", uploadData: upload)
```

For large files, use ``SimpleNetworking/FileBackedMultipartUploadData``. The source is copied in 64 KB chunks to a temporary multipart file, and the upload task reads that file directly rather than retaining the file content in the request body.

```swift
let file = try SimpleNetworking.FileBackedMultipartUploadData.File(
    fileURL: videoURL,
    name: "video"
)
let upload = SimpleNetworking.FileBackedMultipartUploadData(file: file)

let response = await networking.upload(path: "/upload", fileUploadData: upload) { progress in
    print(progress.fractionCompleted ?? 0)
}
```

Download a resource directly to disk with ``SimpleNetworking/download(path:to:onProgress:)``. It does not retain the downloaded body in the returned response.

```swift
let response = await networking.download(path: "/archive.zip", to: destinationURL) { progress in
    print(progress.completedUnitCount)
}
```

Use ``SimpleNetworking/Transfer`` when progress should be consumed as an `AsyncStream`.

```swift
let transfer = networking.uploadTransfer(path: "/upload", uploadData: upload)
for await progress in transfer.progress {
    print(progress.fractionCompleted ?? 0)
}
let response = await transfer.response.value
```

## Cookies and testing

The client keeps its own cookie collection. Add a cookie with ``SimpleNetworking/add(cookie:)`` or ``SimpleNetworking/cookie(domain:path:name:value:)``; cookies received in an HTTP response are saved automatically.

Use ``SimpleNetworking/set(mockData:)`` to provide deterministic responses in tests. Mock keys are absolute URLs.

```swift
networking.set(mockData: [
    "https://api.example.com/health": .init(
        data: "{\"ok\":true}",
        response: nil,
        statusCode: 200,
        error: nil
    )
])
```

## Realtime connections

``SimpleNetworking/eventSource(path:onOpen:onMessage:onError:)`` opens a Server-Sent Events connection and forwards received data chunks. Call ``SimpleNetworking/eventSourceDisconnect()`` when it is no longer needed.

``SimpleNetworking/connect(to:responder:)`` establishes a WebSocket connection. Use ``SimpleNetworking/send(message:)`` to send `String` or `Data` payloads.

## Topics

### Essentials

- ``SimpleNetworking``
- ``SimpleNetworking/Configuration``
- ``SimpleNetworking/Request``
- ``SimpleNetworking/HTTPMethod``
- ``SimpleNetworking/HTTPHeader``

### Responses and errors

- ``SimpleNetworking/NetworkResponse``
- ``SimpleNetworking/NetworkingError``
- ``SimpleNetworking/POSTEncoding``

### Transfers

- ``SimpleNetworking/MultipartUploadData``
- ``SimpleNetworking/FileBackedMultipartUploadData``
- ``SimpleNetworking/FileUpload``
- ``SimpleNetworking/Transfer``
- ``SimpleNetworking/TransferProgress``

### Testing and realtime

- ``SNMock``
