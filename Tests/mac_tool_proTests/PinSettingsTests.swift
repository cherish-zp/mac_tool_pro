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

    // MARK: - 呼吸灯外观（高度 / 距顶部距离 / 颜色）

    func test_defaultState_appearanceDefaults() {
        let state = PinSettingsState()
        XCTAssertEqual(state.indicatorHeight, 4, "默认呼吸灯高度应为 4pt")
        XCTAssertEqual(state.indicatorTopInset, 2, "默认距顶部间距应为 2pt")
        XCTAssertEqual(state.indicatorColorHex, PinIndicatorColor.defaultHex, "默认颜色应为亮绿色")
    }

    func test_init_clampsAppearanceToValidRanges() {
        let state = PinSettingsState(indicatorHeight: 99, indicatorTopInset: -5)
        XCTAssertEqual(state.indicatorHeight, PinIndicatorAppearance.heightRange.upperBound, "高度应夹取到上限")
        XCTAssertEqual(state.indicatorTopInset, PinIndicatorAppearance.topInsetRange.lowerBound, "间距应夹取到下限")
        let small = PinSettingsState(indicatorHeight: 0, indicatorTopInset: 50)
        XCTAssertEqual(small.indicatorHeight, PinIndicatorAppearance.heightRange.lowerBound)
        XCTAssertEqual(small.indicatorTopInset, PinIndicatorAppearance.topInsetRange.upperBound)
    }

    func test_saveLoad_roundTrip_fullAppearance() {
        let store = PinSettingsStore(fileURL: tempURL)
        store.save(PinSettingsState(indicatorStyle: .topBar, indicatorHeight: 6, indicatorTopInset: 5,
                                    indicatorColorHex: "FF3B30"))
        let loaded = store.load()
        XCTAssertEqual(loaded.indicatorHeight, 6)
        XCTAssertEqual(loaded.indicatorTopInset, 5)
        XCTAssertEqual(loaded.indicatorColorHex, "FF3B30")
    }

    func test_load_legacyJSON_withoutAppearanceFields_fallsBackToDefaults() {
        // 旧版本配置文件只有 indicatorStyle 字段，解码后新字段必须回退默认而非解码失败
        try? Data("{\"indicatorStyle\":\"cornerDot\"}".utf8).write(to: tempURL)
        let store = PinSettingsStore(fileURL: tempURL)
        let loaded = store.load()
        XCTAssertEqual(loaded.indicatorStyle, .cornerDot)
        XCTAssertEqual(loaded.indicatorHeight, 4)
        XCTAssertEqual(loaded.indicatorTopInset, 2)
        XCTAssertEqual(loaded.indicatorColorHex, PinIndicatorColor.defaultHex)
    }
}
