import XCTest
import CoreGraphics

/// TDD: 工具条定位 - 固定选区下方居中，下方放不下回退上方，夹取到屏幕边界。
final class ToolbarPositionerTests: XCTestCase {

    private let tbSize = CGSize(width: 740, height: 44)

    func test_centeredBelowSelection_mainScreen() {
        // 主屏 1920x1080，选区 (660,400,600,300) -> midX=960, minY=400
        // 下方：y = 400 - 44 - 8 = 348, x = 960-370 = 590
        let sel = CGRect(x: 660, y: 400, width: 600, height: 300)
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let pos = ToolbarPositioner.position(forSelection: sel, toolbarSize: tbSize, screenFrame: screen)
        XCTAssertEqual(pos.x, 590, accuracy: 0.001)
        XCTAssertEqual(pos.y, 348, accuracy: 0.001)
    }

    func test_belowOverflow_fallbackAbove() {
        // 选区靠近底部，工具条下方放不下 -> 回退到选区上方
        let sel = CGRect(x: 100, y: 10, width: 600, height: 50) // minY=10
        // 下方 y = 10-44-8 = -42 < 0 -> 回退上方: maxY+8 = 68
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let pos = ToolbarPositioner.position(forSelection: sel, toolbarSize: tbSize, screenFrame: screen)
        XCTAssertEqual(pos.y, 68, accuracy: 0.001)
    }

    func test_secondaryScreen_addsOriginOffset() {
        // 副屏 origin (1920,0)，选区 (100,400,600,300) 视图坐标
        // midX=400, x = 400-370+1920 = 1950, y = 400-44-8+0 = 348
        let sel = CGRect(x: 100, y: 400, width: 600, height: 300)
        let screen = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let pos = ToolbarPositioner.position(forSelection: sel, toolbarSize: tbSize, screenFrame: screen)
        XCTAssertEqual(pos.x, 1950, accuracy: 0.001)
        XCTAssertEqual(pos.y, 348, accuracy: 0.001)
    }

    func test_clampedToScreenEdge() {
        // 选区在最左侧，工具条居中后超出左边界 -> 夹取到屏幕左边缘
        let sel = CGRect(x: 0, y: 400, width: 100, height: 300) // midX=50
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let pos = ToolbarPositioner.position(forSelection: sel, toolbarSize: tbSize, screenFrame: screen)
        XCTAssertEqual(pos.x, 0, accuracy: 0.001)
    }
}
