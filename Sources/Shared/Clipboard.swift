import AppKit
import CoreGraphics

/// 可注入的剪贴板抽象，便于在测试中替换为 spy。
public protocol Pasteboard: AnyObject {
    func copy(_ string: String)
    func copyImage(_ image: CGImage)
}

/// 生产实现：写入指定剪贴板（默认 NSPasteboard.general）。
public final class SystemPasteboard: Pasteboard {
    private let pasteboard: NSPasteboard

    public init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    public func copy(_ string: String) {
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }

    /// 写入图片（与 ScreenshotCoordinator.copyToClipboard 行为一致：clearContents + writeObjects）。
    /// CGImage 包装为点尺寸 = 像素尺寸（72dpi）的 NSImage，保证剪贴板里是全分辨率像素。
    public func copyImage(_ image: CGImage) {
        pasteboard.clearContents()
        let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
        pasteboard.writeObjects([nsImage])
    }
}
