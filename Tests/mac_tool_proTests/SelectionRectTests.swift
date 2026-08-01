import XCTest
import CoreGraphics

/// TDD: 截图选区模型 - 规范化拖拽矩形、夹取到屏幕边界、最小尺寸约束。
final class SelectionRectTests: XCTestCase {

    func test_normalize_invertedDrag() {
        // 从右下往左上拖：start(100,100) end(50,50) 应规范为 origin(50,50) w50 h50
        let rect = SelectionRect.normalize(start: CGPoint(x: 100, y: 100), end: CGPoint(x: 50, y: 50))
        XCTAssertEqual(rect.origin, CGPoint(x: 50, y: 50))
        XCTAssertEqual(rect.width, 50, accuracy: 0.001)
        XCTAssertEqual(rect.height, 50, accuracy: 0.001)
    }

    func test_normalize_normalDrag() {
        let rect = SelectionRect.normalize(start: CGPoint(x: 10, y: 20), end: CGPoint(x: 110, y: 70))
        XCTAssertEqual(rect.origin, CGPoint(x: 10, y: 20))
        XCTAssertEqual(rect.width, 100, accuracy: 0.001)
        XCTAssertEqual(rect.height, 50, accuracy: 0.001)
    }

    func test_clampToBounds() {
        let bounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        // 选区超出右下边界
        let rect = SelectionRect.clamp(
            CGRect(x: 1900, y: 1000, width: 100, height: 100),
            to: bounds
        )
        XCTAssertEqual(rect.maxX, 1920, accuracy: 0.001)
        XCTAssertEqual(rect.maxY, 1080, accuracy: 0.001)
    }

    func test_clamp_negativeOrigin() {
        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let rect = SelectionRect.clamp(
            CGRect(x: -50, y: -30, width: 200, height: 200),
            to: bounds
        )
        XCTAssertEqual(rect.origin, CGPoint(x: 0, y: 0))
    }

    func test_enforceMinimumSize_tooSmall() {
        let rect = SelectionRect.enforceMinimumSize(
            CGRect(x: 10, y: 10, width: 3, height: 5),
            minimum: 10
        )
        XCTAssertEqual(rect.width, 10, accuracy: 0.001)
        XCTAssertEqual(rect.height, 10, accuracy: 0.001)
    }

    func test_enforceMinimumSize_alreadyValid() {
        let original = CGRect(x: 10, y: 10, width: 200, height: 150)
        let rect = SelectionRect.enforceMinimumSize(original, minimum: 10)
        XCTAssertEqual(rect, original)
    }

    func test_isValid_aboveMinimum() {
        XCTAssertTrue(SelectionRect.isValid(CGRect(x: 0, y: 0, width: 50, height: 50), minimum: 10))
    }

    func test_isValid_belowMinimum() {
        XCTAssertFalse(SelectionRect.isValid(CGRect(x: 0, y: 0, width: 5, height: 50), minimum: 10))
    }
}
