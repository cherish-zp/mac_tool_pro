import XCTest
import CoreGraphics

/// TDD: 标注颜色模型 - 预设调色板 + 自定义颜色 RGB。
final class AnnotationColorTests: XCTestCase {

    func test_presets_containsSixColors() {
        XCTAssertEqual(AnnotationColor.presets.count, 6)
        XCTAssertEqual(AnnotationColor.presets, [.red, .green, .blue, .purple, .white, .black])
    }

    func test_customColor_equality() {
        XCTAssertEqual(AnnotationColor.custom(red: 0.5, green: 0.3, blue: 0.8),
                       AnnotationColor.custom(red: 0.5, green: 0.3, blue: 0.8))
        XCTAssertNotEqual(AnnotationColor.custom(red: 0.5, green: 0.3, blue: 0.8),
                          AnnotationColor.custom(red: 0.5, green: 0.3, blue: 0.9))
    }

    func test_customColor_notEqualPreset() {
        XCTAssertNotEqual(AnnotationColor.custom(red: 1, green: 0, blue: 0), .red)
    }

    func test_rgbComponents_customReturnsStoredValues() {
        let c = AnnotationColor.custom(red: 0.1, green: 0.2, blue: 0.3)
        let rgb = c.rgbComponents
        XCTAssertEqual(rgb.red, 0.1, accuracy: 0.001)
        XCTAssertEqual(rgb.green, 0.2, accuracy: 0.001)
        XCTAssertEqual(rgb.blue, 0.3, accuracy: 0.001)
    }

    func test_rgbComponents_presetsAreDistinct() {
        let keys = AnnotationColor.presets.map { "\($0.rgbComponents.red),\($0.rgbComponents.green),\($0.rgbComponents.blue)" }
        XCTAssertEqual(Set(keys).count, 6)
    }
}
