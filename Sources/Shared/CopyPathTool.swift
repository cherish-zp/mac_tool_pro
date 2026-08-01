import AppKit

/// Copies the POSIX absolute path(s) of the selected item(s) to the pasteboard.
/// Multiple selections are joined with newlines.
public final class CopyPathTool: Tool {
    public let id = "copy-path"
    public let title = "复制路径"
    public var image: NSImage? {
        NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "复制路径")
    }

    /// 注入的剪贴板，默认为系统剪贴板；测试中注入 spy。
    public var pasteboard: Pasteboard = SystemPasteboard()

    public init() {}

    public func canPerform(on urls: [URL]) -> Bool {
        !urls.isEmpty
    }

    /// 纯函数：把选中项转成换行分隔的 POSIX 绝对路径字符串。
    public func pathString(for urls: [URL]) -> String {
        urls.map(\.path).joined(separator: "\n")
    }

    public func perform(on urls: [URL]) {
        pasteboard.copy(pathString(for: urls))
    }
}
