import XCTest
import CoreGraphics

/// TDD: 贴图定位器 - 将选区坐标（相对屏幕原点）转为绝对屏幕坐标。
final class PinPositionerTests: XCTestCase {

    func test_mainScreen_noOffset() {
        // 主屏 origin=(0,0)，贴图位置 = 选区位置
        let sel = CGPoint(x: 200, y: 300)
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let pin = PinPositioner.pinPoint(selectionOrigin: sel, screenFrame: screen)
        XCTAssertEqual(pin.x, 200, accuracy: 0.001)
        XCTAssertEqual(pin.y, 300, accuracy: 0.001)
    }

    func test_secondaryScreen_addsOffset() {
        // 副屏在主屏右侧，origin=(1920,0)
        let sel = CGPoint(x: 200, y: 300)
        let screen = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let pin = PinPositioner.pinPoint(selectionOrigin: sel, screenFrame: screen)
        XCTAssertEqual(pin.x, 2120, accuracy: 0.001)
        XCTAssertEqual(pin.y, 300, accuracy: 0.001)
    }

    func test_secondaryScreen_leftSide_negativeOffset() {
        // 副屏在主屏左侧，origin=(-1920,0)
        let sel = CGPoint(x: 100, y: 50)
        let screen = CGRect(x: -1920, y: 0, width: 1920, height: 1080)
        let pin = PinPositioner.pinPoint(selectionOrigin: sel, screenFrame: screen)
        XCTAssertEqual(pin.x, -1820, accuracy: 0.001)
    }
}
