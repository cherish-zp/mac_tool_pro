import XCTest
import CoreGraphics

/// TDD: 自定义颜色面板定位 - 放在触发按钮正上方（水平居中），放不下回退下方。
final class ColorPanelPositionerTests: XCTestCase {

    private let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    private let panelSize = CGSize(width: 240, height: 400)

    func test_directlyAbove_centeredHorizontally() {
        // 按钮在屏幕中部，面板放正上方（水平居中于按钮）
        let button = CGRect(x: 946, y: 500, width: 28, height: 28) // midX=960, maxY=528
        let origin = ColorPanelPositioner.origin(
            buttonScreenFrame: button, screenFrame: screen, panelSize: panelSize)
        // x = 960 - 120 = 840
        XCTAssertEqual(origin.x, 840, accuracy: 0.001)
        // y = 528 + 8 = 536（正上方）
        XCTAssertEqual(origin.y, 536, accuracy: 0.001)
    }

    func test_belowWhenAboveDoesNotFit() {
        // 按钮在屏幕顶部，上方放不下 -> 回退下方
        let button = CGRect(x: 946, y: 1000, width: 28, height: 28) // maxY=1028, 上方需 1028+8+400=1436>1080
        let origin = ColorPanelPositioner.origin(
            buttonScreenFrame: button, screenFrame: screen, panelSize: panelSize)
        // 下方: y = 1000 - 8 - 400 = 592
        XCTAssertEqual(origin.y, 592, accuracy: 0.001)
        XCTAssertEqual(origin.x, 840, accuracy: 0.001)
    }

    func test_clampedToLeftEdge() {
        // 按钮在屏幕左边缘，面板居中后超出左边界 -> 夹取到左边界
        let button = CGRect(x: 0, y: 500, width: 28, height: 28) // midX=14
        let origin = ColorPanelPositioner.origin(
            buttonScreenFrame: button, screenFrame: screen, panelSize: panelSize)
        // x = 14 - 120 = -106 -> 夹取到 0
        XCTAssertEqual(origin.x, 0, accuracy: 0.001)
    }

    func test_clampedToRightEdge() {
        // 按钮在屏幕右边缘，面板居中后超出右边界 -> 夹取到右边界
        let button = CGRect(x: 1892, y: 500, width: 28, height: 28) // midX=1906
        let origin = ColorPanelPositioner.origin(
            buttonScreenFrame: button, screenFrame: screen, panelSize: panelSize)
        // x = 1906 - 120 = 1786, 1786+240=2026>1920 -> x=1920-240=1680
        XCTAssertEqual(origin.x, 1680, accuracy: 0.001)
    }

    func test_secondaryScreen_usesScreenFrame() {
        // 副屏 origin(1920,0)，按钮在副屏 -> 面板坐标基于副屏
        let secondary = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let button = CGRect(x: 2866, y: 500, width: 28, height: 28) // midX=2880
        let origin = ColorPanelPositioner.origin(
            buttonScreenFrame: button, screenFrame: secondary, panelSize: panelSize)
        // x = 2880 - 120 = 2760
        XCTAssertEqual(origin.x, 2760, accuracy: 0.001)
        XCTAssertEqual(origin.y, 536, accuracy: 0.001)
    }

    func test_panelLevelAboveOverlayAndToolbar() {
        // 覆盖层 screenSaver=1000，工具条 1002，预设色块面板 1003
        // NSColorPanel 层级必须高于所有这些，否则被全屏覆盖层遮挡
        let overlay = 1000
        let level = ColorPanelPositioner.panelLevelRaw(overlayLevelRaw: overlay)
        XCTAssertGreaterThan(level, overlay)
        XCTAssertGreaterThan(level, overlay + 3)
    }
}
