import XCTest
import CoreGraphics

/// TDD: 截图子面板（更多/画布/颜色）点击外部关闭的几何判定。
/// 背景：更多面板曾跨截图会话泄漏残留（会话结束未关闭、无点击外部关闭），
/// 堆积在屏幕左侧无法消除。
final class PanelDismissalTests: XCTestCase {

    private let toolbarFrame = CGRect(x: 500, y: 500, width: 690, height: 48)
    private let panelFrame = CGRect(x: 800, y: 420, width: 80, height: 44)

    func test_clickOutsidePanelsAndToolbar_dismisses() {
        let click = CGPoint(x: 100, y: 100)
        XCTAssertTrue(
            PanelDismissal.shouldDismiss(click: click, panelFrames: [panelFrame], toolbarFrame: toolbarFrame),
            "点击面板与工具条之外的任意位置应关闭面板"
        )
    }

    func test_clickInsidePanel_keepsOpen() {
        let click = CGPoint(x: 810, y: 430)
        XCTAssertFalse(
            PanelDismissal.shouldDismiss(click: click, panelFrames: [panelFrame], toolbarFrame: toolbarFrame),
            "点击面板内部不关闭（交给面板自身按钮处理）"
        )
    }

    func test_clickInsideToolbar_keepsOpen() {
        let click = CGPoint(x: 600, y: 510)
        XCTAssertFalse(
            PanelDismissal.shouldDismiss(click: click, panelFrames: [panelFrame], toolbarFrame: toolbarFrame),
            "点击工具条不关闭（按钮自身处理切换）"
        )
    }

    func test_clickInsideAnyOfMultiplePanels_keepsOpen() {
        let otherPanel = CGRect(x: 0, y: 0, width: 80, height: 44)
        let clickInOther = CGPoint(x: 10, y: 10)
        XCTAssertFalse(
            PanelDismissal.shouldDismiss(click: clickInOther, panelFrames: [panelFrame, otherPanel], toolbarFrame: toolbarFrame),
            "任一打开的面板被点击都不关闭"
        )
    }

    func test_containsPoint() {
        XCTAssertTrue(PanelDismissal.containsPoint(CGPoint(x: 810, y: 430), frames: [panelFrame]))
        XCTAssertTrue(PanelDismissal.containsPoint(CGPoint(x: 600, y: 510), frames: [toolbarFrame]))
        XCTAssertFalse(PanelDismissal.containsPoint(CGPoint(x: 1, y: 1), frames: [panelFrame]))
    }
}
