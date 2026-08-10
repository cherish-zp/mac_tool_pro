import XCTest
import CoreGraphics

/// TDD: 滚动截图拼接器 - 检测向下滚动时相邻帧的重叠并拼接。
final class ScrollStitcherTests: XCTestCase {

    /// 向下滚动：A 底部=蓝、B 顶部=蓝 -> 重叠=50（精确匹配）
    func test_findOverlap_scrollDown() {
        let a = makeStripedImage(stripeColors: [.blue, .red], totalHeight: 100)
        let b = makeStripedImage(stripeColors: [.green, .blue], totalHeight: 100)
        XCTAssertEqual(ScrollStitcher.findOverlap(top: a, bottom: b), 50)
    }

    func test_findOverlap_noOverlap() {
        let a = makeStripedImage(stripeColors: [.red], totalHeight: 60)
        let b = makeStripedImage(stripeColors: [.blue], totalHeight: 60)
        XCTAssertEqual(ScrollStitcher.findOverlap(top: a, bottom: b), 0)
    }

    func test_findOverlap_identicalImages() {
        let a = makeStripedImage(stripeColors: [.blue, .red], totalHeight: 80)
        XCTAssertEqual(ScrollStitcher.findOverlap(top: a, bottom: a), 80)
    }

    func test_stitch_twoImages() {
        let a = makeStripedImage(stripeColors: [.blue, .red], totalHeight: 100)
        let b = makeStripedImage(stripeColors: [.green, .blue], totalHeight: 100)
        XCTAssertEqual(ScrollStitcher.stitch(images: [a, b])!.height, 150)
    }

    func test_stitch_threeImages() {
        let a = makeStripedImage(stripeColors: [.blue, .red], totalHeight: 100)
        let b = makeStripedImage(stripeColors: [.green, .blue], totalHeight: 100)
        let c = makeStripedImage(stripeColors: [.yellow, .green], totalHeight: 100)
        XCTAssertEqual(ScrollStitcher.stitch(images: [a, b, c])!.height, 200)
    }

    func test_stitch_singleImage_returnsSame() {
        let a = makeStripedImage(stripeColors: [.red], totalHeight: 50)
        XCTAssertEqual(ScrollStitcher.stitch(images: [a])!.height, 50)
    }

    func test_stitch_emptyReturnsNil() {
        XCTAssertNil(ScrollStitcher.stitch(images: []))
    }

    // MARK: - 容差：轻微像素偏差（容错匹配，允许 ±5 行误差）

    func test_findOverlap_withSlightNoise_detectsOverlap() {
        let a = makeStripedImage(stripeColors: [.blue, .red], totalHeight: 100)
        let b = makeStripedImage(stripeColors: [.green, NSColor(srgbRed: 0, green: 0, blue: 245/255, alpha: 1)], totalHeight: 100)
        XCTAssertEqual(ScrollStitcher.findOverlap(top: a, bottom: b), 50, accuracy: 5)
    }

    func test_stitch_withSlightNoise_noDuplicateContent() {
        let a = makeStripedImage(stripeColors: [.blue, .red], totalHeight: 100)
        let b = makeStripedImage(stripeColors: [.green, NSColor(srgbRed: 0, green: 0, blue: 245/255, alpha: 1)], totalHeight: 100)
        XCTAssertEqual(ScrollStitcher.stitch(images: [a, b])!.height, 150, accuracy: 10)
    }

    // MARK: - 容差：单行差异（光标/滚动条，容错匹配）

    func test_findOverlap_withOneMismatchedRow_stillDetects() {
        let a = makeStripedImage(stripeColors: [.blue, .red], totalHeight: 100)
        let b = makeStripedImageWithBadRow(stripeColors: [.green, .blue], totalHeight: 100, badRow: 10, badColor: .green)
        XCTAssertEqual(ScrollStitcher.findOverlap(top: a, bottom: b), 50, accuracy: 5)
    }

    func test_stitch_withMinorDifferences_noDuplicateContent() {
        let a = makeStripedImage(stripeColors: [.blue, .red], totalHeight: 100)
        let b = makeStripedImageWithBadRow(stripeColors: [.green, .blue], totalHeight: 100, badRow: 10, badColor: .green)
        XCTAssertEqual(ScrollStitcher.stitch(images: [a, b])!.height, 150, accuracy: 10)
    }

    // MARK: - Helpers

    private func makeStripedImage(stripeColors: [NSColor], totalHeight: Int, width: Int = 100) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let ctx = CGContext(data: nil, width: width, height: totalHeight,
                            bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let stripeHeight = totalHeight / stripeColors.count
        for (i, color) in stripeColors.enumerated() {
            ctx.setFillColor(color.cgColor)
            ctx.fill(CGRect(x: 0, y: i * stripeHeight, width: width, height: stripeHeight))
        }
        return ctx.makeImage()!
    }

    private func makeStripedImageWithBadRow(stripeColors: [NSColor], totalHeight: Int, badRow: Int, badColor: NSColor, width: Int = 100) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let ctx = CGContext(data: nil, width: width, height: totalHeight,
                            bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let stripeHeight = totalHeight / stripeColors.count
        for (i, color) in stripeColors.enumerated() {
            ctx.setFillColor(color.cgColor)
            ctx.fill(CGRect(x: 0, y: i * stripeHeight, width: width, height: stripeHeight))
        }
        ctx.setFillColor(badColor.cgColor)
        ctx.fill(CGRect(x: 0, y: totalHeight - 1 - badRow, width: width, height: 1))
        return ctx.makeImage()!
    }
}
