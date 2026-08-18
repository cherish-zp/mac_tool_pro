import XCTest
import AppKit

/// TDD: 文本输入撤销策略 - 片段管理窗口的 key/搜索等 NSTextField
/// 使用 field editor 编辑，系统默认 field editor 不允许 Undo（Cmd+Z 无效），
/// 必须由窗口提供 allowsUndo = true 的 field editor。
final class UndoFieldEditorPolicyTests: XCTestCase {

    func test_fieldEditorEnablesUndo() {
        let editor = UndoFieldEditorPolicy.makeFieldEditor()
        XCTAssertTrue(editor.allowsUndo, "field editor 必须启用 Undo，否则 Cmd+Z 无效")
    }

    func test_fieldEditorIsFieldEditor() {
        let editor = UndoFieldEditorPolicy.makeFieldEditor()
        XCTAssertTrue(editor.isFieldEditor, "必须标记为 fieldEditor 才能作为文本控件编辑器")
    }

    func test_fieldEditorIsPlainText() {
        let editor = UndoFieldEditorPolicy.makeFieldEditor()
        XCTAssertFalse(editor.isRichText, "纯文本编辑应关闭富文本，避免撤销状态异常")
    }

    func test_fieldEditorIsReusable() {
        let editor = UndoFieldEditorPolicy.makeFieldEditor()
        editor.string = "abc"
        XCTAssertEqual(editor.string, "abc")
    }
}
