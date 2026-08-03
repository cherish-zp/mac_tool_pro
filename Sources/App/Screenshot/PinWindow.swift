import AppKit

/// 贴图窗口：将截图钉在桌面上，始终置顶、可拖动、可关闭。
/// 模拟浮光（Snipaste）的贴图功能。拖拽移动、右键或双击关闭。
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

        let imageView = PinImageView(frame: NSRect(origin: .zero, size: size))
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyDown
        imageView.autoresizingMask = [.width, .height]
        contentView = imageView

        // 右键菜单：关闭贴图
        let menu = NSMenu()
        let closeItem = menu.addItem(withTitle: "关闭贴图", action: #selector(closePin), keyEquivalent: "")
        closeItem.target = self
        imageView.menu = menu
    }

    /// 关闭贴图并通知协调器释放资源。
    @objc func closePin() {
        orderOut(nil)
        onClose?()
    }
}

/// 贴图图片视图：自定义拖拽移动 + 双击关闭。
/// NSImageView 默认 mouseDownCanMoveWindow=false 且手势识别器会干扰拖拽，
/// 故自行处理 mouseDown/mouseDragged/mouseUp。
final class PinImageView: NSImageView {

    private var dragStartMouse: NSPoint = .zero
    private var dragStartOrigin: NSPoint = .zero
    private var lastClickTime: Date = .distantPast
    private let doubleClickInterval: TimeInterval = 0.3

    override var mouseDownCanMoveWindow: Bool { false }

    override func mouseDown(with event: NSEvent) {
        // 记录拖拽起点（屏幕坐标）
        dragStartMouse = NSEvent.mouseLocation
        dragStartOrigin = window?.frame.origin ?? .zero
    }

    override func mouseDragged(with event: NSEvent) {
        let current = NSEvent.mouseLocation
        let newOrigin = SelectionRect.dragOrigin(
            initialOrigin: dragStartOrigin,
            initialMouse: dragStartMouse,
            currentMouse: current
        )
        window?.setFrameOrigin(newOrigin)
    }

    override func mouseUp(with event: NSEvent) {
        // 双击关闭贴图
        let now = Date()
        if now.timeIntervalSince(lastClickTime) < doubleClickInterval {
            (window as? PinWindow)?.closePin()
        }
        lastClickTime = now
    }
}
