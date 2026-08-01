import Foundation

/// 一次工具调用：工具 id + 当次选中的 urls。
public struct ToolInvocation {
    public let toolId: String
    public let urls: [URL]
    public init(toolId: String, urls: [URL]) {
        self.toolId = toolId
        self.urls = urls
    }
}

/// 菜单项调用表：用 NSMenuItem.tag 作为下标找回调用。
/// 原因：Finder Sync 菜单项的 representedObject(任意对象)跨进程到 Finder 时不被保留，
/// 而 tag(原始 Int)会保留。故用 tag + 本表传递 {工具id, urls}。
public final class ToolInvocationTable {
    public private(set) var invocations: [ToolInvocation] = []

    @discardableResult
    public func append(_ invocation: ToolInvocation) -> Int {
        invocations.append(invocation)
        return invocations.count - 1
    }

    public func clear() {
        invocations.removeAll()
    }

    public func resolve(tag: Int) -> ToolInvocation? {
        guard tag >= 0, tag < invocations.count else { return nil }
        return invocations[tag]
    }
}
