import XCTest

/// TDD: App 侧建文件服务 - 按目录现有文件去重后创建空文件。
final class CreateFileServiceTests: XCTestCase {

    func test_createsWithBaseName_whenNoneExists() throws {
        let dir = makeTempDir()
        let url = CreateFileService().createFile(in: dir, baseName: "新建文件.txt")
        XCTAssertEqual(url?.lastPathComponent, "新建文件.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url!.path))
    }

    func test_createsUniqueName_whenExists() throws {
        let dir = makeTempDir()
        try Data().write(to: dir.appendingPathComponent("新建文件.txt"))
        let url = CreateFileService().createFile(in: dir, baseName: "新建文件.txt")
        XCTAssertEqual(url?.lastPathComponent, "新建文件 2.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url!.path))
    }

    func test_createsUniqueName_whenMultipleExist() throws {
        let dir = makeTempDir()
        try Data().write(to: dir.appendingPathComponent("新建文件.txt"))
        try Data().write(to: dir.appendingPathComponent("新建文件 2.txt"))
        let url = CreateFileService().createFile(in: dir, baseName: "新建文件.txt")
        XCTAssertEqual(url?.lastPathComponent, "新建文件 3.txt")
    }

    func test_createsFromRequest() throws {
        let dir = makeTempDir()
        let url = CreateFileService().createFile(request: CreateFileRequest(directory: dir, baseName: "x.txt"))
        XCTAssertEqual(url?.lastPathComponent, "x.txt")
    }

    private func makeTempDir() -> URL {
        let d = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }
}
