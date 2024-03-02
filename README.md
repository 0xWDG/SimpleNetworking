# Simple networking

This class is meant for simple network tasks.

## Requirements

- Swift 5.9+ (Xcode 15+)
- iOS 13+, macOS 10.15+

## Installation

Install using Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/0xWDG/SimpleNetworking.git", .branch("main")),
],
targets: [
    .target(name: "MyTarget", dependencies: [
        .product(name: "SimpleNetworking", package: "SimpleNetworking"),
    ]),
]
```

And import it:
```swift
import SimpleNetworking
```

## Usage

### Declare networking variable (preferred)
```swift
import SimpleNetworking

let networking = SimpleNetworking.shared
```
We use `networking` as the variable name, but you can use any name you like.
Please note in the examples below we use `networking` as the variable name.
If you use a different name, please replace `networking` with your variable name.
Or use `SimpleNetworking.shared` instead of `networking`.

### Setup (optional)
```swift
networking.set(serverURL: "https://wesleydegroot.nl")
```

### Set user-agent (optional)
```swift
networking.set(userAgent: "STRING")
```

### Set authentication (optional)
```swift
networking.set(authorization: "STRING")
```

### Set post type (optional)
```swift
networking.set(postType: .json) // .plain, .json, .graphQL
```

### GET data Async/Await
```swift
Task {
    let response = await networking.request(
        path: "/", 
        method: .get
    )

    print(response.string)
}
```

### POST data Async/Await
```swift
Task {
    let response = await networking.request(
        path: "/", 
        method: .post(
            [
                "postfield1": "poststring1",
                "postfield2": "poststring2"
            ]
        )
    )

    print(response.string)
}
```

### GET data (closure based)
```swift
networking.request(
    path: "/", 
    method: .get
) { networkResponse in
    print(networkResponse)
}
```

### POST data (closure based)
```swift
networking.request(
    path: "/",
    method: .post(
        [
            "postfield1": "poststring1",
            "postfield2": "poststring2"
        ]
    )
) { networkResponse in
    print(networkResponse)
}
```

### Bonus 1: JSON Decoding
#### Codable, decoding strategy = useDefaultKeys
```swift
struct MyCodable: Codable {
    let value1: String
    let value2: String
}

// Decode the response
let data: MyCodable? = networkResponse.decoded()
```

#### Codable, decoding strategy = convertFromSnakeCase
```swift
struct MyCodable: Codable {
    let snakeCase: String
    let caseSnake: String
}

// Decode the response
let data: MyCodable? = networkResponse.decoded(.convertFromSnakeCase)
```

### Bonus: Websocket
```swift
import SimpleNetworking

networking.connect(to: "https://api.github.com/users/0xWDG") { data in
    print(data)
}
```

### Add HTTP Cookie
```swift
let cookie = HTTPCookie.init(properties: [
    .name: "my cookie",
    .value: "my value",
    .domain: "wesleydegroot.nl"
    .path: "/"
])

networking.add(cookie: "cookie")
```

### Mocking
SimpleNetworking can be mocked (since version 1.0.3), so you can test your code without actually making a network request.

```swift

networking.set(mockData: [
    "https://wesleydegroot.nl": .init(
        data: "OVERRIDE", // Can be Data or String
        response: .init( // NSURLResponse, Can be nil
            url: .init(stringLiteral: "https://wesleydegroot.nl"), 
            mimeType: "text/html", 
            expectedContentLength: 8, 
            textEncodingName: "utf-8"
        ),
        statusCode: 200, // Int: If omitted, 200 is used
        error: nil
    )
])
```
### Debugging
```swift

/// Debug: NSURLRequest
networking.debug.requestURL = false
/// Debug: sent HTTP Headers
networking.debug.requestHeaders = false
/// Debug: sent Cookies
networking.debug.requestCookies = false
/// Debug: sent Body
networking.debug.requestBody = false
/// Debug: received HTTP Headers
networking.debug.responseHeaders = false
/// Debug: received Body
networking.debug.responseBody = false
/// Debug: received JSON (if any)
networking.debug.responseJSON = false
```

## Contact

We can get in touch via [Twitter/X](https://twitter.com/0xWDG), [Discord](https://discordapp.com/users/918438083861573692), [Mastodon](https://iosdev.space/@0xWDG), [Threads](https://threads.net/@0xwdg), [Bluesky](https://bsky.app/profile/0xwdg.bsky.social).

Alternatively you can visit my [Website](https://wesleydegroot.nl).
