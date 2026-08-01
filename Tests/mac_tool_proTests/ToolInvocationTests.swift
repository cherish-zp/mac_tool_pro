import XCTest

/// TDD: Finder Sync 菜单项的 representedObject 跨进程不保留，
/// 改用 NSMenuItem.tag 作为下标，从调用表里找回 {工具id, urls}。
final class ToolInvocationTests: XCTestCase {

    func test_appendReturnsIncreasingTag_andResolves() {
        let table = ToolInvocationTable()
        let a = table.append(ToolInvocation(toolId: "copy-path", urls: [URL(fileURLWithPath: "/a")]))
        let b = table.append(ToolInvocation(toolId: "other", urls: [URL(fileURLWithPath: "/b")]))
        XCTAssertEqual(a, 0)
        XCTAssertEqual(b, 1)
        XCTAssertEqual(table.resolve(tag: 0)?.toolId, "copy-path")
        XCTAssertEqual(table.resolve(tag: 0)?.urls.first?.path, "/a")
        XCTAssertEqual(table.resolve(tag: 1)?.toolId, "other")
        XCTAssertEqual(table.resolve(tag: 1)?.urls.first?.path, "/b")
    }

    func test_resolveOutOfRange_returnsNil() {
        let table = ToolInvocationTable()
        _ = table.append(ToolInvocation(toolId: "copy-path", urls: []))
        XCTAssertNil(table.resolve(tag: -1))
        XCTAssertNil(table.resolve(tag: 99))
    }

    func test_emptyTable_resolveReturnsNil() {
        let table = ToolInvocationTable()
        XCTAssertNil(table.resolve(tag: 0))
    }

    func test_clear_resetsTable() {
        let table = ToolInvocationTable()
        _ = table.append(ToolInvocation(toolId: "copy-path", urls: [URL(fileURLWithPath: "/x")]))
        table.clear()
        XCTAssertNil(table.resolve(tag: 0))
    }
}
