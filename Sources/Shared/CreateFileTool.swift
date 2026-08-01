import AppKit

/// 文件创建器抽象。扩展侧实现为"写请求到队列"，App 侧实现为"真正建文件"，测试用 spy。
public protocol FileCreator: AnyObject {
    func createFile(in directory: URL, baseName: String)
}

/// 文件系统探查抽象（判断 URL 是否目录），便于测试注入。
public protocol FileSystemInspector: AnyObject {
    func isDirectory(_ url: URL) -> Bool
}

/// 生产探查：通过 URLResourceValues 判断是否目录（沙盒若拒绝则回退为非目录）。
public final class SystemFileSystemInspector: FileSystemInspector {
    public init() {}
    public func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }
}

/// 右键"新建文件"工具：在选中项所在目录（或选中的文件夹）内创建空文件。
/// 扩展(沙盒)不能直接写任意目录，故 perform 只把 {目录, 基础名} 交给 FileCreator，
/// 由非沙盒的 App 侧真正建文件并处理文件名去重。
public final class CreateFileTool: Tool {
    public let id = "create-file"
    public let title = "新建文件"
    public var image: NSImage? {
        NSImage(systemSymbolName: "doc.badge.plus", accessibilityDescription: "新建文件")
    }

    /// 默认新建空文本文件；基础名固定，去重在 App 侧按目录现有文件处理。
    public let baseName = "新建文件.txt"
    public var fileCreator: FileCreator
    public var inspector: FileSystemInspector

    public init(fileCreator: FileCreator, inspector: FileSystemInspector = SystemFileSystemInspector()) {
        self.fileCreator = fileCreator
        self.inspector = inspector
    }

    public func canPerform(on urls: [URL]) -> Bool {
        !urls.isEmpty
    }

    public func perform(on urls: [URL]) {
        guard let first = urls.first else { return }
        // 选中文件夹 -> 在其内部创建；选中文件 -> 在其所在目录创建。
        let target = inspector.isDirectory(first) ? first : first.deletingLastPathComponent()
        fileCreator.createFile(in: target, baseName: baseName)
    }
}
