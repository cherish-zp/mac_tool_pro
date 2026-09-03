import XCTest
import CoreGraphics

/// TDD: 画布设置 - 圆角 + 阴影（开关、透明度、模糊、偏移）。
final class CanvasSettingsTests: XCTestCase {

    func test_defaultValues() {
        let s = CanvasSettings.default
        XCTAssertEqual(s.cornerRadius, 16, accuracy: 0.001)
        XCTAssertTrue(s.shadowEnabled)
        XCTAssertEqual(s.shadowOpacity, 0.16, accuracy: 0.001)
        XCTAssertGreaterThan(s.shadowBlur, 0)
    }

    func test_toggleShadow() {
        let s = CanvasSettings.default
        XCTAssertTrue(s.shadowEnabled)
        XCTAssertFalse(s.toggledShadow().shadowEnabled)
        XCTAssertTrue(s.toggledShadow().toggledShadow().shadowEnabled)
    }

    func test_setShadowOpacity_clampsTo01() {
        let s = CanvasSettings.default
        XCTAssertEqual(s.withShadowOpacity(0.5).shadowOpacity, 0.5, accuracy: 0.001)
        XCTAssertEqual(s.withShadowOpacity(-0.5).shadowOpacity, 0, accuracy: 0.001)
        XCTAssertEqual(s.withShadowOpacity(1.5).shadowOpacity, 1, accuracy: 0.001)
    }

    func test_nextCornerRadius_cyclesThroughPresets() {
        var s = CanvasSettings(cornerRadius: 0)
        let size = CGSize(width: 200, height: 200)
        s = s.withNextCornerRadius(selectionSize: size)
        XCTAssertEqual(s.cornerRadius, 8, accuracy: 0.001)
        s = s.withNextCornerRadius(selectionSize: size)
        XCTAssertEqual(s.cornerRadius, 16, accuracy: 0.001)
        s = s.withNextCornerRadius(selectionSize: size)
        XCTAssertEqual(s.cornerRadius, 24, accuracy: 0.001)
    }

    func test_nextCornerRadius_wrapsAroundToZero() {
        let s = CanvasSettings(cornerRadius: 32)
        let next = s.withNextCornerRadius(selectionSize: CGSize(width: 200, height: 200))
        XCTAssertEqual(next.cornerRadius, 0, accuracy: 0.001)
    }

    func test_nextCornerRadius_clampsToSmallSelection() {
        let s = CanvasSettings(cornerRadius: 24)
        let next = s.withNextCornerRadius(selectionSize: CGSize(width: 20, height: 20))
        XCTAssertLessThanOrEqual(next.cornerRadius, 10)
    }

    func test_shadowOpacityPersistsWhenToggling() {
        let s = CanvasSettings.default.withShadowOpacity(0.5)
        let toggled = s.toggledShadow()
        XCTAssertEqual(toggled.shadowOpacity, 0.5, accuracy: 0.001)
    }
}

/// TDD: 画布设置跨会话持久化。
/// 背景：用户在会话 A 选了圆角 32 贴图，会话 B 新截图预览却回到默认 16，
/// "截图和贴图不一样"。画布设置必须持久化，会话开始时同步到覆盖层视图。
final class CanvasSettingsStoreTests: XCTestCase {

    private var defaults: UserDefaults!
    private let suiteName = "test-canvas-settings-\(UUID().uuidString)"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func test_load_missingKey_returnsDefault() {
        XCTAssertEqual(CanvasSettingsStore.load(defaults: defaults), CanvasSettings.default)
    }

    func test_saveLoad_roundtrip_customSettings() {
        let custom = CanvasSettings(cornerRadius: 32, shadowEnabled: false, shadowOpacity: 0.4,
                                    shadowBlur: 12, shadowOffset: CGSize(width: 2, height: -3))
        CanvasSettingsStore.save(custom, defaults: defaults)
        XCTAssertEqual(CanvasSettingsStore.load(defaults: defaults), custom)
    }

    func test_save_thenMutate_thenLoadAgain() {
        CanvasSettingsStore.save(CanvasSettings(cornerRadius: 24), defaults: defaults)
        XCTAssertEqual(CanvasSettingsStore.load(defaults: defaults).cornerRadius, 24, accuracy: 0.001)
        CanvasSettingsStore.save(CanvasSettings(cornerRadius: 8), defaults: defaults)
        XCTAssertEqual(CanvasSettingsStore.load(defaults: defaults).cornerRadius, 8, accuracy: 0.001)
    }
}
