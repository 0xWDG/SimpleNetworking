//
//  FileUpload.swift
//  Simple Networking
//
//  Created by Wesley de Groot on 28/01/2026.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/SimpleNetworking
//  MIT LICENCE
//

import Foundation

extension SimpleNetworking {
    /// Represents multipart upload data (files and form parameters)
    public struct MultipartUploadData {
        /// Files to upload
        public let files: [FileUpload]

        /// Additional form parameters
        public let parameters: [String: String]

        /// Initialize multipart upload data
        /// - Parameters:
        ///   - files: Files to upload
        ///   - parameters: Additional form parameters (default is empty)
        public init(files: [FileUpload], parameters: [String: String] = [:]) {
            self.files = files
            self.parameters = parameters
        }

        /// Initialize multipart upload data with a single file
        /// - Parameters:
        ///   - file: File to upload
        ///   - parameters: Additional form parameters (default is empty)
        public init(file: FileUpload, parameters: [String: String] = [:]) {
            self.files = [file]
            self.parameters = parameters
        }
    }

    /// Represents a file to be uploaded
    public struct FileUpload {
        /// The file data
        public let data: Data

        /// The form field name
        public let name: String

        /// The filename to be sent to the server
        public let filename: String

        /// The MIME type of the file
        public let mimeType: String

        /// Initialize a file upload
        /// - Parameters:
        ///   - data: The file data
        ///   - name: The form field name
        ///   - filename: The filename to be sent to the server
        ///   - mimeType: The MIME type of the file (defaults to "application/octet-stream")
        public init(data: Data, name: String, filename: String, mimeType: String = "application/octet-stream") {
            self.data = data
            self.name = name
            self.filename = filename
            self.mimeType = mimeType
        }

        /// Initialize a file upload from a file URL
        /// - Parameters:
        ///   - fileURL: The URL of the file to upload
        ///   - name: The form field name
        ///   - filename: Optional filename (uses the file's name if not specified)
        ///   - mimeType: Optional MIME type (auto-detected if not specified)
        /// - Throws: FileUploadError if file cannot be read
        public init(fileURL: URL, name: String, filename: String? = nil, mimeType: String? = nil) throws {
            guard fileURL.isFileURL else {
                throw FileUploadError.invalidFileURL
            }

            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                throw FileUploadError.fileNotFound(path: fileURL.path)
            }

            do {
                let fileData = try Data(contentsOf: fileURL)
                let detectedFilename = filename ?? fileURL.lastPathComponent
                let detectedMimeType = mimeType ?? Self.mimeType(for: fileURL)

                self.init(data: fileData, name: name, filename: detectedFilename, mimeType: detectedMimeType)
            } catch {
                throw FileUploadError.cannotReadFile(path: fileURL.path, error: error)
            }
        }

        /// Detect MIME type based on file extension
        /// - Parameter url: The file URL
        /// - Returns: The detected MIME type
        private static func mimeType(for url: URL) -> String {
            let ext = url.pathExtension.lowercased()

            let mimeTypes: [String: String] = [
                "jpg": "image/jpeg",
                "jpeg": "image/jpeg",
                "png": "image/png",
                "gif": "image/gif",
                "bmp": "image/bmp",
                "webp": "image/webp",
                "svg": "image/svg+xml",
                "pdf": "application/pdf",
                "doc": "application/msword",
                "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                "xls": "application/vnd.ms-excel",
                "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                "ppt": "application/vnd.ms-powerpoint",
                "pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
                "txt": "text/plain",
                "html": "text/html",
                "css": "text/css",
                "js": "application/javascript",
                "json": "application/json",
                "xml": "application/xml",
                "zip": "application/zip",
                "tar": "application/x-tar",
                "gz": "application/gzip",
                "mp3": "audio/mpeg",
                "mp4": "video/mp4",
                "avi": "video/x-msvideo",
                "mov": "video/quicktime",
                "wav": "audio/wav"
            ]

            return mimeTypes[ext] ?? "application/octet-stream"
        }
    }

    /// Errors related to file uploads
    public enum FileUploadError: Error, LocalizedError {
        case invalidFileURL
        case fileNotFound(path: String)
        case cannotReadFile(path: String, error: Error)

        public var errorDescription: String? {
            switch self {
            case .invalidFileURL:
                return "The provided URL is not a file URL"
            case .fileNotFound(let path):
                return "File not found at path: \(path)"
            case .cannotReadFile(let path, let error):
                return "Cannot read file at path: \(path). Error: \(error.localizedDescription)"
            }
        }
    }
}
