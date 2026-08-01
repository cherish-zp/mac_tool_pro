import XCTest

/// TDD: 新建文件工具 - 请求 DTO 编解码 + 工具根据选中项解析目标目录并调用 FileCreator。
final class CreateFileToolTests: XCTestCase {

    func test_request_codableRoundTrip() throws {
        let req = CreateFileRequest(directory: URL(fileURLWithPath: "/Users/zp/Desktop"), baseName: "新建文件.txt")
        let data = try JSONEncoder().encode(req)
        let back = try JSONDecoder().decode(CreateFileRequest.self, from: data)
        XCTAssertEqual(back.directory.path, req.directory.path)
        XCTAssertEqual(back.baseName, req.baseName)
    }

    func test_canPerform_requiresSelection() {
        let tool = CreateFileTool(fileCreator: FileCreatorSpy(), inspector: InspectorStub(isDir: false))
        XCTAssertFalse(tool.canPerform(on: []))
        XCTAssertTrue(tool.canPerform(on: [URL(fileURLWithPath: "/a/b.txt")]))
    }

    func test_perform_onFile_createsInParentDirectory() {
        let creator = FileCreatorSpy()
        let tool = CreateFileTool(fileCreator: creator, inspector: InspectorStub(isDir: false))
        tool.perform(on: [URL(fileURLWithPath: "/Users/zp/Documents/notes.txt")])
        XCTAssertEqual(creator.receivedDirectory?.path, "/Users/zp/Documents")
        XCTAssertEqual(creator.receivedBaseName, "新建文件.txt")
    }

    func test_perform_onFolder_createsInsideFolder() {
        let creator = FileCreatorSpy()
        let tool = CreateFileTool(fileCreator: creator, inspector: InspectorStub(isDir: true))
        tool.perform(on: [URL(fileURLWithPath: "/Users/zp/Projects")])
        XCTAssertEqual(creator.receivedDirectory?.path, "/Users/zp/Projects")
        XCTAssertEqual(creator.receivedBaseName, "新建文件.txt")
    }

    func test_perform_noUrls_doesNothing() {
        let creator = FileCreatorSpy()
        let tool = CreateFileTool(fileCreator: creator, inspector: InspectorStub(isDir: false))
        tool.perform(on: [])
        XCTAssertNil(creator.receivedDirectory)
    }
}

final class FileCreatorSpy: FileCreator {
    var receivedDirectory: URL?
    var receivedBaseName: String?
    func createFile(in directory: URL, baseName: String) {
        receivedDirectory = directory
        receivedBaseName = baseName
    }
}

final class InspectorStub: FileSystemInspector {
    let isDir: Bool
    init(isDir: Bool) { self.isDir = isDir }
    func isDirectory(_ url: URL) -> Bool { isDir }
}
