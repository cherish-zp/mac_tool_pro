import XCTest

/// TDD: 复制路径工具应把选中文件的 POSIX 绝对路径写入剪贴板，多个文件用换行分隔。
final class CopyPathToolTests: XCTestCase {

    func test_singleFile_producesPosixAbsolutePath() {
        let tool = CopyPathTool()
        let url = URL(fileURLWithPath: "/Users/zp/Documents/report.pdf")
        XCTAssertEqual(tool.pathString(for: [url]), "/Users/zp/Documents/report.pdf")
    }

    func test_multipleFiles_joinedByNewline() {
        let tool = CopyPathTool()
        let urls = [
            URL(fileURLWithPath: "/Users/zp/a.txt"),
            URL(fileURLWithPath: "/Users/zp/b/folder")
        ]
        XCTAssertEqual(tool.pathString(for: urls), "/Users/zp/a.txt\n/Users/zp/b/folder")
    }

    func test_noFiles_producesEmptyString() {
        let tool = CopyPathTool()
        XCTAssertEqual(tool.pathString(for: []), "")
    }

    func test_perform_writesJoinedPathsToPasteboard() {
        let tool = CopyPathTool()
        let spy = PasteboardSpy()
        tool.pasteboard = spy
        tool.perform(on: [URL(fileURLWithPath: "/Users/zp/x.log")])
        XCTAssertEqual(spy.copied, "/Users/zp/x.log")
    }
}

/// 测试用假剪贴板，记录最后一次写入内容。
final class PasteboardSpy: Pasteboard {
    var copied: String?
    func copy(_ string: String) { copied = string }
}
