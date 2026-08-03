import AppKit

/// 贴图窗口：将截图钉在桌面上，始终置顶、可拖动、可关闭。
/// 直接使用原始 CGImage 绘制，避免 NSImage 转换导致色差/模糊。
final class PinWindow: NSWindow {

    /// 贴图关闭时回调（用于协调器从列表中移除、释放图片）。
    var onClose: (() -> Void)?

    init(cgImage: CGImage, displaySize: NSSize, at point: CGPoint) {
        // displaySize 为点尺寸，窗口按点尺寸创建
        let frame = NSRect(x: point.x, y: point.y, width: displaySize.width, height: displaySize.height)
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

        let imageView = PinImageView(frame: NSRect(origin: .zero, size: displaySize))
        imageView.cgImage = cgImage
        imageView.autoresizingMask = [.width, .height]
        contentView = imageView

        // 右键菜单：关闭贴图
        let menu = NSMenu()
        let closeItem = menu.addItem(withTitle: "关闭贴图", action: #selector(closePin), keyEquivalent: "")
        closeItem.target = self
        imageView.menu = menu

        DiagLog.write("PinWindow: pts=\(displaySize) pixels=\(cgImage.width)x\(cgImage.height) backingScale=\(self.backingScaleFactor)")
    }

    /// 关闭贴图并通知协调器释放资源。
    @objc func closePin() {
        orderOut(nil)
        onClose?()
    }
}

/// 贴图视图：直接用 CGContext.draw 绘制原始 CGImage，与覆盖层渲染方式一致，颜色/清晰度一致。
/// 同时处理拖拽移动 + 双击关闭。
final class PinImageView: NSView {

    var cgImage: CGImage?

    private var dragStartMouse: NSPoint = .zero
    private var dragStartOrigin: NSPoint = .zero
    private var lastClickTime: Date = .distantPast
    private let doubleClickInterval: TimeInterval = 0.3

    override var mouseDownCanMoveWindow: Bool { false }
    override var isFlipped: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext, let cg = cgImage else { return }
        // 与覆盖层完全一致的绘制方式：ctx.draw(cgImage, in: bounds)
        ctx.draw(cg, in: bounds)
    }

    override func mouseDown(with event: NSEvent) {
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
        let now = Date()
        if now.timeIntervalSince(lastClickTime) < doubleClickInterval {
            (window as? PinWindow)?.closePin()
        }
        lastClickTime = now
    }
}
