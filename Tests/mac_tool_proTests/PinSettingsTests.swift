import XCTest

/// TDD: 贴图呼吸灯设置持久化 - 默认顶部横条，读写往返，损坏回退默认。
final class PinSettingsTests: XCTestCase {

    private var tempURL: URL!

    override func setUp() {
        super.setUp()
        tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("pin-settings-test-\(UUID().uuidString).json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempURL)
        super.tearDown()
    }

    func test_defaultState_indicatorStyleIsTopBar() {
        let state = PinSettingsState()
        XCTAssertEqual(state.indicatorStyle, .topBar, "默认应为顶部横条呼吸灯")
    }

    func test_load_missingFile_returnsDefaultState() {
        let store = PinSettingsStore(fileURL: tempURL)
        XCTAssertEqual(store.load(), PinSettingsState(), "无配置文件时应返回默认（横条）")
    }

    func test_saveLoad_roundTrip_cornerDot() {
        let store = PinSettingsStore(fileURL: tempURL)
        store.save(PinSettingsState(indicatorStyle: .cornerDot))
        XCTAssertEqual(store.load().indicatorStyle, .cornerDot, "保存后应能读回圆点样式")
    }

    func test_load_corruptFile_fallsBackToDefault() {
        try? Data("not json".utf8).write(to: tempURL)
        let store = PinSettingsStore(fileURL: tempURL)
        XCTAssertEqual(store.load(), PinSettingsState(), "损坏文件应回退默认（横条）")
    }
}
