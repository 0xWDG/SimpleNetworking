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

### Declare networking variable
```swift
import SimpleNetworking

let networking = SimpleNetworking.shared
```

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
import SimpleNetworking

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
import SimpleNetworking

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
import SimpleNetworking

networking.request(
    path: "/", 
    method: .get
) { networkResponse in
    print(networkResponse)
}
```

### POST data (closure based)
```swift
import SimpleNetworking

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

SimpleNetworking.shared.connect(to: "https://api.github.com/users/0xWDG") { data in
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

SimpleNetworking.shared.add(cookie: "cookie")
```

### Debugging
```swift

/// Debug: NSURLRequest
SimpleNetworking.shared.debug.requestURL = false
/// Debug: sent HTTP Headers
SimpleNetworking.shared.debug.requestHeaders = false
/// Debug: sent Cookies
SimpleNetworking.shared.debug.requestCookies = false
/// Debug: sent Body
SimpleNetworking.shared.debug.requestBody = false
/// Debug: received HTTP Headers
SimpleNetworking.shared.debug.responseHeaders = false
/// Debug: received Body
SimpleNetworking.shared.debug.responseBody = false
/// Debug: received JSON (if any)
SimpleNetworking.shared.debug.responseJSON = false
```

## Contact

We can get in touch via [Twitter/X](https://twitter.com/0xWDG), [Discord](https://discordapp.com/users/918438083861573692), [Mastodon](https://iosdev.space/@0xWDG), [Threads](http://threads.net/@0xwdg), [Bluesky](https://bsky.app/profile/0xwdg.bsky.social).

Alternatively you can visit my [Website](https://wesleydegroot.nl).
