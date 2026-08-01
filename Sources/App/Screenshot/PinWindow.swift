import AppKit

/// 贴图窗口：将截图钉在桌面上，始终置顶、可拖动、可关闭。
/// 模拟浮光（Snipaste）的贴图功能。
final class PinWindow: NSWindow {

    init(image: NSImage, at point: CGPoint) {
        let size = image.size
        let frame = NSRect(x: point.x, y: point.y, width: size.width, height: size.height)
        super.init(
            contentRect: frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovable = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let imageView = NSImageView(frame: frame)
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyDown
        imageView.autoresizingMask = [.width, .height]
        contentView = imageView

        // 双击关闭贴图
        let closeGesture = NSClickGestureRecognizer(target: self, action: #selector(closeOnDouble(_:)))
        closeGesture.numberOfClicksRequired = 2
        contentView?.addGestureRecognizer(closeGesture)
    }

    @available(*, unavailable)
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing bufferingType: NSWindow.BackingStoreType, defer flag: Bool) {
        fatalError()
    }

    @objc private func closeOnDouble(_ sender: NSClickGestureRecognizer) {
        orderOut(nil)
    }
}
