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

    // MARK: - topBar 模式（顶部横条呼吸灯）

    func test_topBarMode_initiallyHidden() {
        let state = PinCloseButtonState(mode: .topBar)
        XCTAssertFalse(state.isVisible, "横条模式下按钮默认隐藏，悬停贴图才浮现")
        XCTAssertTrue(state.showsX, "横条模式浮现时直接显示 X")
        XCTAssertEqual(state.color, .red, "横条模式浮现时为红色")
    }

    func test_topBarMode_imageHoverEnter_reveals() {
        var state = PinCloseButtonState(mode: .topBar)
        state.onImageHoverEnter()
        XCTAssertTrue(state.isVisible, "悬停贴图时浮现关闭按钮")
        XCTAssertEqual(state.color, .red)
        XCTAssertTrue(state.showsX)
    }

    func test_topBarMode_imageHoverExit_hides() {
        var state = PinCloseButtonState(mode: .topBar)
        state.onImageHoverEnter()
        state.onImageHoverExit()
        XCTAssertFalse(state.isVisible, "移出贴图后按钮隐藏")
    }

    func test_topBarMode_blinkTick_doesNothing() {
        var state = PinCloseButtonState(mode: .topBar)
        state.onBlinkTick()
        XCTAssertFalse(state.isVisible, "横条模式不闪烁，未悬停仍应隐藏")
        state.onImageHoverEnter()
        state.onBlinkTick()
        XCTAssertTrue(state.isVisible, "悬停时闪烁回调不影响可见性")
    }

    func test_setMode_switchResetsToCleanState() {
        var state = PinCloseButtonState(mode: .topBar)
        state.onImageHoverEnter()
        state.setMode(.cornerDot)
        XCTAssertEqual(state.color, .green, "切回圆点模式应重置为初始绿色")
        XCTAssertTrue(state.isVisible, "圆点模式初始闪烁可见")
        XCTAssertFalse(state.showsX)
    }
}
