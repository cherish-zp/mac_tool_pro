import XCTest

/// TDD: 编辑菜单规格 - 确保 App 主菜单包含 Cut/Copy/Paste/SelectAll/Undo 等标准项，
/// 否则菜单栏应用中 NSTextView/NSTextField 无法响应 Cmd+V 等快捷键。
final class EditMenuSpecTests: XCTestCase {

    func test_editMenuContainsPasteWithCmdV() {
        let paste = EditMenuSpec.editMenuItems.first { $0.action == "paste:" }
        XCTAssertNotNil(paste, "缺少粘贴菜单项")
        XCTAssertEqual(paste?.keyEquivalent, "v")
    }

    func test_editMenuContainsCopyWithCmdC() {
        let copy = EditMenuSpec.editMenuItems.first { $0.action == "copy:" }
        XCTAssertNotNil(copy)
        XCTAssertEqual(copy?.keyEquivalent, "c")
    }

    func test_editMenuContainsCutWithCmdX() {
        let cut = EditMenuSpec.editMenuItems.first { $0.action == "cut:" }
        XCTAssertNotNil(cut)
        XCTAssertEqual(cut?.keyEquivalent, "x")
    }

    func test_editMenuContainsSelectAllWithCmdA() {
        let selectAll = EditMenuSpec.editMenuItems.first { $0.action == "selectAll:" }
        XCTAssertNotNil(selectAll)
        XCTAssertEqual(selectAll?.keyEquivalent, "a")
    }

    func test_editMenuContainsUndoWithCmdZ() {
        let undo = EditMenuSpec.editMenuItems.first { $0.action == "undo:" }
        XCTAssertNotNil(undo)
        XCTAssertEqual(undo?.keyEquivalent, "z")
    }

    func test_editMenuHasAtLeastFiveItems() {
        XCTAssertGreaterThanOrEqual(EditMenuSpec.editMenuItems.count, 5)
    }
}
