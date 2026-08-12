import XCTest
import CoreGraphics

/// TDD: 画布设置 - 圆角 + 阴影（开关、透明度、模糊、偏移）。
final class CanvasSettingsTests: XCTestCase {

    func test_defaultValues() {
        let s = CanvasSettings.default
        XCTAssertEqual(s.cornerRadius, 16, accuracy: 0.001)
        XCTAssertTrue(s.shadowEnabled)
        XCTAssertEqual(s.shadowOpacity, 0.16, accuracy: 0.001)
        XCTAssertGreaterThan(s.shadowBlur, 0)
    }

    func test_toggleShadow() {
        let s = CanvasSettings.default
        XCTAssertTrue(s.shadowEnabled)
        XCTAssertFalse(s.toggledShadow().shadowEnabled)
        XCTAssertTrue(s.toggledShadow().toggledShadow().shadowEnabled)
    }

    func test_setShadowOpacity_clampsTo01() {
        let s = CanvasSettings.default
        XCTAssertEqual(s.withShadowOpacity(0.5).shadowOpacity, 0.5, accuracy: 0.001)
        XCTAssertEqual(s.withShadowOpacity(-0.5).shadowOpacity, 0, accuracy: 0.001)
        XCTAssertEqual(s.withShadowOpacity(1.5).shadowOpacity, 1, accuracy: 0.001)
    }

    func test_nextCornerRadius_cyclesThroughPresets() {
        var s = CanvasSettings(cornerRadius: 0)
        let size = CGSize(width: 200, height: 200)
        s = s.withNextCornerRadius(selectionSize: size)
        XCTAssertEqual(s.cornerRadius, 8, accuracy: 0.001)
        s = s.withNextCornerRadius(selectionSize: size)
        XCTAssertEqual(s.cornerRadius, 16, accuracy: 0.001)
        s = s.withNextCornerRadius(selectionSize: size)
        XCTAssertEqual(s.cornerRadius, 24, accuracy: 0.001)
    }

    func test_nextCornerRadius_wrapsAroundToZero() {
        let s = CanvasSettings(cornerRadius: 32)
        let next = s.withNextCornerRadius(selectionSize: CGSize(width: 200, height: 200))
        XCTAssertEqual(next.cornerRadius, 0, accuracy: 0.001)
    }

    func test_nextCornerRadius_clampsToSmallSelection() {
        let s = CanvasSettings(cornerRadius: 24)
        let next = s.withNextCornerRadius(selectionSize: CGSize(width: 20, height: 20))
        XCTAssertLessThanOrEqual(next.cornerRadius, 10)
    }

    func test_shadowOpacityPersistsWhenToggling() {
        let s = CanvasSettings.default.withShadowOpacity(0.5)
        let toggled = s.toggledShadow()
        XCTAssertEqual(toggled.shadowOpacity, 0.5, accuracy: 0.001)
    }
}
