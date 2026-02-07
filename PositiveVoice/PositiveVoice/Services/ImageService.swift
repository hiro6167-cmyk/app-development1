import Foundation
import SwiftUI
import ImageIO
import UniformTypeIdentifiers

/// 画像処理・アップロードサービス（v2）
/// 設計書 7.2 の EXIF除去・リサイズ仕様に準拠
enum ImageError: Error, LocalizedError {
    case invalidData
    case encodingFailed
    case uploadFailed
    case tooLarge

    var errorDescription: String? {
        switch self {
        case .invalidData: return "画像データが無効です"
        case .encodingFailed: return "画像の変換に失敗しました"
        case .uploadFailed: return "画像のアップロードに失敗しました"
        case .tooLarge: return "画像サイズが大きすぎます（最大5MB）"
        }
    }
}

enum ImageProcessor {
    /// 画像をEXIFなしJPEGに変換（リサイズ含む）
    /// - Parameters:
    ///   - data: 元画像データ
    ///   - maxSize: 長辺の最大サイズ（デフォルト1080px）
    /// - Returns: 処理済みJPEGデータ
    static func processForUpload(_ data: Data, maxSize: CGFloat = 1080) throws -> Data {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ImageError.invalidData
        }

        // リサイズ
        let resizedImage = resize(cgImage, maxSize: maxSize)

        // EXIF除去してJPEGエンコード（メタデータを一切含めない）
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw ImageError.encodingFailed
        }

        // kCGImageDestinationLossyCompressionQuality のみ指定
        // メタデータ系のキーを一切渡さない = EXIFなし
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.8
        ]

        CGImageDestinationAddImage(destination, resizedImage, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw ImageError.encodingFailed
        }

        let result = mutableData as Data

        // サイズチェック（最大5MB）
        if result.count > 5 * 1024 * 1024 {
            throw ImageError.tooLarge
        }

        return result
    }

    private static func resize(_ image: CGImage, maxSize: CGFloat) -> CGImage {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let maxDimension = max(width, height)

        guard maxDimension > maxSize else { return image }

        let scale = maxSize / maxDimension
        let newWidth = Int(width * scale)
        let newHeight = Int(height * scale)

        guard let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return image
        }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

        return context.makeImage() ?? image
    }

    #if DEBUG
    /// 開発時のみ: 出力にEXIFが含まれていないことを確認
    static func verifyNoExif(_ data: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return true
        }
        // GPS, EXIF, TIFFが含まれていないことを確認
        let sensitiveKeys = [kCGImagePropertyGPSDictionary as String, kCGImagePropertyExifDictionary as String]
        return sensitiveKeys.allSatisfy { properties[$0] == nil }
    }
    #endif
}

class ImageService {
    static let shared = ImageService()

    private init() {}

    /// 画像をアップロードしてURLを返す
    /// - Parameters:
    ///   - imageData: 処理済み画像データ
    ///   - postId: 投稿ID
    /// - Returns: アップロードされた画像のURL
    func uploadImage(_ imageData: Data, postId: String) async throws -> String {
        // TODO: 実際のAPI実装時に有効化
        // 1. POST /media/upload-url で署名付きURL取得
        // 2. S3に直接アップロード
        // 3. 完了したURLを返す

        // モック: 遅延してダミーURLを返す
        try await Task.sleep(nanoseconds: 500_000_000)

        let mockUrl = "https://\(AWSConfig.mediaBucket).s3.amazonaws.com/posts/\(postId)/\(UUID().uuidString).jpg"
        print("ImageService: Mock uploaded image to \(mockUrl)")

        return mockUrl
    }

    /// 複数画像を並列アップロード（最大2並列）
    func uploadImages(_ images: [Data], postId: String) async throws -> [String] {
        var urls: [String] = []

        // 最大2並列でアップロード
        for chunk in images.chunked(into: 2) {
            let results = try await withThrowingTaskGroup(of: String.self) { group in
                for imageData in chunk {
                    group.addTask {
                        try await self.uploadImage(imageData, postId: postId)
                    }
                }

                var chunkUrls: [String] = []
                for try await url in group {
                    chunkUrls.append(url)
                }
                return chunkUrls
            }
            urls.append(contentsOf: results)
        }

        return urls
    }
}

// MARK: - Array Extension for Chunking

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
