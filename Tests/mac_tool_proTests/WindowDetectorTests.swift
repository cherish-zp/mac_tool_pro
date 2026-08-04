import XCTest
import CoreGraphics

/// TDD: 窗口检测器 - 从窗口列表中找到鼠标下最顶层的普通窗口。
final class WindowDetectorTests: XCTestCase {

    private func makeWindow(_ id: Int, bounds: CGRect, layer: Int = 0, pid: Int32 = 1) -> WindowInfo {
        WindowInfo(bounds: bounds, layer: layer, ownerPid: pid, windowId: id)
    }

    // MARK: - topmostWindow

    func test_pointInside_returnsWindow() {
        let windows = [makeWindow(1, bounds: CGRect(x: 0, y: 0, width: 800, height: 600))]
        let result = WindowDetector.topmostWindow(at: CGPoint(x: 100, y: 100), in: windows)
        XCTAssertEqual(result?.windowId, 1)
    }

    func test_pointOutside_returnsNil() {
        let windows = [makeWindow(1, bounds: CGRect(x: 0, y: 0, width: 800, height: 600))]
        let result = WindowDetector.topmostWindow(at: CGPoint(x: 1000, y: 1000), in: windows)
        XCTAssertNil(result)
    }

    func test_overlapping_returnsTopmost() {
        let windows = [
            makeWindow(1, bounds: CGRect(x: 0, y: 0, width: 800, height: 600)),
            makeWindow(2, bounds: CGRect(x: 100, y: 100, width: 400, height: 300)),
        ]
        // 点在两个窗口内，返回列表中第一个（最顶层）
        let result = WindowDetector.topmostWindow(at: CGPoint(x: 200, y: 200), in: windows)
        XCTAssertEqual(result?.windowId, 1)
    }

    func test_excludesPid() {
        let windows = [
            makeWindow(1, bounds: CGRect(x: 0, y: 0, width: 800, height: 600), pid: 100),
            makeWindow(2, bounds: CGRect(x: 100, y: 100, width: 400, height: 300), pid: 200),
        ]
        let result = WindowDetector.topmostWindow(at: CGPoint(x: 200, y: 200), in: windows, excludingPids: [100])
        XCTAssertEqual(result?.windowId, 2)
    }

    func test_excludesNonZeroLayer() {
        let windows = [
            makeWindow(1, bounds: CGRect(x: 0, y: 0, width: 800, height: 600), layer: 25),
            makeWindow(2, bounds: CGRect(x: 0, y: 0, width: 800, height: 600), layer: 0),
        ]
        let result = WindowDetector.topmostWindow(at: CGPoint(x: 100, y: 100), in: windows)
        XCTAssertEqual(result?.windowId, 2)
    }

    func test_emptyList_returnsNil() {
        let result = WindowDetector.topmostWindow(at: CGPoint(x: 100, y: 100), in: [])
        XCTAssertNil(result)
    }

    // MARK: - ScreenCoordinateConverter

    func test_cgRectToViewRect_primaryScreen() {
        // 主屏 1080 高，窗口在 CG 坐标 (100, 200, 300, 400)
        // 视图坐标 y = 1080 - (200+400) - 0 = 480
        let cgRect = CGRect(x: 100, y: 200, width: 300, height: 400)
        let screenFrame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let viewRect = ScreenCoordinateConverter.cgRectToViewRect(cgRect, screenFrame: screenFrame, primaryScreenHeight: 1080)
        XCTAssertEqual(viewRect.origin.x, 100, accuracy: 0.001)
        XCTAssertEqual(viewRect.origin.y, 480, accuracy: 0.001)
        XCTAssertEqual(viewRect.width, 300, accuracy: 0.001)
        XCTAssertEqual(viewRect.height, 400, accuracy: 0.001)
    }

    func test_cgRectToViewRect_withScreenOffset() {
        // 副屏偏移 (1920, 0)，窗口在 CG 坐标 (2000, 100, 300, 200)
        // 视图坐标 x = 2000 - 1920 = 80, y = 1080 - (100+200) - 0 = 780
        let cgRect = CGRect(x: 2000, y: 100, width: 300, height: 200)
        let screenFrame = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let viewRect = ScreenCoordinateConverter.cgRectToViewRect(cgRect, screenFrame: screenFrame, primaryScreenHeight: 1080)
        XCTAssertEqual(viewRect.origin.x, 80, accuracy: 0.001)
        XCTAssertEqual(viewRect.origin.y, 780, accuracy: 0.001)
    }
}
