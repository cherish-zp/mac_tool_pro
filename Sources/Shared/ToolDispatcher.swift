import Foundation

/// 解析工具调用并执行。
/// 关键：执行时使用调用(invocation)自带的 urls，而非任何共享/实例状态——
/// 避免 Finder Sync 多次调用 menu(for:) 覆盖实例选中状态导致复制空内容的 bug。
public enum ToolDispatcher {
    public static func perform(toolId: String, urls: [URL], registry: ToolRegistry = .shared) {
        guard let tool = registry.tool(for: toolId) else { return }
        tool.perform(on: urls)
    }
}
