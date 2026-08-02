import AppKit

/// 截图工具条代理：工具条按钮事件回调。
protocol ScreenshotToolbarDelegate: AnyObject {
    func toolbarDidSelect(tool: AnnotationType?)
    func toolbarDidSelectColor(_ color: AnnotationColor)
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

    init() {
        let frame = NSRect(x: 0, y: 0, width: 640, height: 44)
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

        buildUI()
    }


    private func buildUI() {
        let container = NSView(frame: contentView!.bounds)
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

        // 分隔线
        x += 8
        let sep = NSBox(frame: NSRect(x: x, y: 6, width: 1, height: 32))
        sep.boxType = .separator
        container.addSubview(sep)
        x += 8

        // 颜色选择
        for color in AnnotationColor.allCases {
            let btn = NSButton(frame: NSRect(x: x, y: y, width: 20, height: 20))
            btn.wantsLayer = true
            btn.layer?.cornerRadius = 10
            btn.layer?.backgroundColor = nsColor(color).cgColor
            btn.tag = AnnotationColor.allCases.firstIndex(of: color)! + 100
            btn.action = #selector(colorSelected(_:))
            btn.target = self
            btn.isBordered = false
            container.addSubview(btn)
            x += 24
        }

        // 分隔线
        x += 4
        let sep2 = NSBox(frame: NSRect(x: x, y: 6, width: 1, height: 32))
        sep2.boxType = .separator
        container.addSubview(sep2)
        x += 8

        // 操作按钮
        x = addActionButton(container, x: x, y: y, title: "滚动", action: #selector(scrollTapped), color: .systemPurple)
        x = addActionButton(container, x: x + 4, y: y, title: "剪贴板", action: #selector(copyTapped), color: .systemBlue)
        x = addActionButton(container, x: x + 4, y: y, title: "保存", action: #selector(saveTapped), color: .systemGreen)
        x = addActionButton(container, x: x + 4, y: y, title: "贴图", action: #selector(pinTapped), color: .systemOrange)
        x = addActionButton(container, x: x + 4, y: y, title: "取消", action: #selector(cancelTapped), color: .systemRed)
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

    private func addActionButton(_ container: NSView, x: CGFloat, y: CGFloat,
                                  title: String, action: Selector, color: NSColor) -> CGFloat {
        let btn = NSButton(frame: NSRect(x: x, y: y, width: 52, height: 28))
        btn.wantsLayer = true
        btn.layer?.cornerRadius = 6
        btn.layer?.backgroundColor = color.cgColor
        btn.isBordered = false
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: NSColor.white
        ]
        btn.attributedTitle = NSAttributedString(string: title, attributes: attrs)
        btn.target = self
        btn.action = action
        container.addSubview(btn)
        return x + 52
    }

    // MARK: 动作

    @objc private func toolSelected(_ sender: NSButton) {
        let tool = toolFromTag(sender.tag)
        selectTool(tool)
        DiagLog.write("Toolbar.toolSelected: tool=\(String(describing: tool)) tag=\(sender.tag)")
        toolbarDelegate?.toolbarDidSelect(tool: tool)
    }

    @objc private func colorSelected(_ sender: NSButton) {
        let idx = sender.tag - 100
        guard AnnotationColor.allCases.indices.contains(idx) else { return }
        DiagLog.write("Toolbar.colorSelected: idx=\(idx)")
        toolbarDelegate?.toolbarDidSelectColor(AnnotationColor.allCases[idx])
    }

    @objc private func copyTapped() { toolbarDelegate?.toolbarDidCopy() }
    @objc private func saveTapped() { toolbarDelegate?.toolbarDidSave() }
    @objc private func pinTapped() { toolbarDelegate?.toolbarDidPin() }
    @objc private func cancelTapped() { toolbarDelegate?.toolbarDidCancel() }
    @objc private func scrollTapped() { toolbarDelegate?.toolbarDidScroll() }

    // MARK: 工具状态

    func selectTool(_ tool: AnnotationType?) {
        for (t, btn) in toolButtons {
            btn.layer?.backgroundColor = (t == tool)
                ? NSColor.white.withAlphaComponent(0.3).cgColor
                : NSColor.white.withAlphaComponent(0.08).cgColor
        }
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
        switch color {
        case .red: return .systemRed
        case .yellow: return .systemYellow
        case .green: return .systemGreen
        case .blue: return .systemBlue
        case .white: return .white
        case .black: return .black
        }
    }

}
