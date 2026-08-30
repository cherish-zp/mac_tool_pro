import AppKit

/// 贴图窗口：将截图钉在桌面上，始终置顶、可拖动、可关闭。
/// 直接使用原始 CGImage 绘制，避免 NSImage 转换导致色差/模糊。
/// 呼吸灯样式可配置（横条/圆点），横条的高度/距顶部间距/颜色均可在设置中调整，
/// 设置变更立即生效。
final class PinWindow: NSWindow {

    /// 贴图关闭时回调（用于协调器从列表中移除、释放图片）。
    var onClose: (() -> Void)?

    private var styleObserver: NSObjectProtocol?

    init(cgImage: CGImage, displaySize: NSSize, at point: CGPoint, cornerRadius: CGFloat = 0) {
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
        imageView.baseCornerRadius = cornerRadius
        imageView.setOriginalSize(displaySize)
        imageView.autoresizingMask = [.width, .height]
        contentView = imageView

        // 左上角关闭按钮
        let closeButton = PinCloseButton()
        closeButton.onTap = { [weak self] in self?.closePin() }
        imageView.addCloseButton(closeButton)

        // 呼吸灯样式与外观：读取设置（默认顶部横条，高 4pt、距顶 2pt、绿色）
        imageView.applyIndicatorSettings(PinSettingsStore.defaultStore().load())

        // 右键菜单：复制图片（复制动作走注入的 Pasteboard 抽象；
        // pointSize 取贴图原始点尺寸（未缩放），与工具条复制的逻辑尺寸口径一致）
        imageView.addContextMenu(PinContextMenu(
            pasteboard: SystemPasteboard(),
            imageProvider: { [weak imageView] in imageView?.cgImage },
            pointSizeProvider: { [weak imageView] in imageView?.originalSize ?? .zero }
        ))

        // 设置变更立即生效于已打开的贴图
        styleObserver = NotificationCenter.default.addObserver(
            forName: .pinIndicatorStyleDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self = self, let imageView = self.contentView as? PinImageView else { return }
            imageView.applyIndicatorSettings(PinSettingsStore.defaultStore().load())
        }

        DiagLog.write("PinWindow: pts=\(displaySize) pixels=\(cgImage.width)x\(cgImage.height) backingScale=\(self.backingScaleFactor)")
    }

    deinit {
        if let observer = styleObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// 关闭贴图并通知协调器释放资源。
    @objc func closePin() {
        orderOut(nil)
        onClose?()
    }
}

/// 贴图视图：直接用 CGContext.draw 绘制原始 CGImage，与覆盖层渲染方式一致。
/// 处理拖拽移动 + 双击关闭。管理呼吸灯样式（横条/圆点）与关闭按钮。
final class PinImageView: NSView {

    var cgImage: CGImage?
    /// 贴图基础圆角半径（点，未缩放时口径），用于呼吸灯贴合图片圆角；0 表示直角。
    var baseCornerRadius: CGFloat = 0
    private var closeButton: PinCloseButton?
    private var indicatorBar: PinIndicatorBar?
    private var hoverTrackingArea: NSTrackingArea?
    /// 贴图原始点尺寸（创建时传入的 displaySize，未随滚轮缩放变化），
    /// 供右键复制携带与工具条一致的点尺寸口径。
    private(set) var originalSize: CGSize = .zero
    private var currentScale: CGFloat = 1.0

    private var dragStartMouse: NSPoint = .zero
    private var dragStartOrigin: NSPoint = .zero
    private var lastClickTime: Date = .distantPast
    private let doubleClickInterval: TimeInterval = 0.3
    private var contextMenuController: PinContextMenu?

    /// 挂接右键菜单控制器（窗口创建时注入，复制动作经 Pasteboard 抽象执行）。
    func addContextMenu(_ controller: PinContextMenu) {
        contextMenuController = controller
    }

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

    /// 按设置应用呼吸灯：样式（横条/圆点）+ 横条外观（高度/距顶部间距/颜色）。
    /// 可重复调用（初始化与设置变更通知共用）。
    func applyIndicatorSettings(_ settings: PinSettingsState) {
        closeButton?.setMode(PinCloseButtonState.Mode(settings.indicatorStyle))
        updateCloseButtonFrame()
        if settings.indicatorStyle == .topBar {
            if indicatorBar == nil {
                let bar = PinIndicatorBar()
                addSubview(bar)
                indicatorBar = bar
            }
            indicatorBar?.barHeight = settings.indicatorHeight
            indicatorBar?.topInset = settings.indicatorTopInset
            indicatorBar?.color = PinIndicatorColor.color(fromHex: settings.indicatorColorHex)
                ?? PinIndicatorColor.color(fromHex: PinIndicatorColor.defaultHex)!
            indicatorBar?.silhouetteRadius = baseCornerRadius * currentScale
            updateIndicatorBarFrame()
        } else {
            indicatorBar?.removeFromSuperview()
            indicatorBar = nil
        }
    }

    /// 添加关闭按钮到左上角。
    func addCloseButton(_ button: PinCloseButton) {
        closeButton = button
        button.autoresizingMask = []
        addSubview(button)
        updateCloseButtonFrame()
    }

    /// 根据当前缩放比例与模式更新关闭按钮的位置和大小。
    /// 圆点模式用常规尺寸系（22pt），横条模式用减半的浮现按钮尺寸系。
    func updateCloseButtonFrame() {
        guard let btn = closeButton else { return }
        switch btn.mode {
        case .cornerDot:
            btn.frame = PinScaler.scaledButtonFrame(viewBounds: bounds, scaleFactor: currentScale)
        case .topBar:
            btn.frame = PinScaler.scaledRevealButtonFrame(viewBounds: bounds, scaleFactor: currentScale)
        }
        btn.needsDisplay = true
    }

    /// 顶部横条 frame：高度与距顶间距来自设置（视图原点左下，顶部 = maxY）。
    private func updateIndicatorBarFrame() {
        guard let bar = indicatorBar else { return }
        bar.frame = NSRect(x: 0,
                           y: bounds.height - bar.topInset - bar.barHeight,
                           width: bounds.width,
                           height: bar.barHeight)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let area = hoverTrackingArea { removeTrackingArea(area) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        hoverTrackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        closeButton?.setImageHovered(true)
    }

    override func mouseExited(with event: NSEvent) {
        closeButton?.setImageHovered(false)
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

    /// 右键弹出贴图菜单；NSView 的 rightMouseDown 独立于左键 mouseDown/mouseUp 事件流，
    /// 不影响拖拽与双击关闭。
    override func rightMouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        contextMenuController?.popUp(at: point, in: self)
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
        indicatorBar?.silhouetteRadius = baseCornerRadius * currentScale
    }
}

/// 顶部呼吸横条：胶囊形浮动条，距贴图顶部间距与高度、颜色均来自设置。
/// 用 Core Animation 透明度渐变实现渐亮渐暗，无需定时器重绘。
/// 两端除胶囊圆角外再经「贴图轮廓（圆角矩形）」裁剪，保证不越过贴图圆角外的透明区域。
final class PinIndicatorBar: NSView {

    /// 横条高度（点），来自设置。
    var barHeight: CGFloat = PinIndicatorAppearance.defaultHeight {
        didSet { needsDisplay = true }
    }
    /// 距贴图顶部间距（点），同时用于轮廓裁剪定位。
    var topInset: CGFloat = PinIndicatorAppearance.defaultTopInset
    /// 横条颜色，来自设置色板。
    var color: NSColor = PinIndicatorColor.color(fromHex: PinIndicatorColor.defaultHex)! {
        didSet { needsDisplay = true }
    }
    /// 贴图当前圆角半径（点，= baseRadius × currentScale），0 表示直角贴图。
    var silhouetteRadius: CGFloat = 0 {
        didSet { needsDisplay = true }
    }

    override var isFlipped: Bool { true }

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        autoresizingMask = [.width, .minYMargin]
    }

    required init?(coder: NSCoder) { fatalError("unsupported") }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            startBreathing()
        } else {
            layer?.removeAnimation(forKey: "breathing")
        }
    }

    /// 渐亮（1.2s）→ 渐暗（1.2s）循环，缓入缓出。
    private func startBreathing() {
        let anim = CABasicAnimation(keyPath: "opacity")
        anim.fromValue = 0.15
        anim.toValue = 1.0
        anim.duration = 1.2
        anim.autoreverses = true
        anim.repeatCount = .infinity
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer?.add(anim, forKey: "breathing")
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        // 贴图轮廓裁剪：圆角矩形顶边在横条顶边上方 topInset 处（横条自身坐标系 y 向下）
        if silhouetteRadius > 0 {
            let silhouette = NSRect(x: 0, y: -topInset, width: bounds.width,
                                    height: bounds.height + topInset + silhouetteRadius + 8)
            ctx.addPath(CGPath(roundedRect: silhouette, cornerWidth: silhouetteRadius,
                               cornerHeight: silhouetteRadius, transform: nil))
            ctx.clip()
        }
        // 胶囊形状（圆角 = 高度一半）
        let capsule = CGPath(roundedRect: bounds, cornerWidth: bounds.height / 2,
                             cornerHeight: bounds.height / 2, transform: nil)
        ctx.addPath(capsule)
        ctx.clip()
        ctx.setFillColor(color.cgColor)
        ctx.fill(bounds)
    }

    override func cursorUpdate(with event: NSEvent) {
        NSCursor.arrow.set()
    }
}

/// 贴图关闭按钮：左上角圆形按钮，点击关闭。
/// 圆点模式：亮绿色闪烁，悬停变红并显示X；横条模式：悬停贴图时淡入红色X。
final class PinCloseButton: NSView {

    var onTap: (() -> Void)?
    private var state = PinCloseButtonState()
    private let buttonSize: CGFloat = 22
    private var blinkTimer: Timer?

    override var isFlipped: Bool { true }

    /// 当前指示样式模式（圆点/横条），供按模式选按钮尺寸系。
    var mode: PinCloseButtonState.Mode { state.mode }

    /// 切换指示样式模式（横条/圆点），重置可见性与闪烁。
    func setMode(_ mode: PinCloseButtonState.Mode) {
        state.setMode(mode)
        updateBlinking()
        applyVisibility()
    }

    /// 横条模式：由贴图悬停状态驱动浮现/隐藏；圆点模式下忽略。
    func setImageHovered(_ hovered: Bool) {
        guard state.mode == .topBar else { return }
        hovered ? state.onImageHoverEnter() : state.onImageHoverExit()
        applyVisibility()
    }

    private func updateBlinking() {
        if state.mode == .cornerDot && window != nil {
            startBlinking()
        } else {
            stopBlinking()
        }
    }

    /// 可见性淡入淡出（横条模式浮现/隐藏，0.15s）。
    private func applyVisibility() {
        let target: CGFloat = state.isVisible ? 1 : 0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animator().alphaValue = target
        }
        needsDisplay = true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateBlinking()
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
        guard state.mode == .cornerDot else { return }
        state.onHoverEnter()
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        guard state.mode == .cornerDot else { return }
        state.onHoverExit()
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        // 横条模式隐藏时不拦截点击（交给贴图拖拽）
        if state.mode == .topBar && !state.isVisible { return }
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

        // 悬停时显示白色X（随按钮尺寸等比：22pt 时 r≈4、线宽≈2，与原视觉一致）
        if state.showsX {
            let center = NSPoint(x: bounds.midX, y: bounds.midY)
            let r = bounds.width * 0.18
            ctx.setStrokeColor(NSColor.white.cgColor)
            ctx.setLineWidth(Swift.max(1.5, bounds.width * 0.09))
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
