import XCTest
import CoreGraphics

/// TDD: 缩放手柄 -> 光标类型映射。确保拖拽边/角时光标正确指示缩放方向。
final class ResizeCursorKindTests: XCTestCase {

    func test_topBottom_returnsResizeVertical() {
        XCTAssertEqual(ResizeHandle.top.cursorKind, .resizeVertical)
        XCTAssertEqual(ResizeHandle.bottom.cursorKind, .resizeVertical)
    }

    func test_leftRight_returnsResizeHorizontal() {
        XCTAssertEqual(ResizeHandle.left.cursorKind, .resizeHorizontal)
        XCTAssertEqual(ResizeHandle.right.cursorKind, .resizeHorizontal)
    }

    func test_topLeftBottomRight_returnsDiagonalTLBR() {
        XCTAssertEqual(ResizeHandle.topLeft.cursorKind, .resizeDiagonalTLBR)
        XCTAssertEqual(ResizeHandle.bottomRight.cursorKind, .resizeDiagonalTLBR)
    }

    func test_topRightBottomLeft_returnsDiagonalBLTR() {
        XCTAssertEqual(ResizeHandle.topRight.cursorKind, .resizeDiagonalBLTR)
        XCTAssertEqual(ResizeHandle.bottomLeft.cursorKind, .resizeDiagonalBLTR)
    }

    func test_interior_returnsMove() {
        XCTAssertEqual(ResizeHandle.interior.cursorKind, .move)
    }
}
