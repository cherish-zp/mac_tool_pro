import XCTest
import Foundation

/// TDD: 文件中转站存储 - URL 引用式暂存，不复制文件本体。
final class TransferShelfStoreTests: XCTestCase {

    func test_addStoresURLReference() {
        var store = TransferShelfStore()
        let url = URL(fileURLWithPath: "/tmp/report.pdf")
        let item = store.add(url: url)
        XCTAssertEqual(item?.url, url)
        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items.first?.name, "report.pdf")
    }

    func test_addDuplicateURLIsIgnored() {
        var store = TransferShelfStore()
        let url = URL(fileURLWithPath: "/tmp/report.pdf")
        XCTAssertNotNil(store.add(url: url))
        XCTAssertNil(store.add(url: url))
        XCTAssertEqual(store.items.count, 1)
    }

    func test_removeByID() {
        var store = TransferShelfStore()
        let item = store.add(url: URL(fileURLWithPath: "/tmp/a.txt"))!
        XCTAssertTrue(store.remove(id: item.id))
        XCTAssertFalse(store.remove(id: item.id))
        XCTAssertTrue(store.items.isEmpty)
    }

    func test_persistenceRoundtrip() throws {
        var store = TransferShelfStore()
        store.add(url: URL(fileURLWithPath: "/tmp/a.txt"))
        store.add(url: URL(fileURLWithPath: "/tmp/b.txt"))
        let data = try XCTUnwrap(store.encode())
        let restored = TransferShelfStore.load(from: data)
        XCTAssertEqual(restored.items.map(\.url.path), ["/tmp/a.txt", "/tmp/b.txt"])
    }

    func test_expiredItemWhenFileMissing() {
        let store = TransferShelfStore()
        let item = TransferItem(id: UUID(), url: URL(fileURLWithPath: "/gone.txt"),
                                name: "gone.txt", addedAt: Date())
        XCTAssertFalse(store.isValid(item, fileExists: { _ in false }))
        XCTAssertTrue(store.isValid(item, fileExists: { _ in true }))
    }
}
