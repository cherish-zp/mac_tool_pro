import XCTest

/// TDD: 工具分发必须使用调用(invocation)自带的 urls，而非任何共享/实例状态。
/// 这重现并锁死"右键复制路径却复制空内容"的 bug：实例 selectedURLs 被多次 menu(for:) 覆盖。
final class ToolDispatcherTests: XCTestCase {

    func test_dispatch_copiesCarriedSelectionPath() {
        let spy = PasteboardSpy()
        let tool = CopyPathTool()
        tool.pasteboard = spy
        let registry = ToolRegistry(tools: [tool])

        ToolDispatcher.perform(toolId: "copy-path",
                               urls: [URL(fileURLWithPath: "/Users/zp/notes.txt")],
                               registry: registry)

        XCTAssertEqual(spy.copied, "/Users/zp/notes.txt")
    }

    func test_dispatch_usesInvocationUrlsNotExternalState() {
        // 即使外部没有任何选中状态，分发也必须用 invocation 自带的 urls
        let spy = PasteboardSpy()
        let tool = CopyPathTool()
        tool.pasteboard = spy
        let registry = ToolRegistry(tools: [tool])

        ToolDispatcher.perform(toolId: "copy-path",
                               urls: [URL(fileURLWithPath: "/a/b/c")],
                               registry: registry)

        XCTAssertEqual(spy.copied, "/a/b/c")
    }

    func test_dispatch_multipleUrls_joinedByNewline() {
        let spy = PasteboardSpy()
        let tool = CopyPathTool()
        tool.pasteboard = spy
        let registry = ToolRegistry(tools: [tool])

        ToolDispatcher.perform(toolId: "copy-path",
                               urls: [URL(fileURLWithPath: "/x"), URL(fileURLWithPath: "/y")],
                               registry: registry)

        XCTAssertEqual(spy.copied, "/x\n/y")
    }

    func test_dispatch_unknownTool_copiesNothing() {
        let spy = PasteboardSpy()
        let tool = CopyPathTool()
        tool.pasteboard = spy
        let registry = ToolRegistry(tools: [tool])

        ToolDispatcher.perform(toolId: "does-not-exist",
                               urls: [URL(fileURLWithPath: "/x")],
                               registry: registry)

        XCTAssertNil(spy.copied)
    }
}
