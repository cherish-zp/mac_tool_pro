import XCTest
import CoreGraphics

/// TDD: 截图选区模型 - 规范化拖拽矩形、夹取到屏幕边界、最小尺寸约束。
final class SelectionRectTests: XCTestCase {

    func test_normalize_invertedDrag() {
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

    // MARK: - Retina 像素缩放（点坐标 -> 像素坐标）

    func test_scaleToPixels_retina2x() {
        let viewSize = CGSize(width: 1920, height: 1080)
        let imageSize = CGSize(width: 3840, height: 2160)
        let rect = CGRect(x: 100, y: 200, width: 300, height: 400)
        let scaled = SelectionRect.scaleToPixels(rect, imageSize: imageSize, viewSize: viewSize)
        XCTAssertEqual(scaled.origin.x, 200, accuracy: 0.001)
        XCTAssertEqual(scaled.origin.y, 400, accuracy: 0.001)
        XCTAssertEqual(scaled.width, 600, accuracy: 0.001)
        XCTAssertEqual(scaled.height, 800, accuracy: 0.001)
    }

    func test_scaleToPixels_noScale() {
        let size = CGSize(width: 1920, height: 1080)
        let rect = CGRect(x: 50, y: 60, width: 100, height: 200)
        let scaled = SelectionRect.scaleToPixels(rect, imageSize: size, viewSize: size)
        XCTAssertEqual(scaled, rect)
    }

   func test_scaleToPixels_zeroViewSize() {
       let rect = CGRect(x: 10, y: 20, width: 30, height: 40)
       let scaled = SelectionRect.scaleToPixels(rect, imageSize: CGSize(width: 3840, height: 2160), viewSize: .zero)
       XCTAssertEqual(scaled, rect)
   }

    // MARK: - 标注局部坐标 -> 视图绝对坐标

    func test_toAbsolute_localToView() {
        // 标注点存储为相对选区原点的局部坐标，绘制时需加上选区原点还原为视图绝对坐标
        let abs = SelectionRect.toAbsolute(CGPoint(x: 100, y: 50), origin: CGPoint(x: 400, y: 200))
        XCTAssertEqual(abs, CGPoint(x: 500, y: 250))
    }

    func test_toAbsolute_zeroOrigin() {
        let abs = SelectionRect.toAbsolute(CGPoint(x: 30, y: 70), origin: .zero)
        XCTAssertEqual(abs, CGPoint(x: 30, y: 70))
    }

    // MARK: - 像素缩放往返（显示尺寸 = 选区点尺寸）

    func test_scaleToPixels_roundTrip_displaySizeEqualsSelection() {
        // 选区 300x400 点，2x Retina -> 像素 600x800
        // 裁剪后 NSImage 的 size 应为选区点尺寸(300x400)，而非像素尺寸(600x800)
        let sel = CGRect(x: 100, y: 200, width: 300, height: 400)
        let viewSize = CGSize(width: 1920, height: 1080)
        let imageSize = CGSize(width: 3840, height: 2160)
        let pixels = SelectionRect.scaleToPixels(sel, imageSize: imageSize, viewSize: viewSize)
        XCTAssertEqual(pixels.width, 600, accuracy: 0.001)
        XCTAssertEqual(pixels.height, 800, accuracy: 0.001)
        // 像素 -> 点尺寸：像素 / 缩放比 = 点尺寸 = 选区尺寸
        XCTAssertEqual(SelectionRect.pointSize(pixelSize: pixels.size, scaleFactor: 2.0), sel.size)
    }

    func test_pointSize_retina2x() {
        let pts = SelectionRect.pointSize(pixelSize: CGSize(width: 600, height: 800), scaleFactor: 2.0)
        XCTAssertEqual(pts.width, 300, accuracy: 0.001)
        XCTAssertEqual(pts.height, 400, accuracy: 0.001)
    }

    func test_pointSize_zeroScale() {
        // 缩放比为 0 时不崩溃，返回原值
        let pts = SelectionRect.pointSize(pixelSize: CGSize(width: 100, height: 200), scaleFactor: 0)
        XCTAssertEqual(pts, CGSize(width: 100, height: 200))
    }

    // MARK: - 贴图拖拽位移

    func test_dragOrigin_movesByDelta() {
        // 鼠标从 (500,600) 移到 (550,580)，窗口原点 (100,200) 应移动 delta(50,-20) -> (150,180)
        let origin = SelectionRect.dragOrigin(
            initialOrigin: CGPoint(x: 100, y: 200),
            initialMouse: CGPoint(x: 500, y: 600),
            currentMouse: CGPoint(x: 550, y: 580)
        )
        XCTAssertEqual(origin, CGPoint(x: 150, y: 180))
    }
}
