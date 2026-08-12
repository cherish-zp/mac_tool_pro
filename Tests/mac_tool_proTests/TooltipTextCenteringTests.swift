import XCTest
import CoreGraphics

/// TDD: 提示文字垂直居中 — 根据字体度量计算基线 y 坐标，修正 NSTextField 默认偏上。
final class TooltipTextCenteringTests: XCTestCase {

    func test_baselineY_centersTextWithEqualTopBottomMargins() {
        let containerHeight: CGFloat = 22
        let ascender: CGFloat = 14
        let descender: CGFloat = -4
        let y = TooltipTextCentering.baselineY(
            containerHeight: containerHeight, ascender: ascender, descender: descender)
        let topOfText = y + ascender
        let bottomOfText = y + descender
        let topMargin = containerHeight - topOfText
        let bottomMargin = bottomOfText
        XCTAssertEqual(topMargin, bottomMargin, accuracy: 0.001)
    }

    func test_baselineY_value() {
        // containerHeight=22, a=14, d=-4 → y = 22/2 - (14-4)/2 = 11 - 5 = 6
        let y = TooltipTextCentering.baselineY(containerHeight: 22, ascender: 14, descender: -4)
        XCTAssertEqual(y, 6, accuracy: 0.001)
    }

    func test_baselineY_symmetricFont() {
        // ascender = -descender → baseline at center
        let y = TooltipTextCentering.baselineY(containerHeight: 20, ascender: 10, descender: -10)
        XCTAssertEqual(y, 10, accuracy: 0.001)
    }

    func test_baselineY_realSystemFont() {
        let font = NSFont.systemFont(ofSize: 12, weight: .medium)
        let containerHeight: CGFloat = 28
        let y = TooltipTextCentering.baselineY(
            containerHeight: containerHeight, ascender: font.ascender, descender: font.descender)
        let topMargin = containerHeight - (y + font.ascender)
        let bottomMargin = y + font.descender
        XCTAssertEqual(topMargin, bottomMargin, accuracy: 0.01)
    }
}
