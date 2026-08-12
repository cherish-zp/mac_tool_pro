import XCTest
import CoreGraphics

/// TDD: 阴影边框 - 在截图最外边缘绘制深色边线，不改变图片尺寸。
/// 阴影透明度控制边线颜色深浅（默认 16%）。
final class ShadowBorderTests: XCTestCase {

    func test_outputSize_equalsInputSize_noExpansion() {
        let size = CGSize(width: 100, height: 80)
        let out = ShadowBorder.outputSize(imageSize: size)
        XCTAssertEqual(out.width, 100, accuracy: 0.001)
        XCTAssertEqual(out.height, 80, accuracy: 0.001)
    }

    func test_borderColor_hasCorrectAlpha() {
        let color = ShadowBorder.borderColor(opacity: 0.16)
        XCTAssertEqual(color.alpha, 0.16, accuracy: 0.001)
    }

    func test_borderColor_clampsTo01() {
        XCTAssertEqual(ShadowBorder.borderColor(opacity: -0.5).alpha, 0, accuracy: 0.001)
        XCTAssertEqual(ShadowBorder.borderColor(opacity: 1.5).alpha, 1, accuracy: 0.001)
    }

    func test_borderWidth_isPositive() {
        XCTAssertGreaterThan(ShadowBorder.borderWidth, 0)
    }

    func test_borderRect_isInsetByHalfWidth() {
        let size = CGSize(width: 100, height: 80)
        let rect = ShadowBorder.borderRect(imageSize: size)
        let half = ShadowBorder.borderWidth / 2
        XCTAssertEqual(rect.origin.x, half, accuracy: 0.001)
        XCTAssertEqual(rect.origin.y, half, accuracy: 0.001)
        XCTAssertEqual(rect.width, 100 - ShadowBorder.borderWidth, accuracy: 0.001)
        XCTAssertEqual(rect.height, 80 - ShadowBorder.borderWidth, accuracy: 0.001)
    }
}
