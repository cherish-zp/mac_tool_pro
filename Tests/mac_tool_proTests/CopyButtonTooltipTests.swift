import XCTest
import CoreGraphics

/// TDD: 对勾复制按钮悬停提示 - 纯函数计算提示窗口屏幕坐标 + 悬停状态机。
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

    func test_hoverState_enterShows_leaveHides() {
        var state = CopyButtonHoverState()
        let button = CGRect(x: 0, y: 0, width: 28, height: 28)
        XCTAssertFalse(state.isHovering)
        XCTAssertTrue(state.update(point: CGPoint(x: 10, y: 10), buttonFrame: button))
        XCTAssertTrue(state.isHovering)
        XCTAssertFalse(state.update(point: CGPoint(x: 10, y: 10), buttonFrame: button))
        XCTAssertTrue(state.update(point: CGPoint(x: 100, y: 100), buttonFrame: button))
        XCTAssertFalse(state.isHovering)
    }
}
