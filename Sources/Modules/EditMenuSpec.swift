import Foundation

/// 编辑菜单规格：描述 App 主菜单中「编辑」子菜单的标准项。
/// 菜单栏应用（.accessory）默认无主菜单，导致 NSTextView/NSTextField
/// 无法响应 Cmd+V/C/X/A/Z 等快捷键。此规格用于构建主菜单修复此问题。
public enum EditMenuSpec {

    public struct Item: Equatable {
        public let title: String
        public let action: String
        public let keyEquivalent: String

        public init(title: String, action: String, keyEquivalent: String) {
            self.title = title
            self.action = action
            self.keyEquivalent = keyEquivalent
        }
    }

    /// 编辑菜单标准项：撤销、重做、剪切、复制、粘贴、全选。
    public static let editMenuItems: [Item] = [
        Item(title: "撤销", action: "undo:", keyEquivalent: "z"),
        Item(title: "重做", action: "redo:", keyEquivalent: "Z"),
        Item(title: "剪切", action: "cut:", keyEquivalent: "x"),
        Item(title: "复制", action: "copy:", keyEquivalent: "c"),
        Item(title: "粘贴", action: "paste:", keyEquivalent: "v"),
        Item(title: "全选", action: "selectAll:", keyEquivalent: "a"),
    ]
}
