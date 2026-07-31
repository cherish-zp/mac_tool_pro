import AppKit

/// Copies the POSIX absolute path(s) of the selected item(s) to the pasteboard.
/// Multiple selections are joined with newlines.
public final class CopyPathTool: Tool {
    public let id = "copy-path"
    public let title = "复制路径"
    public var image: NSImage? {
        NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "复制路径")
    }

    public init() {}

    public func canPerform(on urls: [URL]) -> Bool {
        !urls.isEmpty
    }

    public func perform(on urls: [URL]) {
        let paths = urls.map(\.path)
        Clipboard.copy(paths.joined(separator: "\n"))
    }
}
