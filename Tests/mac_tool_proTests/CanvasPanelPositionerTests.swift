import XCTest
import CoreGraphics

/// TDD: 画布子面板定位 - 确保子面板不与工具栏重叠。
final class CanvasPanelPositionerTests: XCTestCase {

    private let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)

    func test_panelBelowToolbar_noOverlap() {
        let toolbar = CGRect(x: 500, y: 600, width: 690, height: 48)
        let panelSize = CGSize(width: 320, height: 44)
        let pos = CanvasPanelPositioner.position(
            toolbarFrame: toolbar, panelSize: panelSize, screenFrame: screen)
        // 面板顶部应在工具栏底部下方（有间距）
        XCTAssertLessThanOrEqual(pos.y + panelSize.height, toolbar.minY)
        // 水平居中于工具栏
        XCTAssertEqual(pos.x + panelSize.width / 2, toolbar.midX, accuracy: 1)
    }

    func test_panelBelowToolbar_respectsGap() {
        let toolbar = CGRect(x: 500, y: 600, width: 690, height: 48)
        let panelSize = CGSize(width: 320, height: 44)
        let gap: CGFloat = 8
        let pos = CanvasPanelPositioner.position(
            toolbarFrame: toolbar, panelSize: panelSize, screenFrame: screen, gap: gap)
        let panelTop = pos.y + panelSize.height
        let actualGap = toolbar.minY - panelTop
        XCTAssertEqual(actualGap, gap, accuracy: 0.001)
    }

    func test_panelAboveToolbar_whenNoRoomBelow() {
        let toolbar = CGRect(x: 500, y: 10, width: 690, height: 48)
        let panelSize = CGSize(width: 320, height: 44)
        let pos = CanvasPanelPositioner.position(
            toolbarFrame: toolbar, panelSize: panelSize, screenFrame: screen)
        // 面板底部应在工具栏顶部上方
        XCTAssertGreaterThanOrEqual(pos.y, toolbar.maxY)
    }

    func test_panelClampedToScreenBounds() {
        let toolbar = CGRect(x: 0, y: 600, width: 690, height: 48)
        let panelSize = CGSize(width: 320, height: 44)
        let pos = CanvasPanelPositioner.position(
            toolbarFrame: toolbar, panelSize: panelSize, screenFrame: screen)
        XCTAssertGreaterThanOrEqual(pos.x, screen.minX)
        XCTAssertLessThanOrEqual(pos.x + panelSize.width, screen.maxX)
    }
}
