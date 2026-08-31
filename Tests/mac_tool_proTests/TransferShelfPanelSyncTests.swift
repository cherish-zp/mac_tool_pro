import XCTest
import AppKit

/// TDD: 中转站面板与暂存库的显示同步。
/// 修复的 bug(截图为证):重启后面板显示空态占位「拖文件到这里暂存」,
/// 再拖入库内的同一文件也毫无反应——
/// 1) showPanel() 从不把 store 里已有的条目渲染到新建面板;
/// 2) accept() 在拖入 URL 全部命中去重时直接 return,不重新渲染。
/// 结果文件早已入库,面板却永远空白。
@MainActor
final class TransferShelfPanelSyncTests: XCTestCase {

    private var workDir: URL!
    private var storageURL: URL!

    override func setUpWithError() throws {
        workDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("shelf-sync-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)
        storageURL = workDir.appendingPathComponent("transfer_shelf.json")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: workDir)
    }

    /// 在临时目录造一个真实存在的文件(purge 巡检要求文件存在)。
    private func makeRealFile(_ name: String) throws -> URL {
        let url = workDir.appendingPathComponent(name)
        try Data("x".utf8).write(to: url)
        return url
    }

    func test_showPanelRendersPersistedItems() throws {
        let url = try makeRealFile("already-staged.zip")
        var store = TransferShelfStore()
        store.add(url: url)
        let controller = TransferShelfPanelController(store: store, storageURL: storageURL)

        controller.showPanel()

        let itemViews = TransferShelfPanelSyncTests.findAll(in: controller.shelfView, of: TransferShelfItemView.self)
        XCTAssertEqual(itemViews.count, 1, "showPanel 必须把库内已有条目渲染到面板,而不是空态占位")
        let placeholders = TransferShelfPanelSyncTests.findAll(in: controller.shelfView, of: NSTextField.self)
            .filter { $0.stringValue == "拖文件到这里暂存" }
        XCTAssertTrue(placeholders.allSatisfy(\.isHidden), "库内有条目时不得显示空态占位")
    }

    func test_acceptDuplicateUrlStillRendersItems() throws {
        let url = try makeRealFile("duplicate.zip")
        var store = TransferShelfStore()
        store.add(url: url)
        let controller = TransferShelfPanelController(store: store, storageURL: storageURL)
        controller.showPanel()

        // 再拖入库内的同一文件:去重不新增条目,但面板必须同步显示已有条目。
        controller.accept(urls: [url])

        let itemViews = TransferShelfPanelSyncTests.findAll(in: controller.shelfView, of: TransferShelfItemView.self)
        XCTAssertEqual(itemViews.count, 1, "去重后仍应渲染库内条目,给用户可见反馈")
    }

    func test_acceptNewUrlRendersItem() throws {
        let controller = TransferShelfPanelController(store: TransferShelfStore(), storageURL: storageURL)
        controller.showPanel()

        let url = try makeRealFile("fresh.txt")
        controller.accept(urls: [url])

        let itemViews = TransferShelfPanelSyncTests.findAll(in: controller.shelfView, of: TransferShelfItemView.self)
        XCTAssertEqual(itemViews.count, 1, "拖入新文件应立即显示")
    }

    private static func findAll<T: NSView>(in root: NSView, of type: T.Type) -> [T] {
        var found: [T] = []
        for sub in root.subviews {
            if let hit = sub as? T { found.append(hit) }
            found.append(contentsOf: findAll(in: sub, of: type))
        }
        return found
    }
}
