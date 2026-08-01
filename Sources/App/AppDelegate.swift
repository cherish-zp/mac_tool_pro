import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var requestProcessor: RequestProcessor?
    private var pollTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(
            systemSymbolName: "hammer",
            accessibilityDescription: "mac_tool_pro"
        )
        statusItem.button?.image?.isTemplate = true
        rebuildMenu()
        startRequestPolling()
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let header = menu.addItem(withTitle: "mac_tool_pro", action: nil, keyEquivalent: "")
        header.isEnabled = false

        for tool in ToolRegistry.shared.tools {
            let item = NSMenuItem(title: tool.title, action: #selector(toggle(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = tool.id
            item.image = tool.image
            item.state = ToolConfig.isEnabled(tool.id) ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())
        menu.addItem(withTitle: "退出 mac_tool_pro", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
    }

    /// 轮询扩展容器里的"新建文件"请求队列，由本非沙盒进程真正创建文件。
    private func startRequestPolling() {
        requestProcessor = RequestProcessor(queueDirectory: IPCConfig.extensionRequestDirectory())
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.requestProcessor?.processAll()
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    @objc private func toggle(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        ToolConfig.setEnabled(id, !ToolConfig.isEnabled(id))
        rebuildMenu()
    }
}
