import AppKit

/// 贴图窗口：将截图钉在桌面上，始终置顶、可拖动、可关闭。
/// 直接使用原始 CGImage 绘制，避免 NSImage 转换导致色差/模糊。
/// 左上角有亮绿色关闭按钮，悬停变红并显示X，点击关闭。
final class PinWindow: NSWindow {

    /// 贴图关闭时回调（用于协调器从列表中移除、释放图片）。
    var onClose: (() -> Void)?

    init(cgImage: CGImage, displaySize: NSSize, at point: CGPoint) {
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
        imageView.setOriginalSize(displaySize)
        imageView.autoresizingMask = [.width, .height]
        contentView = imageView

        // 左上角关闭按钮
        let closeButton = PinCloseButton()
        closeButton.onTap = { [weak self] in self?.closePin() }
        imageView.addCloseButton(closeButton)

        DiagLog.write("PinWindow: pts=\(displaySize) pixels=\(cgImage.width)x\(cgImage.height) backingScale=\(self.backingScaleFactor)")
    }

    /// 关闭贴图并通知协调器释放资源。
    @objc func closePin() {
        orderOut(nil)
        onClose?()
    }
}

/// 贴图视图：直接用 CGContext.draw 绘制原始 CGImage，与覆盖层渲染方式一致。
/// 处理拖拽移动 + 双击关闭。左上角有关闭按钮（悬停变红+X）。
final class PinImageView: NSView {

    var cgImage: CGImage?
    private var closeButton: PinCloseButton?
    private var originalSize: CGSize = .zero
    private var currentScale: CGFloat = 1.0

    private var dragStartMouse: NSPoint = .zero
    private var dragStartOrigin: NSPoint = .zero
    private var lastClickTime: Date = .distantPast
    private let doubleClickInterval: TimeInterval = 0.3

    /// 设置原始尺寸（初始化时调用），用于缩放基准。
    func setOriginalSize(_ size: CGSize) {
        originalSize = size
    }

    override var mouseDownCanMoveWindow: Bool { false }
    override var isFlipped: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext, let cg = cgImage else { return }
        ctx.draw(cg, in: bounds)
    }

    /// 添加关闭按钮到左上角。
    func addCloseButton(_ button: PinCloseButton) {
        closeButton = button
        button.autoresizingMask = []
        addSubview(button)
        updateCloseButtonFrame()
    }

    /// 根据当前缩放比例更新关闭按钮的位置和大小。
    func updateCloseButtonFrame() {
        guard let btn = closeButton else { return }
        btn.frame = PinScaler.scaledButtonFrame(viewBounds: bounds, scaleFactor: currentScale)
        btn.needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        // 点击关闭按钮时不触发拖拽
        let point = convert(event.locationInWindow, from: nil)
        if let btn = closeButton, btn.frame.contains(point) { return }
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
        let point = convert(event.locationInWindow, from: nil)
        if let btn = closeButton, btn.frame.contains(point) { return }
        let now = Date()
        if now.timeIntervalSince(lastClickTime) < doubleClickInterval {
            (window as? PinWindow)?.closePin()
        }
        lastClickTime = now
    }

    /// 滚轮缩放：上滚放大、下滚缩小，等比例缩放，保持窗口中心不变。
    override func scrollWheel(with event: NSEvent) {
        let delta = event.deltaY
        guard abs(delta) > 0.01 else { return }
        let scaleDelta = 1.0 + delta * 0.1
        currentScale = PinScaler.clampedScaleFactor(currentScale * scaleDelta)
        guard let win = window, originalSize.width > 0 else { return }
        let newSize = PinScaler.scaledSize(original: originalSize, scaleFactor: currentScale)
        let newFrame = PinScaler.scaledFrame(originalFrame: win.frame, newSize: newSize)
        win.setFrame(newFrame, display: true)
        updateCloseButtonFrame()
    }
}

/// 贴图关闭按钮：左上角亮绿色圆形按钮，悬停变红并显示X，点击关闭。
final class PinCloseButton: NSView {

    var onTap: (() -> Void)?
    private var state = PinCloseButtonState()
    private let buttonSize: CGFloat = 22
    private var blinkTimer: Timer?

    override var isFlipped: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            startBlinking()
        } else {
            stopBlinking()
        }
    }

    private func startBlinking() {
        stopBlinking()
        blinkTimer = Timer.scheduledTimer(
            withTimeInterval: PinCloseButtonState.blinkInterval, repeats: true
        ) { [weak self] _ in
            guard let self = self else { return }
            self.state.onBlinkTick()
            self.needsDisplay = true
        }
    }

    private func stopBlinking() {
        blinkTimer?.invalidate()
        blinkTimer = nil
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
    }

    override func mouseEntered(with event: NSEvent) {
        state.onHoverEnter()
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        state.onHoverExit()
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        onTap?()
    }

    override func draw(_ dirtyRect: NSRect) {
        guard state.isVisible else { return }
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let rect = bounds.insetBy(dx: 1, dy: 1)
        // 圆形背景
        let bgColor: NSColor = state.color == .red
            ? NSColor(calibratedRed: 1.0, green: 0.23, blue: 0.19, alpha: 0.95)
            : NSColor(calibratedRed: 0.30, green: 0.85, blue: 0.31, alpha: 0.90)
        ctx.setFillColor(bgColor.cgColor)
        ctx.fillEllipse(in: rect)

        // 悬停时显示白色X
        if state.showsX {
            let center = NSPoint(x: bounds.midX, y: bounds.midY)
            let r: CGFloat = 4
            ctx.setStrokeColor(NSColor.white.cgColor)
            ctx.setLineWidth(2)
            ctx.setLineCap(.round)
            ctx.move(to: NSPoint(x: center.x - r, y: center.y - r))
            ctx.addLine(to: NSPoint(x: center.x + r, y: center.y + r))
            ctx.move(to: NSPoint(x: center.x + r, y: center.y - r))
            ctx.addLine(to: NSPoint(x: center.x - r, y: center.y + r))
            ctx.strokePath()
        }
    }

    override func cursorUpdate(with event: NSEvent) {
        NSCursor.arrow.set()
    }
}
