import XCTest
import CoreGraphics

/// TDD: 滚动截图拼接器 - 检测两帧之间的垂直重叠并拼接。
final class ScrollStitcherTests: XCTestCase {

    func test_findOverlap_stripedImages() {
        // A: 上半红、下半蓝；B: 上半蓝、下半绿 -> 重叠=蓝部分=50行
        let a = makeStripedImage(stripeColors: [.red, .blue], totalHeight: 100)
        let b = makeStripedImage(stripeColors: [.blue, .green], totalHeight: 100)
        let overlap = ScrollStitcher.findOverlap(top: a, bottom: b)
        XCTAssertEqual(overlap, 50)
    }

    func test_findOverlap_noOverlap() {
        // A: 全红；B: 全蓝 -> 无重叠
        let a = makeStripedImage(stripeColors: [.red], totalHeight: 60)
        let b = makeStripedImage(stripeColors: [.blue], totalHeight: 60)
        let overlap = ScrollStitcher.findOverlap(top: a, bottom: b)
        XCTAssertEqual(overlap, 0)
    }

    func test_findOverlap_identicalImages() {
        let a = makeStripedImage(stripeColors: [.red, .blue], totalHeight: 80)
        let overlap = ScrollStitcher.findOverlap(top: a, bottom: a)
        XCTAssertEqual(overlap, 80)
    }

    func test_stitch_twoImages() {
        let a = makeStripedImage(stripeColors: [.red, .blue], totalHeight: 100)
        let b = makeStripedImage(stripeColors: [.blue, .green], totalHeight: 100)
        let stitched = ScrollStitcher.stitch(images: [a, b])
        // 100 + 100 - 50(重叠) = 150
        XCTAssertEqual(stitched!.height, 150)
    }

    func test_stitch_threeImages() {
        let a = makeStripedImage(stripeColors: [.red, .blue], totalHeight: 100)
        let b = makeStripedImage(stripeColors: [.blue, .green], totalHeight: 100)
        let c = makeStripedImage(stripeColors: [.green, .yellow], totalHeight: 100)
        let stitched = ScrollStitcher.stitch(images: [a, b, c])
        // 100 + (100-50) + (100-50) = 200
        XCTAssertEqual(stitched!.height, 200)
    }

    func test_stitch_singleImage_returnsSame() {
        let a = makeStripedImage(stripeColors: [.red], totalHeight: 50)
        let stitched = ScrollStitcher.stitch(images: [a])
        XCTAssertEqual(stitched!.height, 50)
    }

    func test_stitch_emptyReturnsNil() {
        XCTAssertNil(ScrollStitcher.stitch(images: []))
    }

    // MARK: - Helpers

    /// 创建水平条纹图片（CGContext 原点在左下，条纹按从下到上排列）。
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
}
