import XCTest

/// TDD: 在已存在文件名集合中为 baseName 生成不冲突的文件名。
final class FileNameResolverTests: XCTestCase {

    func test_noConflict_returnsBaseName() {
        XCTAssertEqual(FileNameResolver.unique(baseName: "新建文件.txt", existingNames: []), "新建文件.txt")
    }

    func test_conflict_returnsNumbered() {
        XCTAssertEqual(
            FileNameResolver.unique(baseName: "新建文件.txt", existingNames: ["新建文件.txt"]),
            "新建文件 2.txt"
        )
    }

    func test_multipleConflicts_increments() {
        let existing: Set<String> = ["新建文件.txt", "新建文件 2.txt", "新建文件 3.txt"]
        XCTAssertEqual(FileNameResolver.unique(baseName: "新建文件.txt", existingNames: existing), "新建文件 4.txt")
    }

    func test_noExtension_conflict() {
        XCTAssertEqual(FileNameResolver.unique(baseName: "notes", existingNames: ["notes"]), "notes 2")
    }

    func test_caseSensitiveComparison() {
        XCTAssertEqual(
            FileNameResolver.unique(baseName: "File.TXT", existingNames: ["file.txt"]),
            "File.TXT"
        )
    }
}
