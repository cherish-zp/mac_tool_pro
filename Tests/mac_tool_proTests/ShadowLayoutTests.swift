import XCTest
import CoreGraphics

/// TDD: 阴影布局 - 计算紧凑的阴影输出尺寸和绘制位置。
/// 用户反馈：输出图片透明边距过大，应仅保留截图+阴影。
final class ShadowLayoutTests: XCTestCase {

    func test_padding_isTighterThanFullBlur() {
        let blur: CGFloat = 20
        let offset = CGSize(width: 0, height: -4)
        let pad = ShadowLayout.padding(blur: blur, offset: offset)
        // 标准 padding = blur + maxOffset + 1 = 25
        // 紧凑 padding 应明显小于标准
        XCTAssertLessThan(pad, blur + max(abs(offset.width), abs(offset.height)) + 1)
        // 但仍需足够容纳大部分阴影
        XCTAssertGreaterThanOrEqual(pad, blur * 0.5)
    }

    func test_outputSize_includesPadding() {
        let imageSize = CGSize(width: 100, height: 80)
        let blur: CGFloat = 20
        let offset = CGSize(width: 0, height: -4)
        let size = ShadowLayout.outputSize(imageSize: imageSize, blur: blur, offset: offset)
        let pad = ShadowLayout.padding(blur: blur, offset: offset)
        XCTAssertEqual(size.width, 100 + pad * 2, accuracy: 0.001)
        XCTAssertEqual(size.height, 80 + pad * 2, accuracy: 0.001)
    }

    func test_drawRect_centeredImage() {
        let imageSize = CGSize(width: 100, height: 80)
        let blur: CGFloat = 15
        let offset = CGSize(width: 0, height: 0)
        let rect = ShadowLayout.drawImageRect(imageSize: imageSize, blur: blur, offset: offset)
        let pad = ShadowLayout.padding(blur: blur, offset: offset)
        XCTAssertEqual(rect.origin.x, pad, accuracy: 0.001)
        XCTAssertEqual(rect.origin.y, pad, accuracy: 0.001)
        XCTAssertEqual(rect.width, 100, accuracy: 0.001)
        XCTAssertEqual(rect.height, 80, accuracy: 0.001)
    }

    func test_zeroBlurZeroOffset_minimalPadding() {
        let pad = ShadowLayout.padding(blur: 0, offset: .zero)
        XCTAssertEqual(pad, 0, accuracy: 0.001)
    }
}
