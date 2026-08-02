import AppKit

/// 截图覆盖层窗口：无边框、全屏、置顶、透明，承载 ScreenshotOverlayView。
final class ScreenshotOverlayWindow: NSWindow {

    var overlayView: ScreenshotOverlayView!

    /// 便捷初始化：在指定屏幕上创建全屏覆盖层。
    /// 用 convenience init 调用 designated init（无 screen 版本），
    /// 避免 NSWindow 内部 init 链触发 fatalError。
    convenience init(screen: NSScreen, capturedImage: CGImage) {
        let frame = screen.frame
        self.init(contentRect: frame, styleMask: [.borderless, .fullSizeContentView], backing: .buffered, defer: false)

        let view = ScreenshotOverlayView(capturedImage: capturedImage, frame: frame)
        self.overlayView = view
        self.level = .screenSaver
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.contentView = view
        // 确保窗口在正确屏幕上
        self.setFrame(frame, display: true)
    }

    /// Designated init：直接调用 super，避免 Swift 合成的 fatalError。
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing bufferingType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: bufferingType, defer: flag)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
