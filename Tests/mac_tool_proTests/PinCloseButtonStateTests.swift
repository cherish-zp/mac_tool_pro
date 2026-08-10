import XCTest
import AppKit

/// TDD: 贴图关闭按钮状态机 - 悬停变色+X，非悬停时每1s闪烁。
final class PinCloseButtonStateTests: XCTestCase {

    func test_initialState_greenNoX_blinkVisible() {
        let state = PinCloseButtonState()
        XCTAssertEqual(state.color, .green)
        XCTAssertFalse(state.showsX)
        XCTAssertTrue(state.isVisible, "初始状态按钮应可见")
    }

    func test_onHoverEnter_redShowsX_alwaysVisible() {
        var state = PinCloseButtonState()
        state.onHoverEnter()
        XCTAssertEqual(state.color, .red)
        XCTAssertTrue(state.showsX)
        XCTAssertTrue(state.isVisible, "悬停时常显")
    }

    func test_onHoverExit_backToGreen() {
        var state = PinCloseButtonState()
        state.onHoverEnter()
        state.onHoverExit()
        XCTAssertEqual(state.color, .green)
        XCTAssertFalse(state.showsX)
    }

    func test_onBlinkTick_togglesVisibility() {
        var state = PinCloseButtonState()
        XCTAssertTrue(state.isVisible)
        state.onBlinkTick()
        XCTAssertFalse(state.isVisible, "闪烁后应不可见")
        state.onBlinkTick()
        XCTAssertTrue(state.isVisible, "再次闪烁后应可见")
    }

    func test_onBlinkTick_whenHovered_doesNotBlink() {
        var state = PinCloseButtonState()
        state.onHoverEnter()
        state.onBlinkTick()
        XCTAssertTrue(state.isVisible, "悬停时不闪烁，保持可见")
    }

    func test_onHoverExit_resetsBlinkVisible() {
        var state = PinCloseButtonState()
        state.onBlinkTick()  // 不可见
        XCTAssertFalse(state.isVisible)
        state.onHoverEnter()
        state.onHoverExit()
        XCTAssertTrue(state.isVisible, "离开悬停后重置为可见")
    }
}
