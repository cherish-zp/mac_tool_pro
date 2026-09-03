import XCTest

/// TDD: 贴图呼吸灯外观颜色工具 - hex 解析、默认色、预设色板。
final class PinIndicatorColorTests: XCTestCase {

    func test_colorFromHex_parsesComponents() {
        let color = PinIndicatorColor.color(fromHex: "4DD94F")
        XCTAssertNotNil(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color!.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, 77.0 / 255.0, accuracy: 0.001)
        XCTAssertEqual(g, 217.0 / 255.0, accuracy: 0.001)
        XCTAssertEqual(b, 79.0 / 255.0, accuracy: 0.001)
        XCTAssertEqual(a, 1.0, accuracy: 0.001)
    }

    func test_colorFromHex_toleratesLeadingHash() {
        XCTAssertNotNil(PinIndicatorColor.color(fromHex: "#FF3B30"))
        XCTAssertNotNil(PinIndicatorColor.color(fromHex: "FF3B30"))
    }

    func test_colorFromHex_invalidReturnsNil() {
        XCTAssertNil(PinIndicatorColor.color(fromHex: ""))
        XCTAssertNil(PinIndicatorColor.color(fromHex: "not-a-color"))
        XCTAssertNil(PinIndicatorColor.color(fromHex: "12345"))
        XCTAssertNil(PinIndicatorColor.color(fromHex: "GGGGGG"))
    }

    func test_defaultHex_isGreen() {
        XCTAssertEqual(PinIndicatorColor.defaultHex, "4DD94F", "默认呼吸灯颜色应为现有亮绿色")
        XCTAssertNotNil(PinIndicatorColor.color(fromHex: PinIndicatorColor.defaultHex))
    }

    func test_palette_containsEnoughSwatches_andAllParsable() {
        let palette = PinIndicatorColor.paletteHexes
        XCTAssertGreaterThanOrEqual(palette.count, 7, "预设色板至少 7 种颜色")
        XCTAssertTrue(palette.contains(PinIndicatorColor.defaultHex), "默认绿色必须在色板中")
        for hex in palette {
            XCTAssertNotNil(PinIndicatorColor.color(fromHex: hex), "色板中的 \(hex) 必须可解析")
        }
        XCTAssertEqual(Set(palette).count, palette.count, "色板颜色不得重复")
    }

    // MARK: - 呼吸灯"灯感"参数（避免低透明度时淡成幻影线）

    func test_breathOpacityRange_staysVisibleAtDimPhase() {
        let min = PinIndicatorAppearance.breathMinOpacity
        let max = PinIndicatorAppearance.breathMaxOpacity
        XCTAssertGreaterThanOrEqual(min, 0.4, "呼吸最低亮度不得低于 0.4，否则淡得像残影弧线")
        XCTAssertLessThanOrEqual(max, 1.0)
        XCTAssertLessThan(min, max, "最低亮度必须低于最高亮度才有呼吸感")
    }
}
