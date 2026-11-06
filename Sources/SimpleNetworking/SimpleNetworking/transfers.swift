//
//  transfers.swift
//  Simple Networking
//
//  Created by Wesley de Groot on 25/09/2026.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/SimpleNetworking
//  MIT LICENCE

import Foundation

#if canImport(FoundationNetworking)
@preconcurrency import FoundationNetworking
#endif

extension SimpleNetworking {
    /// Download a resource to a local file, reporting byte progress as it arrives.
    public func download(
        path: String,
        to destinationURL: URL,
        onProgress: @escaping @Sendable (TransferProgress) -> Void = { _ in }
    ) async -> NetworkResponse {
        guard let url = isURL(path) else {
            return .init(
                error: NetworkingError(message: "Error: Download endpoint doesn't appear to be an URL"),
                request: .init(url: defaultURL)
            )
        }

        var request = createRequest(url: url)
        request.httpMethod = "GET"
        addStoredCookies(to: &request)

        if let mock = requestSettings().mocks[url.absoluteString] {
            do {
                try mock.data?.write(to: destinationURL, options: .atomic)
                let byteCount = Int64(mock.data?.count ?? 0)
                onProgress(.init(completedUnitCount: byteCount, totalUnitCount: byteCount))
                return response(from: mock.data, response: mock.response, error: mock.error, request: request)
            } catch {
                return .init(error: error, request: request)
            }
        }

        let delegate = TransferDelegate(progressHandler: onProgress, destinationURL: destinationURL)
        let configuration = requestSettings().session?.configuration ?? .ephemeral
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        var response = await delegate.download(session: session, request: request)
        saveCookies(from: response.response)
        response.cookies = cookieSnapshot()
        return response
    }

    /// Start a download and expose its progress as an `AsyncStream`.
    public func download(path: String, to destinationURL: URL) -> Transfer {
        makeTransfer { progress in
            await self.download(path: path, to: destinationURL, onProgress: progress)
        }
    }

    /// Resume a previously interrupted download using resume data returned by `URLSession`.
    public func download(
        resuming resumeData: Data,
        to destinationURL: URL,
        onProgress: @escaping @Sendable (TransferProgress) -> Void = { _ in }
    ) async -> NetworkResponse {
        let delegate = TransferDelegate(progressHandler: onProgress, destinationURL: destinationURL)
        let configuration = requestSettings().session?.configuration ?? .ephemeral
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        var response = await delegate.download(session: session, resumeData: resumeData)
        saveCookies(from: response.response)
        response.cookies = cookieSnapshot()
        return response
    }

    /// Upload multipart data while reporting byte progress.
    public func upload(
        path: String,
        uploadData: MultipartUploadData,
        onProgress: @escaping @Sendable (TransferProgress) -> Void
    ) async -> NetworkResponse {
        guard let request = createUploadRequest(path: path, uploadData: uploadData) else {
            return .init(
                error: NetworkingError(message: "Error: Upload endpoint doesn't appear to be an URL"),
                request: .init(url: defaultURL)
            )
        }

        var preparedRequest = request
        addStoredCookies(to: &preparedRequest)

        if let url = preparedRequest.url,
           let mock = requestSettings().mocks[url.absoluteString] {
            let bytes = Int64(preparedRequest.httpBody?.count ?? 0)
            onProgress(.init(completedUnitCount: bytes, totalUnitCount: bytes))
            return response(from: mock.data, response: mock.response, error: mock.error, request: preparedRequest)
        }

        let delegate = TransferDelegate(progressHandler: onProgress)
        let configuration = requestSettings().session?.configuration ?? .ephemeral
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        var response = await delegate.upload(session: session, request: preparedRequest)
        saveCookies(from: response.response)
        response.cookies = cookieSnapshot()
        return response
    }

    /// Start an upload and expose its progress as an `AsyncStream`.
    public func uploadTransfer(path: String, uploadData: MultipartUploadData) -> Transfer {
        makeTransfer { progress in
            await self.upload(path: path, uploadData: uploadData, onProgress: progress)
        }
    }

    private func makeTransfer(
        _ operation: @escaping @Sendable (@escaping @Sendable (TransferProgress) -> Void) async -> NetworkResponse
    ) -> Transfer {
        let channel = TransferProgressChannel()
        let response = Task { @Sendable in
            defer { channel.finish() }
            return await operation { progress in channel.yield(progress) }
        }
        return .init(progress: channel.stream, response: response)
    }

    internal func response(
        from data: Data?,
        response: URLResponse?,
        error: Error?,
        request: URLRequest
    ) -> NetworkResponse {
        let statusCode = (response as? HTTPURLResponse)?.statusCode
        var networkResponse = NetworkResponse(
            response: response,
            statuscode: statusCode,
            error: error,
            data: data,
            string: data.flatMap { String(data: $0, encoding: .utf8) },
            dictionary: data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] },
            cookies: cookieSnapshot(),
            request: request
        )
        networkResponse.normalizeError()
        return networkResponse
    }
}

private final class TransferProgressChannel: @unchecked Sendable {
    let stream: AsyncStream<SimpleNetworking.TransferProgress>
    private let continuation: AsyncStream<SimpleNetworking.TransferProgress>.Continuation

    init() {
        let pair = AsyncStream<SimpleNetworking.TransferProgress>.makeStream()
        stream = pair.stream
        continuation = pair.continuation
    }

    func yield(_ progress: SimpleNetworking.TransferProgress) {
        continuation.yield(progress)
    }

    func finish() {
        continuation.finish()
    }
}

final class TransferDelegate: NSObject, URLSessionDownloadDelegate, URLSessionDataDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private let progressHandler: @Sendable (SimpleNetworking.TransferProgress) -> Void
    private let destinationURL: URL?
    private var downloadContinuation: CheckedContinuation<SimpleNetworking.NetworkResponse, Never>?
    private var uploadContinuation: CheckedContinuation<SimpleNetworking.NetworkResponse, Never>?
    private var downloadedResponse: SimpleNetworking.NetworkResponse?
    private var uploadData: Data?

    init(
        progressHandler: @escaping @Sendable (SimpleNetworking.TransferProgress) -> Void,
        destinationURL: URL? = nil
    ) {
        self.progressHandler = progressHandler
        self.destinationURL = destinationURL
    }

    func download(session: URLSession, request: URLRequest) async -> SimpleNetworking.NetworkResponse {
        let task = session.downloadTask(with: request)
        return await download(task: task)
    }

    func download(session: URLSession, resumeData: Data) async -> SimpleNetworking.NetworkResponse {
        let task = session.downloadTask(withResumeData: resumeData)
        return await download(task: task)
    }

    private func download(task: URLSessionDownloadTask) async -> SimpleNetworking.NetworkResponse {
        return await withTaskCancellationHandler(operation: {
            await withCheckedContinuation { continuation in
                lock.lock()
                downloadContinuation = continuation
                lock.unlock()
                task.resume()
            }
        }, onCancel: {
            task.cancel()
        })
    }

    func upload(session: URLSession, request: URLRequest) async -> SimpleNetworking.NetworkResponse {
        let task = session.uploadTask(with: request, from: request.httpBody ?? Data())
        return await upload(task: task)
    }

    func upload(session: URLSession, request: URLRequest, bodyFile: URL) async -> SimpleNetworking.NetworkResponse {
        let task = session.uploadTask(with: request, fromFile: bodyFile)
        return await upload(task: task)
    }

    private func upload(task: URLSessionUploadTask) async -> SimpleNetworking.NetworkResponse {
        return await withTaskCancellationHandler(operation: {
            await withCheckedContinuation { continuation in
                lock.lock()
                uploadContinuation = continuation
                lock.unlock()
                task.resume()
            }
        }, onCancel: {
            task.cancel()
        })
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        progressHandler(.init(completedUnitCount: totalBytesWritten, totalUnitCount: totalBytesExpectedToWrite))
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        progressHandler(.init(completedUnitCount: totalBytesSent, totalUnitCount: totalBytesExpectedToSend))
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            guard let destinationURL else { throw CocoaError(.fileNoSuchFile) }
            try FileManager.default.createDirectory(
                at: destinationURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: location, to: destinationURL)
            downloadedResponse = .init(
                response: downloadTask.response,
                statuscode: (downloadTask.response as? HTTPURLResponse)?.statusCode,
                error: nil,
                data: nil,
                string: nil,
                dictionary: nil,
                cookies: nil,
                request: downloadTask.originalRequest ?? .init(url: downloadTask.currentRequest?.url ?? location)
            )
        } catch {
            downloadedResponse = .init(error: error, request: downloadTask.originalRequest ?? .init(url: location))
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        lock.lock()
        uploadData = (uploadData ?? Data()) + data
        lock.unlock()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        lock.lock()
        defer { lock.unlock() }

        if let continuation = downloadContinuation {
            downloadContinuation = nil
            continuation.resume(returning: downloadedResponse ?? .init(
                error: error,
                request: task.originalRequest ?? .init(url: URL(fileURLWithPath: "/"))
            ))
        }

        if let continuation = uploadContinuation {
            uploadContinuation = nil
            let data = uploadData
            continuation.resume(returning: .init(
                response: task.response,
                statuscode: (task.response as? HTTPURLResponse)?.statusCode,
                error: error,
                data: data,
                string: data.flatMap { String(data: $0, encoding: .utf8) },
                dictionary: data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] },
                cookies: nil,
                request: task.originalRequest ?? .init(url: URL(fileURLWithPath: "/"))
            ))
        }
        session.finishTasksAndInvalidate()
    }
}
