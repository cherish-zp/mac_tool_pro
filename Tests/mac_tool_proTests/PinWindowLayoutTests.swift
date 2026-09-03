import XCTest
import AppKit
import CoreGraphics

/// TDD: 贴图窗口缩放回归 - 图片视图必须跟随窗口尺寸变化（边距恒定），
/// 否则滚轮缩放时窗口以中心缩放、图片却锚死左上角，内容会"到处滑动"。
final class PinWindowLayoutTests: XCTestCase {

    private func tinyImage() -> CGImage? {
        let ctx = CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                            space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        ctx?.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        ctx?.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        return ctx?.makeImage()
    }

    private func makePinWindow(displaySize: NSSize) -> PinWindow? {
        guard let cg = tinyImage() else { return nil }
        let pin = PinWindow(cgImage: cg, displaySize: displaySize,
                            at: CGPoint(x: 200, y: 200), cornerRadius: 0)
        pin.contentView?.layoutSubtreeIfNeeded()
        return pin
    }

    private func imageView(of pin: PinWindow) -> NSView? {
        (pin.contentView as? PinWindowContentView)?.imageView
    }

    func test_initialLayout_imageViewFillsContentMinusMargins() throws {
        let size = NSSize(width: 200, height: 100)
        let pin = try XCTUnwrap(makePinWindow(displaySize: size))
        let margin = PinImageView.shadowMargin
        let iv = try XCTUnwrap(imageView(of: pin))

        XCTAssertEqual(iv.frame.minX, margin, accuracy: 0.5)
        XCTAssertEqual(iv.frame.minY, margin, accuracy: 0.5)
        XCTAssertEqual(iv.frame.width, size.width, accuracy: 0.5)
        XCTAssertEqual(iv.frame.height, size.height, accuracy: 0.5)
    }

    func test_imageViewTracksWindowSize_whenWindowScales() throws {
        let size = NSSize(width: 200, height: 100)
        let pin = try XCTUnwrap(makePinWindow(displaySize: size))
        let margin = PinImageView.shadowMargin
        let iv = try XCTUnwrap(imageView(of: pin))

        // 模拟滚轮缩放后窗口 frame 变化（放大 60x30）
        pin.setContentSize(NSSize(width: size.width + margin * 2 + 60,
                                  height: size.height + margin * 2 + 30))
        pin.contentView?.layoutSubtreeIfNeeded()

        XCTAssertEqual(iv.frame.width, size.width + 60, accuracy: 0.5,
                       "图片视图必须跟随窗口缩放，否则贴图内容到处滑动")
        XCTAssertEqual(iv.frame.height, size.height + 30, accuracy: 0.5)
        XCTAssertEqual(iv.frame.minX, margin, accuracy: 0.5, "阴影边距必须保持恒定")
        XCTAssertEqual(iv.frame.minY, margin, accuracy: 0.5)
    }
}
