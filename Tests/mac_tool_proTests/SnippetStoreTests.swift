import XCTest
import Foundation

/// TDD: 快速片段存储纯逻辑 - 增删改查 + 搜索。
final class SnippetStoreTests: XCTestCase {

    func test_add_returnsSnippet() {
        var store = SnippetStore()
        let snippet = store.add(key: "邮箱", content: "test@example.com")
        XCTAssertNotNil(snippet)
        XCTAssertEqual(snippet?.key, "邮箱")
        XCTAssertEqual(snippet?.content, "test@example.com")
        XCTAssertEqual(store.snippets.count, 1)
    }

    func test_add_duplicateKey_returnsNil() {
        var store = SnippetStore()
        store.add(key: "邮箱", content: "a@b.com")
        let dup = store.add(key: "邮箱", content: "c@d.com")
        XCTAssertNil(dup, "重复 key 不应添加")
        XCTAssertEqual(store.snippets.count, 1)
    }

    func test_update_existingSnippet() {
        var store = SnippetStore()
        let s = store.add(key: "邮箱", content: "old@x.com")!
        let ok = store.update(id: s.id, key: "邮箱", content: "new@x.com")
        XCTAssertTrue(ok)
        XCTAssertEqual(store.snippets.first?.content, "new@x.com")
    }

    func test_update_nonexistent_returnsFalse() {
        var store = SnippetStore()
        let ok = store.update(id: UUID(), key: "x", content: "y")
        XCTAssertFalse(ok)
    }

    func test_update_toDuplicateKey_returnsFalse() {
        var store = SnippetStore()
        store.add(key: "A", content: "aaa")
        let b = store.add(key: "B", content: "bbb")!
        let ok = store.update(id: b.id, key: "A", content: "bbb")
        XCTAssertFalse(ok, "不能改为已存在的 key")
    }

    func test_delete_existingSnippet() {
        var store = SnippetStore()
        let s = store.add(key: "邮箱", content: "x@y.com")!
        let ok = store.delete(id: s.id)
        XCTAssertTrue(ok)
        XCTAssertEqual(store.snippets.count, 0)
    }

    func test_delete_nonexistent_returnsFalse() {
        var store = SnippetStore()
        XCTAssertFalse(store.delete(id: UUID()))
    }

    func test_contentForKey_found() {
        var store = SnippetStore()
        store.add(key: "邮箱", content: "test@example.com")
        XCTAssertEqual(store.content(forKey: "邮箱"), "test@example.com")
    }

    func test_contentForKey_notFound_returnsNil() {
        var store = SnippetStore()
        XCTAssertNil(store.content(forKey: "不存在"))
    }

    func test_contentForKey_caseInsensitive() {
        var store = SnippetStore()
        store.add(key: "Email", content: "a@b.com")
        XCTAssertEqual(store.content(forKey: "email"), "a@b.com")
    }

    func test_search_matchesKey() {
        var store = SnippetStore()
        store.add(key: "SQL查询", content: "SELECT * FROM users")
        store.add(key: "邮箱", content: "test@x.com")
        let results = store.search(query: "sql")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.key, "SQL查询")
    }

    func test_search_matchesContent() {
        var store = SnippetStore()
        store.add(key: "模板", content: "SELECT * FROM orders WHERE date > '2024'")
        let results = store.search(query: "orders")
        XCTAssertEqual(results.count, 1)
    }

    func test_search_emptyQuery_returnsAll() {
        var store = SnippetStore()
        store.add(key: "A", content: "aaa")
        store.add(key: "B", content: "bbb")
        XCTAssertEqual(store.search(query: "").count, 2)
    }

    func test_loadFromJSON_roundTrip() {
        var store = SnippetStore()
        store.add(key: "邮箱", content: "test@x.com")
        store.add(key: "SQL", content: "SELECT 1")
        let data = store.encodeToJSON()!

        var loaded = SnippetStore()
        loaded.loadFromJSON(data)
        XCTAssertEqual(loaded.snippets.count, 2)
        XCTAssertEqual(loaded.content(forKey: "邮箱"), "test@x.com")
        XCTAssertEqual(loaded.content(forKey: "SQL"), "SELECT 1")
    }
}
