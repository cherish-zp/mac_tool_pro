import XCTest
import CoreGraphics

/// TDD: 工具条定位 - 选区正上方居中，上方放不下则下方，夹取到屏幕边界。
final class ToolbarPositionerTests: XCTestCase {

    private let tbSize = CGSize(width: 740, height: 44)

    func test_centeredAboveSelection_mainScreen() {
        // 主屏 1920x1080，选区居中 (660,400,600,300) -> midX=960, maxY=700
        // 工具条 x = 960-370 = 590, y = 700+8 = 708
        let sel = CGRect(x: 660, y: 400, width: 600, height: 300)
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let pos = ToolbarPositioner.position(forSelection: sel, toolbarSize: tbSize, screenFrame: screen)
        XCTAssertEqual(pos.x, 590, accuracy: 0.001)
        XCTAssertEqual(pos.y, 708, accuracy: 0.001)
    }

    func test_aboveOverflow_movesBelow() {
        // 选区靠近顶部，工具条放不下 -> 移到选区下方
        let sel = CGRect(x: 100, y: 1000, width: 600, height: 50) // maxY=1050
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let pos = ToolbarPositioner.position(forSelection: sel, toolbarSize: tbSize, screenFrame: screen)
        // 下方：y = 1000 - 44 - 8 = 948
        XCTAssertEqual(pos.y, 948, accuracy: 0.001)
    }

    func test_secondaryScreen_addsOriginOffset() {
        // 副屏 origin (1920,0)，选区在副屏 (100,400,600,300) 视图坐标
        // midX=400, 屏幕 x = 400-370+1920 = 1950, y = 700+8+0 = 708
        let sel = CGRect(x: 100, y: 400, width: 600, height: 300)
        let screen = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let pos = ToolbarPositioner.position(forSelection: sel, toolbarSize: tbSize, screenFrame: screen)
        XCTAssertEqual(pos.x, 1950, accuracy: 0.001)
        XCTAssertEqual(pos.y, 708, accuracy: 0.001)
    }

    func test_clampedToScreenEdge() {
        // 选区在最左侧，工具条居中后超出左边界 -> 夹取到屏幕左边缘
        let sel = CGRect(x: 0, y: 400, width: 100, height: 300) // midX=50
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let pos = ToolbarPositioner.position(forSelection: sel, toolbarSize: tbSize, screenFrame: screen)
        XCTAssertEqual(pos.x, 0, accuracy: 0.001) // 夹取到 minX=0
    }
}
