import AppKit

/// 文件中转站面板控制器：顶部毛玻璃面板，接收文件拖入暂存 URL 引用，
/// 条目可拖出到 Finder/其他 App，点击定位，右键管理。
final class TransferShelfPanelController: NSObject {

    static let shared = TransferShelfPanelController()

    private var panel: NSPanel?
    private var shelfView: TransferShelfView!
    private var hideWorkItem: DispatchWorkItem?

    private var store = TransferShelfStore() {
        didSet { persist() }
    }

    private override init() {
        super.init()
        loadPersisted()
    }

    // MARK: - 对外接口

    /// 显示面板（拖拽会话开始或菜单触发）。
    func showPanel(manual: Bool = false) {
        let toastPanel = panel ?? makePanel()
        panel = toastPanel
        position(toastPanel)
        cancelScheduledHide()

        toastPanel.alphaValue = 0
        toastPanel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = TransferShelfLayoutSpec.fadeInDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            toastPanel.animator().alphaValue = 1
        })
        scheduleHide(after: manual ? 5 : 3.2)
    }

    /// 拖拽会话开始（全局鼠标拖动超阈值）。
    func dragSessionStarted() {
        showPanel()
    }

    /// 拖拽会话结束（鼠标松开）。若面板刚接收文件则延长停留。
    func dragSessionEnded() {
        scheduleHide(after: 3)
    }

    // MARK: - 面板构建

    private func makePanel() -> NSPanel {
        let item = TransferShelfView(frame: NSRect(x: 0, y: 0, width: 200, height: TransferShelfLayoutSpec.panelHeight))
        item.onItemsChanged = { [weak self] in
            self?.reloadItems()
        }
        item.onInteracting = { [weak self] in
            self?.cancelScheduledHide()
        }
        shelfView = item

        let newPanel = NSPanel(
            contentRect: item.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = true
        newPanel.level = .floating
        newPanel.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
        newPanel.hidesOnDeactivate = false
        newPanel.contentView = item
        return newPanel
    }

    /// 面板定位到鼠标所在屏幕顶部、水平居中。
    private func position(_ toastPanel: NSPanel) {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        guard let screen = screen else { return }
        let visible = screen.visibleFrame
        let width = shelfView.preferredPanelWidth()
        let height = TransferShelfLayoutSpec.panelHeight
        toastPanel.setFrame(
            NSRect(
                x: visible.midX - width / 2,
                y: visible.maxY - height - TransferShelfLayoutSpec.topGap,
                width: width,
                height: height
            ),
            display: true
        )
        shelfView.frame = NSRect(x: 0, y: 0, width: width, height: height)
    }

    private func reloadItems() {
        shelfView.render(items: store.items)
        position(panel ?? NSPanel())
        cancelScheduledHide()
        scheduleHide(after: 3.5)
    }

    // MARK: - 显示/隐藏调度

    private func scheduleHide(after delay: TimeInterval) {
        cancelScheduledHide()
        let item = DispatchWorkItem { [weak self] in
            self?.hidePanel()
        }
        hideWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    private func cancelScheduledHide() {
        hideWorkItem?.cancel()
        hideWorkItem = nil
    }

    private func hidePanel() {
        guard let toastPanel = panel else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = TransferShelfLayoutSpec.fadeOutDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            toastPanel.animator().alphaValue = 0
        }, completionHandler: {
            if toastPanel.alphaValue == 0 {
                toastPanel.orderOut(nil)
            }
        })
    }

    // MARK: - 持久化

    private var storageURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("mac_tool_pro", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("transfer_shelf.json")
    }

    private func persist() {
        guard let data = store.encode() else { return }
        try? data.write(to: storageURL, options: .atomic)
    }

    private func loadPersisted() {
        guard let data = try? Data(contentsOf: storageURL) else { return }
        store = TransferShelfStore.load(from: data)
    }

    /// 接收拖入的文件 URL（由 TransferShelfView 调用）。
    func accept(urls: [URL]) {
        var changed = false
        for url in urls where url.isFileURL {
            if store.add(url: url) != nil {
                changed = true
            }
        }
        guard changed, let toastPanel = panel else { return }
        shelfView.render(items: store.items)
        position(toastPanel)
        cancelScheduledHide()
        scheduleHide(after: 3.5)
    }

    /// 供条目操作回调：移除条目。
    func removeItem(id: UUID) {
        if store.remove(id: id) {
            shelfView.render(items: store.items)
            position(panel ?? NSPanel())
        }
    }
}

// MARK: - 暂存面板视图

/// 毛玻璃暂存面板：接收文件拖入，横向排列条目。
final class TransferShelfView: NSVisualEffectView {

    var onItemsChanged: (() -> Void)?
    var onInteracting: (() -> Void)?

    private var items: [TransferItem] = []
    private let stackView = NSStackView()
    private let emptyLabel = NSTextField(labelWithString: "拖入文件暂存")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        material = .hudWindow
        blendingMode = .behindWindow
        state = .active
        wantsLayer = true
        layer?.cornerRadius = TransferShelfLayoutSpec.cornerRadius
        layer?.masksToBounds = true
        registerForDraggedTypes([.fileURL, .URL])

        stackView.orientation = .horizontal
        stackView.spacing = TransferShelfLayoutSpec.itemSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        emptyLabel.font = .systemFont(ofSize: 12, weight: .medium)
        emptyLabel.textColor = .secondaryLabelColor
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: TransferShelfLayoutSpec.panelPadding),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -TransferShelfLayoutSpec.panelPadding),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func wantsPeriodicDraggingUpdates() -> Bool {
        false
    }

    func preferredPanelWidth() -> CGFloat {
        items.isEmpty ? 180 : TransferShelfLayoutSpec.panelWidth(itemCount: items.count)
    }

    func render(items: [TransferItem]) {
        self.items = items
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for item in items {
            let itemView = TransferShelfItemView(item: item)
            itemView.onRemove = { [weak self] id in
                TransferShelfPanelController.shared.removeItem(id: id)
                self?.onInteracting?()
            }
            stackView.addArrangedSubview(itemView)
        }
        emptyLabel.isHidden = !items.isEmpty
    }

    // MARK: - 拖入接收

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard hasFileURLs(sender) else { return [] }
        onInteracting?()
        layer?.borderColor = NSColor.controlAccentColor.cgColor
        layer?.borderWidth = 2
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        layer?.borderWidth = 0
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        layer?.borderWidth = 0
        guard let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self]) as? [URL],
              !urls.isEmpty else { return false }
        TransferShelfPanelController.shared.accept(urls: urls)
        return true
    }

    private func hasFileURLs(_ sender: NSDraggingInfo) -> Bool {
        guard let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] else {
            return false
        }
        return urls.contains { $0.isFileURL }
    }
}

// MARK: - 条目视图

/// 单个暂存条目：文件图标 + 名称；点击 Finder 定位，可拖出，右键管理。
final class TransferShelfItemView: NSView {

    var onRemove: ((UUID) -> Void)?

    private let item: TransferItem
    private let iconView = NSImageView()
    private let nameLabel = NSTextField(labelWithString: "")

    init(item: TransferItem) {
        self.item = item
        super.init(frame: NSRect(x: 0, y: 0,
                                 width: TransferShelfLayoutSpec.itemSize,
                                 height: TransferShelfLayoutSpec.itemSize))

        let icon = NSWorkspace.shared.icon(forFile: item.url.path)
        icon.size = NSSize(width: 32, height: 32)
        iconView.image = icon
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)

        nameLabel.stringValue = item.name
        nameLabel.font = .systemFont(ofSize: 9, weight: .medium)
        nameLabel.textColor = .secondaryLabelColor
        nameLabel.maximumNumberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingMiddle
        nameLabel.cell?.truncatesLastVisibleLine = true
        nameLabel.cell?.wraps = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)

        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.25).cgColor

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),

            nameLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 2),
            nameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 2),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -2),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -3),
        ])

        registerForDraggedTypes([])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// 点击：在 Finder 中定位该文件。
    override func mouseDown(with event: NSEvent) {
        NSWorkspace.shared.activateFileViewerSelecting([item.url])
    }

    /// 拖动：把暂存文件拖出到 Finder/其他 App。
    override func mouseDragged(with event: NSEvent) {
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(item.url.absoluteString, forType: .fileURL)
        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }

    /// 右键菜单：Finder 显示 / 拷贝路径 / 移除。
    override func menu(for event: NSEvent) -> NSMenu? {
        let menu = NSMenu()
        let revealItem = NSMenuItem(title: "在 Finder 显示", action: #selector(revealInFinder), keyEquivalent: "")
        revealItem.target = self
        menu.addItem(revealItem)
        let copyItem = NSMenuItem(title: "拷贝路径", action: #selector(copyPath), keyEquivalent: "")
        copyItem.target = self
        menu.addItem(copyItem)
        menu.addItem(.separator())
        let removeItem = NSMenuItem(title: "移除", action: #selector(removeSelf), keyEquivalent: "")
        removeItem.target = self
        menu.addItem(removeItem)
        return menu
    }

    @objc private func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([item.url])
    }

    @objc private func copyPath() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.url.path, forType: .string)
    }

    @objc private func removeSelf() {
        onRemove?(item.id)
    }
}

extension TransferShelfItemView: NSDraggingSource {
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        [.copy, .move]
    }
}
