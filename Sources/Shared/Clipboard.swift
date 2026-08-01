import AppKit

/// 可注入的剪贴板抽象，便于在测试中替换为 spy。
public protocol Pasteboard: AnyObject {
    func copy(_ string: String)
}

/// 生产实现：写入系统剪贴板 NSPasteboard.general。
public final class SystemPasteboard: Pasteboard {
    public init() {}

    public func copy(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }
}
