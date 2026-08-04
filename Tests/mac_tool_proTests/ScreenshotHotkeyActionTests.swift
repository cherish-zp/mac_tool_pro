import XCTest
import CoreGraphics

/// TDD: 截图全局热键动作映射。F1 -> 截图，F3 -> 贴图。
final class ScreenshotHotkeyActionTests: XCTestCase {

    func test_f1KeyCode_mapsToScreenshot() {
        XCTAssertEqual(ScreenshotHotkeyAction.action(for: 122), .screenshot)
    }

    func test_f3KeyCode_mapsToPin() {
        XCTAssertEqual(ScreenshotHotkeyAction.action(for: 99), .pin)
    }

    func test_unknownKeyCode_returnsNil() {
        XCTAssertNil(ScreenshotHotkeyAction.action(for: 0))
        XCTAssertNil(ScreenshotHotkeyAction.action(for: 200))
    }

    func test_keyCodeConstants() {
        XCTAssertEqual(ScreenshotHotkeyAction.f1KeyCode, 122)
        XCTAssertEqual(ScreenshotHotkeyAction.f3KeyCode, 99)
    }
}
