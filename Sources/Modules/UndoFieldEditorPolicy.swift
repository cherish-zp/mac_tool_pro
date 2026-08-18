import AppKit

/// 文本输入撤销策略：为 NSTextField/NSSearchField 提供启用 Undo 的 field editor。
/// macOS 默认 field editor 的 allowsUndo = false，导致 Cmd+Z 撤销无效。
public enum UndoFieldEditorPolicy {

    /// 创建可复用的纯文本 field editor，启用 Undo/Redo。
    public static func makeFieldEditor() -> NSTextView {
        let editor = NSTextView()
        editor.isFieldEditor = true
        editor.allowsUndo = true
        editor.isRichText = false
        editor.isAutomaticQuoteSubstitutionEnabled = false
        editor.isAutomaticDashSubstitutionEnabled = false
        return editor
    }
}
