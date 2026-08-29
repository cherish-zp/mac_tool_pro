import AppKit
import CoreGraphics

/// 可注入的剪贴板抽象，便于在测试中替换为 spy。
public protocol Pasteboard: AnyObject {
    func copy(_ string: String)
    /// 写入图片：pointSize 为逻辑点尺寸（与工具条 renderFinalImage 的 sel.size 同口径），
    /// 剪贴板内保留全分辨率像素、DPI 按点尺寸标注。
    func copyImage(_ image: CGImage, pointSize: NSSize)
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
    /// CGImage 按 pointSize 包装为 NSImage（同工具条 NSImage(cgImage:size: sel.size) 的点尺寸口径），
    /// 保证剪贴板里是全分辨率像素、粘贴出的逻辑尺寸与工具条复制一致。
    public func copyImage(_ image: CGImage, pointSize: NSSize) {
        pasteboard.clearContents()
        let nsImage = NSImage(cgImage: image, size: pointSize)
        pasteboard.writeObjects([nsImage])
    }
}
