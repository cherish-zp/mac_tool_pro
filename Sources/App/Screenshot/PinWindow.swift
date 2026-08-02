import AppKit

/// 贴图窗口：将截图钉在桌面上，始终置顶、可拖动、可关闭。
/// 模拟浮光（Snipaste）的贴图功能。右键或双击关闭。
final class PinWindow: NSWindow {

    /// 贴图关闭时回调（用于协调器从列表中移除、释放图片）。
    var onClose: (() -> Void)?

    init(image: NSImage, at point: CGPoint) {
        // image.size 为点尺寸（由 renderFinalImage 设置），窗口按点尺寸创建，不变形
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

        let imageView = NSImageView(frame: NSRect(origin: .zero, size: size))
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyDown
        imageView.autoresizingMask = [.width, .height]
        contentView = imageView

        // 右键菜单：关闭贴图
        let menu = NSMenu()
        let closeItem = menu.addItem(withTitle: "关闭贴图", action: #selector(closePin), keyEquivalent: "")
        closeItem.target = self
        imageView.menu = menu

        // 双击关闭贴图
        let closeGesture = NSClickGestureRecognizer(target: self, action: #selector(closeOnDouble(_:)))
        closeGesture.numberOfClicksRequired = 2
        contentView?.addGestureRecognizer(closeGesture)
    }

    @objc private func closePin() {
        orderOut(nil)
        onClose?()
    }

    @objc private func closeOnDouble(_ sender: NSClickGestureRecognizer) {
        closePin()
    }
}
