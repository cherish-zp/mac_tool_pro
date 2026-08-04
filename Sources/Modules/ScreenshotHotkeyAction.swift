import CoreGraphics

/// 截图相关全局热键的动作类型：F1 = 截图，F3 = 贴图当前选区。
public enum ScreenshotHotkeyAction: Equatable {
    case screenshot
    case pin

    /// F1 虚拟键码（kVK_F1 = 122）。
    public static let f1KeyCode: UInt32 = 122
    /// F3 虚拟键码（kVK_F3 = 99）。
    public static let f3KeyCode: UInt32 = 99

    /// 根据虚拟键码映射到截图热键动作，未匹配返回 nil。
    public static func action(for keyCode: UInt32) -> ScreenshotHotkeyAction? {
        switch keyCode {
        case f1KeyCode: return .screenshot
        case f3KeyCode: return .pin
        default: return nil
        }
    }
}
