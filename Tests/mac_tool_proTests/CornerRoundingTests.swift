import XCTest
import CoreGraphics

/// TDD: 截图选区圆角半径管理：预设、循环切换、夹取上限。
final class CornerRoundingTests: XCTestCase {

    func test_nextRadius_cyclesForward() {
        XCTAssertEqual(CornerRounding.nextRadius(0), 8)
        XCTAssertEqual(CornerRounding.nextRadius(8), 16)
        XCTAssertEqual(CornerRounding.nextRadius(16), 24)
        XCTAssertEqual(CornerRounding.nextRadius(24), 32)
    }

    func test_nextRadius_wrapsAroundToZero() {
        XCTAssertEqual(CornerRounding.nextRadius(32), 0)
    }

    func test_nextRadius_unknownValue_returnsZero() {
        XCTAssertEqual(CornerRounding.nextRadius(10), 0)
    }

    func test_clampedRadius_withinBounds() {
        let r = CornerRounding.clampedRadius(16, for: CGSize(width: 200, height: 100))
        XCTAssertEqual(r, 16, accuracy: 0.001)
    }

    func test_clampedRadius_exceedsHalfMinDimension() {
        let r = CornerRounding.clampedRadius(100, for: CGSize(width: 200, height: 100))
        XCTAssertEqual(r, 50, accuracy: 0.001)
    }

    func test_clampedRadius_negativeClampsToZero() {
        let r = CornerRounding.clampedRadius(-5, for: CGSize(width: 200, height: 100))
        XCTAssertEqual(r, 0, accuracy: 0.001)
    }

    func test_isEnabled_zeroIsFalse() {
        XCTAssertFalse(CornerRounding.isEnabled(0))
    }

   func test_isEnabled_positiveIsTrue() {
       XCTAssertTrue(CornerRounding.isEnabled(8))
       XCTAssertTrue(CornerRounding.isEnabled(16))
   }

    func test_defaultRadius_isPositive() {
        XCTAssertTrue(CornerRounding.defaultRadius > 0)
    }

    func test_defaultRadius_isInPresets() {
        XCTAssertTrue(CornerRounding.presets.contains(CornerRounding.defaultRadius))
    }
}
