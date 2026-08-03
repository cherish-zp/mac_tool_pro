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

    // MARK: - 裁剪保留 Retina 分辨率

    func test_cropRect_preservesRetina2xResolution() {
        // 2x Retina: 1920x1080 点 -> 3840x2160 像素
        // 选区 300x400 点 -> 裁剪应为 600x800 像素
        let viewSize = CGSize(width: 1920, height: 1080)
        let imageSize = CGSize(width: 3840, height: 2160)
        let sel = CGRect(x: 100, y: 200, width: 300, height: 400)
        let cropRect = SelectionRect.scaleToPixels(sel, imageSize: imageSize, viewSize: viewSize)
        // 裁剪矩形像素尺寸 = 选区点尺寸 * 2
        XCTAssertEqual(cropRect.width, 600, accuracy: 0.001)
        XCTAssertEqual(cropRect.height, 800, accuracy: 0.001)
        // 显示尺寸（点）= 像素 / 2 = 选区尺寸
        let displaySize = SelectionRect.pointSize(pixelSize: cropRect.size, scaleFactor: 2.0)
        XCTAssertEqual(displaySize, sel.size)
        // cgImage 像素 / NSImage size 点 = Retina 缩放比（确保高清）
        XCTAssertEqual(cropRect.width / displaySize.width, 2.0, accuracy: 0.001)
        XCTAssertEqual(cropRect.height / displaySize.height, 2.0, accuracy: 0.001)
    }

    // MARK: - 贴图 CGImage 直接绘制（避免 NSImage 颜色匹配导致偏色）

    func test_cgImageFromNSImage_preservesPixelDimensions() {
        // NSImage(cgImage:size:) 创建后，提取的 CGImage 像素尺寸应与原始一致
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil, width: 600, height: 800, bitsPerComponent: 8,
                                  bytesPerRow: 0, space: cs,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let original = ctx.makeImage() else {
            XCTFail("Cannot create test CGImage")
            return
        }
        let nsImage = NSImage(cgImage: original, size: NSSize(width: 300, height: 400))
        let extracted = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        XCTAssertNotNil(extracted)
        XCTAssertEqual(extracted?.width, 600)
        XCTAssertEqual(extracted?.height, 800)
    }

    // MARK: - CGImage 裁剪 y 轴翻转（CGImage 原点左上 vs 视图原点左下）

    func test_cropRectPixels_flipsYForTopLeftOrigin() {
        // 视图 1000x800 点(左下原点)，图片 2000x1600 像素(2x, 左上原点)
        // 选区 origin(100,200) size(300,400) -> maxY=600
        // CGImage y = (800 - 600) * 2 = 400（从顶部算）
        let cropRect = SelectionRect.cropRectPixels(
            selection: CGRect(x: 100, y: 200, width: 300, height: 400),
            imageSize: CGSize(width: 2000, height: 1600),
            viewSize: CGSize(width: 1000, height: 800)
        )
        XCTAssertEqual(cropRect.origin.x, 200, accuracy: 0.001)
        XCTAssertEqual(cropRect.origin.y, 400, accuracy: 0.001)
        XCTAssertEqual(cropRect.width, 600, accuracy: 0.001)
        XCTAssertEqual(cropRect.height, 800, accuracy: 0.001)
    }

    func test_cropRectPixels_selectionAtTopOfScreen() {
        // 选区在屏幕顶部：origin.y=700 height=100, maxY=800=viewHeight
        // CGImage y = (800-800)*2 = 0（图片最顶部）
        let cropRect = SelectionRect.cropRectPixels(
            selection: CGRect(x: 0, y: 700, width: 1000, height: 100),
            imageSize: CGSize(width: 2000, height: 1600),
            viewSize: CGSize(width: 1000, height: 800)
        )
        XCTAssertEqual(cropRect.origin.y, 0, accuracy: 0.001)
    }

    func test_cropRectPixels_selectionAtBottomOfScreen() {
        // 选区在屏幕底部：origin.y=0 height=100, maxY=100
        // CGImage y = (800-100)*2 = 1400（图片最底部）
        let cropRect = SelectionRect.cropRectPixels(
            selection: CGRect(x: 0, y: 0, width: 1000, height: 100),
            imageSize: CGSize(width: 2000, height: 1600),
            viewSize: CGSize(width: 1000, height: 800)
        )
        XCTAssertEqual(cropRect.origin.y, 1400, accuracy: 0.001)
    }
}
