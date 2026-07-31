import FinderSync
import AppKit

@objc(FinderSyncExt)
final class FinderSyncExt: FIFinderSync {
    override init() {
        super.init()
        // Observe the whole file system so the context menu is available everywhere.
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForItems || menuKind == .contextualMenuForContainer else {
            return nil
        }
        let menu = NSMenu(title: "mac_tool_pro")
        buildMenu(into: menu)
        return menu
    }

    private func buildMenu(into menu: NSMenu) {
        let urls = FIFinderSyncController.default().selectedItemURLs() ?? []
        let state = ToolConfig.load()

        let applicable: [Tool] = ToolRegistry.shared.tools.filter { tool in
            (state.enabled[tool.id] ?? true) && tool.canPerform(on: urls)
        }

        if applicable.isEmpty {
            let placeholder = menu.addItem(withTitle: "mac_tool_pro", action: nil, keyEquivalent: "")
            placeholder.isEnabled = false
            return
        }

        if applicable.count == 1 {
            menu.addItem(menuItem(for: applicable[0]))
            return
        }

        let parent = menu.addItem(withTitle: "mac_tool_pro", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "mac_tool_pro")
        for tool in applicable {
            submenu.addItem(menuItem(for: tool))
        }
        parent.submenu = submenu
    }

    private func menuItem(for tool: Tool) -> NSMenuItem {
        let item = NSMenuItem(title: tool.title, action: #selector(performTool(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = tool.id
        item.image = tool.image
        return item
    }

    @objc private func performTool(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String,
              let tool = ToolRegistry.shared.tool(for: id) else { return }
        let urls = FIFinderSyncController.default().selectedItemURLs() ?? []
        tool.perform(on: urls)
    }
}
