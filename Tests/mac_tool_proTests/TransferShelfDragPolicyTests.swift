import XCTest
import CoreGraphics

/// TDD: 全局拖拽判定 - mouseDown 后移动超过阈值视为拖拽会话进行。
final class TransferShelfDragPolicyTests: XCTestCase {

    func test_belowThresholdDoesNotTrigger() {
        var policy = TransferShelfDragPolicy()
        policy.mouseDown(at: CGPoint(x: 100, y: 100))
        XCTAssertFalse(policy.mouseDragged(to: CGPoint(x: 110, y: 105)))
    }

    func test_aboveThresholdTriggers() {
        var policy = TransferShelfDragPolicy()
        policy.mouseDown(at: CGPoint(x: 100, y: 100))
        XCTAssertTrue(policy.mouseDragged(to: CGPoint(x: 150, y: 130)))
    }

    func test_thresholdIs30Points() {
        XCTAssertEqual(TransferShelfDragPolicy.dragThreshold, 30, accuracy: 0.1)
    }

    func test_mouseUpEndsDragging() {
        var policy = TransferShelfDragPolicy()
        policy.mouseDown(at: .zero)
        policy.mouseDragged(to: CGPoint(x: 100, y: 0))
        XCTAssertTrue(policy.isDragging)
        policy.mouseUp()
        XCTAssertFalse(policy.isDragging)
    }

    func test_draggedWithoutDownDoesNotTrigger() {
        var policy = TransferShelfDragPolicy()
        XCTAssertFalse(policy.mouseDragged(to: CGPoint(x: 500, y: 500)))
        XCTAssertFalse(policy.isDragging)
    }

    func test_resetClearsState() {
        var policy = TransferShelfDragPolicy()
        policy.mouseDown(at: .zero)
        policy.mouseDragged(to: CGPoint(x: 100, y: 0))
        policy.reset()
        XCTAssertFalse(policy.isDragging)
        XCTAssertFalse(policy.mouseDragged(to: CGPoint(x: 400, y: 0)))
    }
}


/// TDD: 热区 hover 状态 - 进入顶部热区仅回调一次，避免重复触发。
final class TransferShelfHotZoneHoverTests: XCTestCase {

    func test_enterHotZoneReturnsTrueOnce() {
        var policy = TransferShelfDragPolicy()
        XCTAssertTrue(policy.hotZoneHoverChanged(inside: true))
        XCTAssertFalse(policy.hotZoneHoverChanged(inside: true))
    }

    func test_exitThenReenterHotZone() {
        var policy = TransferShelfDragPolicy()
        XCTAssertTrue(policy.hotZoneHoverChanged(inside: true))
        XCTAssertTrue(policy.hotZoneHoverChanged(inside: false))
        XCTAssertTrue(policy.hotZoneHoverChanged(inside: true))
    }

    func test_resetClearsHotZoneState() {
        var policy = TransferShelfDragPolicy()
        _ = policy.hotZoneHoverChanged(inside: true)
        policy.reset()
        XCTAssertTrue(policy.hotZoneHoverChanged(inside: true))
    }
}
