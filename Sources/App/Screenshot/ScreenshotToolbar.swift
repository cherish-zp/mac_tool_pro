import AppKit

/// 截图工具条代理：工具条按钮事件回调。
protocol ScreenshotToolbarDelegate: AnyObject {
    func toolbarDidSelect(tool: AnnotationType?)
    func toolbarDidSelectColor(_ color: AnnotationColor)
    func toolbarDidToggleCornerRadius()
    func toolbarDidUndo()
    func toolbarDidCopy()
    func toolbarDidSave()
    func toolbarDidPin()
    func toolbarDidCancel()
    func toolbarDidScroll()
}

/// 浮动截图工具条：标注工具 + 颜色 + 操作按钮（复制/保存/贴图/取消）。
final class ScreenshotToolbar: NSWindow {

    weak var toolbarDelegate: ScreenshotToolbarDelegate?
    private var toolButtons: [AnnotationType?: NSButton] = [:]
    private var cornerButton: NSButton?
    private var paletteButton: NSButton?
    private var colorPanel: NSPanel?
    private var undoButton: NSButton?
    private(set) var selectedColor: AnnotationColor = .red

    init() {
        let frame = NSRect(x: 0, y: 0, width: 690, height: 44)
        super.init(
            contentRect: frame,
            styleMask: [.borderless, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        // 工具条层级高于覆盖层(screenSaver)，防止用户点覆盖层画图时覆盖层置顶遮住工具条
        self.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 2)
        self.isOpaque = false
        self.backgroundColor = NSColor(calibratedRed: 0.16, green: 0.16, blue: 0.18, alpha: 0.96)
        self.hasShadow = true
        self.isMovable = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.acceptsMouseMovedEvents = true

        buildUI()
    }


    private func buildUI() {
        let container = ToolbarContainerView(frame: contentView!.bounds)
        container.wantsLayer = true
        container.autoresizingMask = [.width, .height]
        contentView = container

        var x: CGFloat = 8
        let y: CGFloat = 8
        let btnSize: CGFloat = 28

        // 选择工具（无标注）
        x = addToolButton(container, x: x, y: y, size: btnSize, tool: nil, symbol: "cursorarrow")

        // 标注工具
        x = addToolButton(container, x: x + 4, y: y, size: btnSize, tool: .rectangle, symbol: "square")
        x = addToolButton(container, x: x + 4, y: y, size: btnSize, tool: .arrow, symbol: "arrow.up.right")
        x = addToolButton(container, x: x + 4, y: y, size: btnSize, tool: .text, symbol: "textformat")
        x = addToolButton(container, x: x + 4, y: y, size: btnSize, tool: .mosaic, symbol: "square.dashed")

        // 圆角按钮（切换选区圆角半径）
        let cb = NSButton(frame: NSRect(x: x + 6, y: y, width: 40, height: btnSize))
        cb.wantsLayer = true
        cb.layer?.cornerRadius = 6
        cb.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.08).cgColor
        cb.isBordered = false
        cb.attributedTitle = NSAttributedString(string: "圆角", attributes: [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.white
        ])
        cb.target = self
        cb.action = #selector(cornerTapped)
        container.addSubview(cb)
       cornerButton = cb
       x += 6 + 40

        // 撤销按钮（撤销最后一个标注）
        let ub = NSButton(frame: NSRect(x: x + 4, y: y, width: btnSize, height: btnSize))
        ub.image = NSImage(systemSymbolName: "arrow.uturn.backward", accessibilityDescription: "撤销")
        ub.image?.isTemplate = true
        ub.contentTintColor = .white
        ub.isBordered = false
        ub.wantsLayer = true
        ub.layer?.cornerRadius = 6
        ub.title = ""
        ub.target = self
        ub.action = #selector(undoTapped)
        container.addSubview(ub)
        container.registerTooltipButton(ub, text: "撤销")
        undoButton = ub
        updateUndoButton(canUndo: false)
        x += 4 + btnSize

        // 分隔线
        x += 8
        let sep = NSBox(frame: NSRect(x: x, y: 6, width: 1, height: 32))
        sep.boxType = .separator
        container.addSubview(sep)
        x += 8

        // 主题颜色按钮：点击弹出颜色选择面板（预设色 + 自定义）
        let pBtn = NSButton(frame: NSRect(x: x, y: y, width: 28, height: 28))
        pBtn.image = NSImage(systemSymbolName: "paintpalette", accessibilityDescription: "主题")
        pBtn.image?.isTemplate = true
        pBtn.contentTintColor = .white
        pBtn.isBordered = false
        pBtn.wantsLayer = true
        pBtn.layer?.cornerRadius = 6
        pBtn.layer?.borderWidth = 1
        pBtn.layer?.borderColor = NSColor.black.withAlphaComponent(0.3).cgColor
        pBtn.toolTip = "主题"
        pBtn.target = self
        pBtn.action = #selector(paletteTapped)
        container.addSubview(pBtn)
        container.registerTooltipButton(pBtn, text: "主题")
        paletteButton = pBtn
        x += 28
        selectColor(.red)

        // 分隔线
        x += 4
        let sep2 = NSBox(frame: NSRect(x: x, y: 6, width: 1, height: 32))
        sep2.boxType = .separator
        container.addSubview(sep2)
        x += 8

        // 操作按钮
        x = addIconButton(container, x: x, y: y, symbol: "arrow.down.to.line", tooltip: "长截图", action: #selector(scrollTapped), bgColor: .systemPurple)
        x = addIconButton(container, x: x + 4, y: y, symbol: "arrow.down", tooltip: "下载", action: #selector(saveTapped), bgColor: .systemGreen)
        x = addIconButton(container, x: x + 4, y: y, symbol: "pin", tooltip: "贴图", action: #selector(pinTapped), bgColor: .systemOrange)
        x = addIconButton(container, x: x + 4, y: y, symbol: "xmark", tooltip: "关闭", action: #selector(cancelTapped), bgColor: .systemRed)

        // 对勾按钮：复制到剪贴板（最常用，放最后方便点击）
        x = addIconButton(container, x: x + 6, y: y, symbol: "checkmark", tooltip: "复制", action: #selector(copyTapped), bgColor: .systemBlue)
    }

    private func addToolButton(_ container: NSView, x: CGFloat, y: CGFloat, size: CGFloat,
                               tool: AnnotationType?, symbol: String) -> CGFloat {
        let btn = NSButton(frame: NSRect(x: x, y: y, width: size, height: size))
        btn.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        btn.image?.isTemplate = true
        btn.contentTintColor = .white
        btn.isBordered = false
        btn.wantsLayer = true
        btn.layer?.cornerRadius = 6
        btn.target = self
        btn.action = #selector(toolSelected(_:))
        btn.tag = toolTag(tool)
        container.addSubview(btn)
        toolButtons[tool] = btn
        selectTool(tool)
        return x + size
    }

    /// 图标按钮（下载/复制等）：无边框图标 + 背景色 + 悬停提示注册。
    private func addIconButton(_ container: ToolbarContainerView, x: CGFloat, y: CGFloat,
                                symbol: String, tooltip: String, action: Selector,
                                bgColor: NSColor) -> CGFloat {
        let btn = NSButton(frame: NSRect(x: x, y: y, width: 28, height: 28))
        btn.image = NSImage(systemSymbolName: symbol, accessibilityDescription: tooltip)
        btn.image?.isTemplate = true
        btn.contentTintColor = .white
        btn.isBordered = false
        btn.wantsLayer = true
        btn.layer?.cornerRadius = 6
        btn.layer?.backgroundColor = bgColor.cgColor
        btn.toolTip = tooltip
        btn.target = self
        btn.action = action
        container.addSubview(btn)
        container.registerTooltipButton(btn, text: tooltip)
        return x + 28
    }

    // MARK: 动作

    @objc private func toolSelected(_ sender: NSButton) {
        let tool = toolFromTag(sender.tag)
        selectTool(tool)
        DiagLog.write("Toolbar.toolSelected: tool=\(String(describing: tool)) tag=\(sender.tag)")
        toolbarDelegate?.toolbarDidSelect(tool: tool)
    }

    @objc private func paletteTapped() {
        if colorPanel != nil { closeColorPanel(); return }
        showColorPanel()
    }

    private func showColorPanel() {
        let swatchSize: CGFloat = 28
        let spacing: CGFloat = 6
        let count = CGFloat(AnnotationColor.presets.count)
        let panelWidth = count * swatchSize + (count - 1) * spacing + 16
        let panelHeight: CGFloat = 68
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = NSColor(white: 0.16, alpha: 0.96)
        panel.hasShadow = true
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 3)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovable = false
        panel.acceptsMouseMovedEvents = true

        let content = NSView(frame: panel.contentView!.bounds)
        content.wantsLayer = true
        panel.contentView = content

        var sx: CGFloat = 8
        let sy: CGFloat = 34
        for color in AnnotationColor.presets {
            let swatch = NSButton(frame: NSRect(x: sx, y: sy, width: swatchSize, height: swatchSize))
            swatch.title = ""
            swatch.image = nil
            swatch.wantsLayer = true
            swatch.layer?.cornerRadius = swatchSize / 2
            swatch.layer?.backgroundColor = nsColor(color).cgColor
            swatch.isBordered = false
            swatch.tag = AnnotationColor.presets.firstIndex(of: color)! + 200
            swatch.target = self
            swatch.action = #selector(presetColorSelected(_:))
            content.addSubview(swatch)
            sx += swatchSize + spacing
        }

        let customBtn = NSButton(frame: NSRect(x: 8, y: 6, width: panelWidth - 16, height: 22))
        customBtn.title = ""
        customBtn.isBordered = false
        customBtn.attributedTitle = NSAttributedString(string: "自定义…", attributes: [
            .font: NSFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white
        ])
        customBtn.alignment = .center
        customBtn.target = self
        customBtn.action = #selector(customColorTapped)
        content.addSubview(customBtn)

        if let btn = paletteButton, let btnWin = btn.window {
            let btnInWin = btn.superview?.convert(btn.frame, to: nil) ?? btn.frame
            let origin = btnWin.frame.origin
            let btnScreen = btnInWin.offsetBy(dx: origin.x, dy: origin.y)
            let screenFrame = btnWin.screen?.frame ?? NSScreen.main?.frame ?? .zero
            var px = btnScreen.midX - panelWidth / 2
            var py = btnScreen.minY - panelHeight - 6
            if px < screenFrame.minX { px = screenFrame.minX }
            if px + panelWidth > screenFrame.maxX { px = screenFrame.maxX - panelWidth }
            if py < screenFrame.minY { py = btnScreen.maxY + 6 }
            panel.setFrameOrigin(NSPoint(x: px, y: py))
        }

        panel.orderFrontRegardless()
        colorPanel = panel
        updatePaletteSelection()
    }

    @objc private func presetColorSelected(_ sender: NSButton) {
        let idx = sender.tag - 200
        guard AnnotationColor.presets.indices.contains(idx) else { return }
        let color = AnnotationColor.presets[idx]
        selectColor(color)
        DiagLog.write("Toolbar.presetColorSelected: color=\(color)")
        toolbarDelegate?.toolbarDidSelectColor(color)
        closeColorPanel()
    }

    @objc private func customColorTapped() {
        closeColorPanel()
        let cp = NSColorPanel.shared
        cp.showsAlpha = false
        // 层级必须高于全屏截图覆盖层（screenSaver），否则颜色面板被遮挡看不到
        cp.level = NSWindow.Level(rawValue: ColorPanelPositioner.panelLevelRaw(
            overlayLevelRaw: NSWindow.Level.screenSaver.rawValue))
        NotificationCenter.default.addObserver(
            self, selector: #selector(colorPanelChanged),
            name: NSColorPanel.colorDidChangeNotification, object: cp)
        // 先定位再显示，避免系统重置位置
        positionColorPanel(cp)
        cp.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        // 显示后再定位一次，确保位置不被系统覆盖
        positionColorPanel(cp)
        DispatchQueue.main.async { [weak self] in
            self?.positionColorPanel(cp)
        }
    }

    private func positionColorPanel(_ cp: NSColorPanel) {
        guard let btn = paletteButton, let btnWin = btn.window else { return }
        let btnInWin = btn.superview?.convert(btn.frame, to: nil) ?? btn.frame
        let origin = btnWin.frame.origin
        let btnScreen = btnInWin.offsetBy(dx: origin.x, dy: origin.y)
        let screen = btnWin.screen ?? NSScreen.main ?? NSScreen.screens.first
        let screenFrame = screen?.frame ?? .zero
        let pos = ColorPanelPositioner.origin(
            buttonScreenFrame: btnScreen, screenFrame: screenFrame, panelSize: cp.frame.size)
        cp.setFrameOrigin(pos)
    }

    @objc private func colorPanelChanged() {
        let cp = NSColorPanel.shared
        let c = cp.color.usingColorSpace(.sRGB) ?? cp.color
        let custom = AnnotationColor.custom(red: c.redComponent, green: c.greenComponent, blue: c.blueComponent)
        selectColor(custom)
        DiagLog.write("Toolbar.colorPanelChanged: custom color selected")
        toolbarDelegate?.toolbarDidSelectColor(custom)
    }

    func closeColorPanel() {
        colorPanel?.orderOut(nil)
        colorPanel = nil
    }

    func cleanupColorPanel() {
        closeColorPanel()
        NotificationCenter.default.removeObserver(
            self, name: NSColorPanel.colorDidChangeNotification, object: NSColorPanel.shared)
        NSColorPanel.shared.close()
    }

    @objc private func copyTapped() { toolbarDelegate?.toolbarDidCopy() }
    @objc private func saveTapped() { toolbarDelegate?.toolbarDidSave() }
    @objc private func pinTapped() { toolbarDelegate?.toolbarDidPin() }
    @objc private func cancelTapped() { toolbarDelegate?.toolbarDidCancel() }
    @objc private func scrollTapped() { toolbarDelegate?.toolbarDidScroll() }
    @objc private func cornerTapped() { toolbarDelegate?.toolbarDidToggleCornerRadius() }
    @objc private func undoTapped() { toolbarDelegate?.toolbarDidUndo() }

    // MARK: 工具状态

    func selectTool(_ tool: AnnotationType?) {
        for (t, btn) in toolButtons {
            btn.layer?.backgroundColor = (t == tool)
                ? NSColor.white.withAlphaComponent(0.3).cgColor
                : NSColor.white.withAlphaComponent(0.08).cgColor
        }
    }

    /// 更新当前选中颜色，同步调色板按钮背景色。
    func selectColor(_ color: AnnotationColor) {
        selectedColor = color
        paletteButton?.layer?.backgroundColor = nsColor(color).cgColor
        updatePaletteSelection()
    }

    /// 高亮颜色面板中当前选中的预设色块（白色描边）。
    private func updatePaletteSelection() {
        guard let content = colorPanel?.contentView else { return }
        for sv in content.subviews {
            guard let btn = sv as? NSButton, btn.tag >= 200 else { continue }
            let idx = btn.tag - 200
            guard AnnotationColor.presets.indices.contains(idx) else { continue }
            let isSelected = AnnotationColor.presets[idx] == selectedColor
            btn.layer?.borderWidth = isSelected ? 2.5 : 0
            btn.layer?.borderColor = NSColor.white.cgColor
        }
    }

    /// 更新撤销按钮的可用状态（无可撤销标注时置灰）。
    func updateUndoButton(canUndo: Bool) {
        undoButton?.isEnabled = canUndo
        undoButton?.contentTintColor = canUndo ? .white : NSColor.white.withAlphaComponent(0.3)
    }

    /// 更新圆角按钮的视觉状态（激活时高亮并显示当前半径）。
    func updateCornerRadius(_ radius: CGFloat) {
        let active = CornerRounding.isEnabled(radius)
        cornerButton?.layer?.backgroundColor = active
            ? NSColor.systemTeal.withAlphaComponent(0.6).cgColor
            : NSColor.white.withAlphaComponent(0.08).cgColor
        let title = active ? "圆\(Int(radius))" : "圆角"
        cornerButton?.attributedTitle = NSAttributedString(string: title, attributes: [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.white
        ])
    }

    private func toolTag(_ tool: AnnotationType?) -> Int {
        guard let tool = tool else { return 0 }
        return AnnotationType.allCases.firstIndex(of: tool)! + 1
    }

    private func toolFromTag(_ tag: Int) -> AnnotationType? {
        guard tag > 0 else { return nil }
        let idx = tag - 1
        return AnnotationType.allCases.indices.contains(idx) ? AnnotationType.allCases[idx] : nil
    }

    private func nsColor(_ color: AnnotationColor) -> NSColor {
        let rgb = color.rgbComponents
        return NSColor(srgbRed: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1)
    }

}

/// 工具条内容视图：强制显示箭头光标，并管理图标按钮的悬停提示。
/// nonactivatingPanel 下 cursorRect 与 mouseEntered 不可靠，改用 mouseMoved
/// tracking area（已验证有效）检测悬停，提示用独立小窗口显示避免裁剪。
final class ToolbarContainerView: NSView {
    private var tooltipButtons: [(button: NSButton, text: String)] = []
    private var hoverState = ToolbarHoverState()
    private var tooltipWindow: NSPanel?

    /// 注册一个图标按钮及其悬停提示文本。
    func registerTooltipButton(_ button: NSButton, text: String) {
        tooltipButtons.append((button, text))
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: NSCursor.arrow)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for ta in trackingAreas { removeTrackingArea(ta) }
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .cursorUpdate, .activeAlways, .inVisibleRect],
            owner: self, userInfo: nil
        ))
    }

    /// 鼠标在工具条任意位置（含子视图）移动时强制箭头光标，并更新图标按钮悬停提示。
    override func mouseMoved(with event: NSEvent) {
        NSCursor.arrow.set()
        updateTooltip(with: event)
    }

    override func cursorUpdate(with event: NSEvent) {
        NSCursor.arrow.set()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil { hideTooltip() }
    }

    private func updateTooltip(with event: NSEvent) {
        guard !tooltipButtons.isEmpty else { return }
        let point = convert(event.locationInWindow, from: nil)
        let matched = tooltipButtons.first(where: { $0.button.frame.contains(point) })?.text
        guard hoverState.update(matchedTooltip: matched) else { return }
        if let text = hoverState.currentTooltip,
           let button = tooltipButtons.first(where: { $0.text == text })?.button {
            showTooltip(text: text, for: button)
        } else {
            hideTooltip()
        }
    }

    private func showTooltip(text: String, for button: NSButton) {
        hideTooltip()
        let font = NSFont.labelFont(ofSize: 12)
        let labelSize = CGSize(width: 28, height: 16)
        let buttonInWindow = button.superview?.convert(button.frame, to: nil) ?? button.frame
        let winOrigin = button.window?.frame.origin ?? .zero
        let buttonScreen = buttonInWindow.offsetBy(dx: winOrigin.x, dy: winOrigin.y)
        let screenFrame = button.window?.screen?.frame ?? NSScreen.main?.frame ?? .zero
        let frame = CopyButtonTooltip.windowFrame(
            buttonScreenFrame: buttonScreen, labelSize: labelSize, screenFrame: screenFrame)

        let panel = NSPanel(contentRect: frame,
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 3)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovable = false

        let label = NSTextField(labelWithString: text)
        label.font = font
        label.textColor = .white
        label.alignment = .center
        label.wantsLayer = true
        label.layer?.cornerRadius = 4
        label.layer?.backgroundColor = NSColor(white: 0, alpha: 0.85).cgColor
        label.frame = panel.contentView!.bounds
        label.autoresizingMask = [.width, .height]
        panel.contentView?.addSubview(label)

        panel.orderFrontRegardless()
        tooltipWindow = panel
    }

    private func hideTooltip() {
        tooltipWindow?.orderOut(nil)
        tooltipWindow = nil
    }
}
