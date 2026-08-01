import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var requestProcessor: RequestProcessor?
    private var pollTimer: Timer?

    // App 模块（截图/录屏/取色/OCR...）
    private var hotkeyManager: HotkeyManager!
    private var moduleRegistry: AppModuleRegistry!
    private var screenshotModule: ScreenshotModule!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(
            systemSymbolName: "hammer",
            accessibilityDescription: "mac_tool_pro"
        )
        statusItem.button?.image?.isTemplate = true

        setupAppModules()
        rebuildMenu()
        startRequestPolling()
    }

    /// 初始化 App 模块注册表 + Carbon 全局热键。
    private func setupAppModules() {
        let registrar = CarbonHotkeyRegistrar()
        hotkeyManager = HotkeyManager(registrar: registrar)
        moduleRegistry = AppModuleRegistry(hotkeyManager: hotkeyManager)

        screenshotModule = ScreenshotModule()
        moduleRegistry.register(screenshotModule)
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let header = menu.addItem(withTitle: "mac_tool_pro", action: nil, keyEquivalent: "")
        header.isEnabled = false

        // Finder 工具
        let toolsHeader = menu.addItem(withTitle: "Finder 工具", action: nil, keyEquivalent: "")
        toolsHeader.isEnabled = false
        for tool in ToolRegistry.shared.tools {
            let item = NSMenuItem(title: tool.title, action: #selector(toggleTool(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = tool.id
            item.image = tool.image
            item.state = ToolConfig.isEnabled(tool.id) ? .on : .off
            menu.addItem(item)
        }

        // App 模块
        menu.addItem(.separator())
        let modulesHeader = menu.addItem(withTitle: "功能模块", action: nil, keyEquivalent: "")
        modulesHeader.isEnabled = false
        for module in moduleRegistry.modules {
            let item = NSMenuItem(title: module.title, action: #selector(toggleModule(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = module.id
            item.state = moduleRegistry.isEnabled(module.id) ? .on : .off
            menu.addItem(item)
        }

        // 手动触发截图
        menu.addItem(.separator())
        menu.addItem(withTitle: "截图 (F1)", action: #selector(triggerScreenshot), keyEquivalent: "")

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

    @objc private func toggleTool(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        ToolConfig.setEnabled(id, !ToolConfig.isEnabled(id))
        rebuildMenu()
    }

    @objc private func toggleModule(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        moduleRegistry.setEnabled(id, !moduleRegistry.isEnabled(id))
        rebuildMenu()
    }

    @objc private func triggerScreenshot() {
        screenshotModule.perform()
    }
}
