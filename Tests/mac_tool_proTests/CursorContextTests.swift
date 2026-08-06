import XCTest
import CoreGraphics

/// TDD: 光标上下文映射 - 截图区域 -> 十字光标，工具条 -> 箭头，区域变化时触发动效。
final class CursorContextTests: XCTestCase {

    func test_screenshotArea_defaultIsCrosshair() {
        XCTAssertEqual(CursorContext.screenshotArea.defaultStyle, .crosshair)
    }

    func test_toolbarArea_defaultIsArrow() {
        XCTAssertEqual(CursorContext.toolbarArea.defaultStyle, .arrow)
    }

    func test_background_defaultIsCrosshair() {
        XCTAssertEqual(CursorContext.background.defaultStyle, .crosshair)
    }

    func test_shouldAnimate_differentContexts() {
        XCTAssertTrue(CursorContext.shouldAnimate(from: .screenshotArea, to: .toolbarArea))
        XCTAssertTrue(CursorContext.shouldAnimate(from: .toolbarArea, to: .background))
    }

    func test_shouldAnimate_sameContext() {
        XCTAssertFalse(CursorContext.shouldAnimate(from: .screenshotArea, to: .screenshotArea))
        XCTAssertFalse(CursorContext.shouldAnimate(from: .toolbarArea, to: .toolbarArea))
    }

    // MARK: - 工具条光标显式验证

    func test_toolbarArea_isNotCrosshair() {
        XCTAssertNotEqual(CursorContext.toolbarArea.defaultStyle, .crosshair)
        XCTAssertEqual(CursorContext.toolbarArea.defaultStyle, .arrow)
    }

    func test_screenshotArea_isNotArrow() {
        XCTAssertNotEqual(CursorContext.screenshotArea.defaultStyle, .arrow)
    }
}
