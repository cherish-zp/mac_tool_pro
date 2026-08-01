import AppKit

/// 截图覆盖层窗口：无边框、全屏、置顶、透明，承载 ScreenshotOverlayView。
final class ScreenshotOverlayWindow: NSWindow {

    let overlayView: ScreenshotOverlayView

    init(screen: NSScreen, capturedImage: CGImage) {
        let frame = screen.frame
        let view = ScreenshotOverlayView(capturedImage: capturedImage, frame: frame)
        self.overlayView = view

        super.init(
            contentRect: frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: screen
        )

        self.level = .screenSaver
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.contentView = view
    }

    @available(*, unavailable)
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing bufferingType: NSWindow.BackingStoreType, defer flag: Bool) {
        fatalError()
    }
}
