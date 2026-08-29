import XCTest
import CoreGraphics

/// TDD: SystemPasteboard 应支持注入私有 NSPasteboard，并提供 copyImage(CGImage)，
/// 行为与 ScreenshotCoordinator.copyToClipboard 一致（clearContents + writeObjects）。
final class PasteboardImageTests: XCTestCase {

    /// 每个用例用独立命名的私有剪贴板，互不污染 NSPasteboard.general。
    private func makePrivatePasteboard() -> NSPasteboard {
        NSPasteboard(name: NSPasteboard.Name("test-\(UUID().uuidString)"))
    }

    /// 构造纯色 CGImage（无 DPI 元数据，读回时 1pt = 1px）。
    private func makeImage(width: Int, height: Int) -> CGImage {
        let ctx = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        ctx.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return ctx.makeImage()!
    }

    // MARK: - copyImage

    func test_copyImage_readBackNSImageMatchesOriginalSize() {
        let privatePb = makePrivatePasteboard()
        let pasteboard = SystemPasteboard(pasteboard: privatePb)
        let image = makeImage(width: 123, height: 45)

        pasteboard.copyImage(image)

        let readBack = privatePb.readObjects(forClasses: [NSImage.self]) as? [NSImage]
        XCTAssertEqual(readBack?.count, 1)
        let size = readBack?.first?.size
        XCTAssertEqual(size?.width ?? -1, 123, accuracy: 0.5)
        XCTAssertEqual(size?.height ?? -1, 45, accuracy: 0.5)
    }

    func test_copyImage_clearsPreviousContents() {
        let privatePb = makePrivatePasteboard()
        let pasteboard = SystemPasteboard(pasteboard: privatePb)
        privatePb.setString("stale", forType: .string)

        pasteboard.copyImage(makeImage(width: 10, height: 10))

        XCTAssertNil(privatePb.string(forType: .string))
        XCTAssertEqual((privatePb.readObjects(forClasses: [NSImage.self]) as? [NSImage])?.count, 1)
    }

    // MARK: - copy(string:) 回归

    func test_copyString_writesStringToInjectedPasteboard() {
        let privatePb = makePrivatePasteboard()
        let pasteboard = SystemPasteboard(pasteboard: privatePb)

        pasteboard.copy("/Users/zp/a.txt")

        XCTAssertEqual(privatePb.string(forType: .string), "/Users/zp/a.txt")
    }
}
