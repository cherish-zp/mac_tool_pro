import XCTest
import CoreGraphics

/// TDD: 工具条图标按钮悬停提示 - 纯函数计算提示窗口屏幕坐标 + 多按钮悬停状态机。
final class CopyButtonTooltipTests: XCTestCase {

    private let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    private let labelSize = CGSize(width: 28, height: 16)

    func test_tooltipAboveButton_whenRoomAbove() {
        let button = CGRect(x: 1000, y: 500, width: 28, height: 28)
        let frame = CopyButtonTooltip.windowFrame(
            buttonScreenFrame: button, labelSize: labelSize, screenFrame: screen)
        // width = 28 + 12 = 40, height = 16 + 6 = 22
        XCTAssertEqual(frame.width, 40, accuracy: 0.001)
        XCTAssertEqual(frame.height, 22, accuracy: 0.001)
        XCTAssertEqual(frame.midX, button.midX, accuracy: 0.001)
        // aboveY = 528 + 6 = 534
        XCTAssertEqual(frame.minY, 534, accuracy: 0.001)
    }

    func test_tooltipBelowButton_whenNoRoomAbove() {
        let button = CGRect(x: 1000, y: 1066, width: 28, height: 28) // maxY=1094+6+22=1122>1080
        let frame = CopyButtonTooltip.windowFrame(
            buttonScreenFrame: button, labelSize: labelSize, screenFrame: screen)
        // 下方: belowY = 1066 - 6 - 22 = 1038
        XCTAssertEqual(frame.minY, 1038, accuracy: 0.001)
        XCTAssertEqual(frame.midX, button.midX, accuracy: 0.001)
    }

    func test_tooltipClampedHorizontallyToScreen() {
        let button = CGRect(x: 0, y: 500, width: 28, height: 28)
        let frame = CopyButtonTooltip.windowFrame(
            buttonScreenFrame: button, labelSize: labelSize, screenFrame: screen)
        // centerX = 14 - 20 = -6 -> 夹取到 0
        XCTAssertEqual(frame.minX, 0, accuracy: 0.001)
    }

    func test_hoverState_enterLeaveSwitch() {
        var state = ToolbarHoverState()
        XCTAssertNil(state.currentTooltip)
        // 进入复制按钮
        XCTAssertTrue(state.update(matchedTooltip: "复制"))
        XCTAssertEqual(state.currentTooltip, "复制")
        // 停留，无变化
        XCTAssertFalse(state.update(matchedTooltip: "复制"))
        // 切换到下载按钮
        XCTAssertTrue(state.update(matchedTooltip: "下载"))
        XCTAssertEqual(state.currentTooltip, "下载")
        // 切换到贴图按钮
        XCTAssertTrue(state.update(matchedTooltip: "贴图"))
        XCTAssertEqual(state.currentTooltip, "贴图")
        // 离开所有按钮
        XCTAssertTrue(state.update(matchedTooltip: nil))
        XCTAssertNil(state.currentTooltip)
    }
}
