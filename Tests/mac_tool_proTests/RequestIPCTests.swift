import XCTest

/// TDD: 扩展->App 的文件请求 IPC。
/// - RequestFileCreator: 扩展把 {目标目录, 文件名} 写成队列里的 JSON 文件。
/// - RequestProcessor: App 读队列 JSON -> 真正建文件 -> 删请求。
final class RequestIPCTests: XCTestCase {

    func test_creator_writesRequestJson() throws {
        let queue = makeTempDir()
        let creator = RequestFileCreator(queueDirectory: queue)
        creator.createFile(in: URL(fileURLWithPath: "/target/dir"), baseName: "新建文件.txt")
        let jsons = try FileManager.default.contentsOfDirectory(atPath: queue.path).filter { $0.hasSuffix(".json") }
        XCTAssertEqual(jsons.count, 1)
        let data = try Data(contentsOf: queue.appendingPathComponent(jsons[0]))
        let req = try JSONDecoder().decode(CreateFileRequest.self, from: data)
        XCTAssertEqual(req.directory.path, "/target/dir")
        XCTAssertEqual(req.baseName, "新建文件.txt")
    }

    func test_processor_createsFileAndDeletesRequest() throws {
        let queue = makeTempDir()
        let target = makeTempDir()
        let req = CreateFileRequest(directory: target, baseName: "hi.txt")
        try JSONEncoder().encode(req).write(to: queue.appendingPathComponent("abc.json"))
        let processor = RequestProcessor(queueDirectory: queue, service: CreateFileService())
        let n = processor.processAll()
        XCTAssertEqual(n, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: target.appendingPathComponent("hi.txt").path))
        let remaining = try FileManager.default.contentsOfDirectory(atPath: queue.path)
        XCTAssertTrue(remaining.isEmpty)
    }

    func test_processor_skipsAndRemovesMalformedRequest() throws {
        let queue = makeTempDir()
        let target = makeTempDir()
        try Data("not json".utf8).write(to: queue.appendingPathComponent("bad.json"))
        let processor = RequestProcessor(queueDirectory: queue, service: CreateFileService())
        _ = processor.processAll()
        let remaining = (try? FileManager.default.contentsOfDirectory(atPath: queue.path)) ?? []
        XCTAssertTrue(remaining.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: target.appendingPathComponent("hi.txt").path))
    }

    private func makeTempDir() -> URL {
        let d = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }
}
