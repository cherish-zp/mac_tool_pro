import AppKit

/// 设置窗口：左侧分类栏 + 右侧详情面板（仿系统设置布局）。
/// 第一版含「贴图」分类（呼吸灯样式）；左侧栏结构为后续设置项预留扩展。
final class SettingsWindow: NSWindow, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate {

    private var tableView: NSTableView!
    private var pinPane: PinSettingsPaneView!

    private let sidebarItems = ["贴图"]
    private static let cellID = NSUserInterfaceItemIdentifier("settingsSidebarCell")

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 420),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        title = "设置"
        titlebarAppearsTransparent = true
        center()
        isReleasedWhenClosed = false
        minSize = NSSize(width: 560, height: 340)
        delegate = self
        buildUI()
    }

    func showAndFocus() {
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - UI 构建

    private func buildUI() {
        let bg = NSVisualEffectView()
        bg.material = .windowBackground
        bg.blendingMode = .behindWindow
        bg.state = .active
        bg.autoresizingMask = [.width, .height]
        contentView = bg

        let split = NSSplitView()
        split.isVertical = true
        split.dividerStyle = .thin
        split.translatesAutoresizingMaskIntoConstraints = false
        bg.addSubview(split)

        // 左侧分类栏
        let sidebar = NSVisualEffectView()
        sidebar.material = .sidebar
        sidebar.blendingMode = .behindWindow
        sidebar.state = .active
        sidebar.translatesAutoresizingMaskIntoConstraints = false

        let scroll = NSScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.hasVerticalScroller = true
        scroll.borderType = .noBorder
        scroll.drawsBackground = false

        tableView = NSTableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsMultipleSelection = false
        tableView.headerView = nil
        tableView.backgroundColor = .clear
        tableView.rowHeight = 44
        tableView.intercellSpacing = NSSize(width: 0, height: 2)
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("settingsSidebar"))
        tableView.addTableColumn(column)
        scroll.documentView = tableView
        sidebar.addSubview(scroll)

        // 右侧详情：贴图设置面板
        pinPane = PinSettingsPaneView()
        pinPane.translatesAutoresizingMaskIntoConstraints = false

        split.addArrangedSubview(sidebar)
        split.addArrangedSubview(pinPane)
        split.setHoldingPriority(NSLayoutConstraint.Priority(260), forSubviewAt: 0)
        sidebar.widthAnchor.constraint(equalToConstant: 180).isActive = true

        NSLayoutConstraint.activate([
            split.leadingAnchor.constraint(equalTo: bg.leadingAnchor),
            split.trailingAnchor.constraint(equalTo: bg.trailingAnchor),
            split.topAnchor.constraint(equalTo: bg.topAnchor),
            split.bottomAnchor.constraint(equalTo: bg.bottomAnchor),

            scroll.leadingAnchor.constraint(equalTo: sidebar.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: sidebar.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: sidebar.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: sidebar.bottomAnchor),

            pinPane.leadingAnchor.constraint(equalTo: pinPane.superview!.leadingAnchor),
            pinPane.trailingAnchor.constraint(equalTo: pinPane.superview!.trailingAnchor),
            pinPane.topAnchor.constraint(equalTo: pinPane.superview!.topAnchor),
            pinPane.bottomAnchor.constraint(equalTo: pinPane.superview!.bottomAnchor),
        ])

        tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
    }

    // MARK: - NSTableView

    func numberOfRows(in tableView: NSTableView) -> Int { sidebarItems.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: Self.cellID, owner: nil) as? NSTableCellView
            ?? NSTableCellView()
        cell.identifier = Self.cellID
        cell.textField = NSTextField(labelWithString: sidebarItems[row])
        cell.textField?.font = .systemFont(ofSize: 13)
        cell.textField?.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(cell.textField!)
        NSLayoutConstraint.activate([
            cell.textField!.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 16),
            cell.textField!.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
        ])
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        // 目前仅「贴图」一个分类；新增分类时在此切换右侧详情
        let row = tableView.selectedRow
        pinPane.isHidden = row != 0
    }
}

/// 贴图设置面板：呼吸灯样式单选，更改立即保存并通知已打开贴图。
final class PinSettingsPaneView: NSView {

    private let topBarRadio: NSButton
    private let cornerDotRadio: NSButton

    init() {
        topBarRadio = NSButton(radioButtonWithTitle: "顶部横条呼吸灯", target: nil, action: nil)
        cornerDotRadio = NSButton(radioButtonWithTitle: "左上角圆点", target: nil, action: nil)
        super.init(frame: .zero)
        buildUI()
        syncFromStore()
    }

    required init?(coder: NSCoder) { fatalError("unsupported") }

    private func buildUI() {
        let titleLabel = NSTextField(labelWithString: "贴图")
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)

        let hintLabel = NSTextField(labelWithString: "呼吸灯提示当前存在贴图；更改立即对已打开的贴图生效。")
        hintLabel.font = .systemFont(ofSize: 12)
        hintLabel.textColor = .secondaryLabelColor

        topBarRadio.target = self
        topBarRadio.action = #selector(styleChanged(_:))
        cornerDotRadio.target = self
        cornerDotRadio.action = #selector(styleChanged(_:))

        let radioStack = NSStackView(views: [topBarRadio, cornerDotRadio])
        radioStack.orientation = .vertical
        radioStack.alignment = .leading
        radioStack.spacing = 10

        let box = NSBox()
        box.title = "呼吸灯样式"
        box.titleFont = .systemFont(ofSize: 13, weight: .medium)
        box.contentView = radioStack

        let stack = NSStackView(views: [titleLabel, hintLabel, box])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -24),
            box.widthAnchor.constraint(equalToConstant: 300),
        ])
    }

    @objc private func styleChanged(_ sender: NSButton) {
        let style: PinIndicatorStyle = sender == topBarRadio ? .topBar : .cornerDot
        PinSettingsStore.defaultStore().save(PinSettingsState(indicatorStyle: style))
        NotificationCenter.default.post(name: .pinIndicatorStyleDidChange, object: nil)
    }

    private func syncFromStore() {
        let style = PinSettingsStore.defaultStore().load().indicatorStyle
        topBarRadio.state = style == .topBar ? .on : .off
        cornerDotRadio.state = style == .cornerDot ? .on : .off
    }
}
