import XCTest

/// TDD: 热键管理器 - 注册/注销/分发，注入 HotkeyRegistrar 便于测试。
final class HotkeyManagerTests: XCTestCase {

    func test_register_dispatchesHandler() {
        let registrar = FakeHotkeyRegistrar()
        let manager = HotkeyManager(registrar: registrar)
        var fired = false
        let id = manager.register(Hotkey.f1) { fired = true }
        XCTAssertNotNil(id)
        registrar.onTrigger?(id!)   // 模拟 F1 按下
        XCTAssertTrue(fired)
    }

    func test_register_sameHotkey_conflict_returnsNil() {
        let manager = HotkeyManager(registrar: FakeHotkeyRegistrar())
        XCTAssertNotNil(manager.register(Hotkey.f1) {})
        XCTAssertNil(manager.register(Hotkey.f1) {})
    }

    func test_unregister_removesHandler() {
        let registrar = FakeHotkeyRegistrar()
        let manager = HotkeyManager(registrar: registrar)
        var fired = false
        let id = manager.register(Hotkey.f1) { fired = true }
        manager.unregister(Hotkey.f1)
        registrar.onTrigger?(id!)
        XCTAssertFalse(fired)
    }

    func test_differentHotkeys_dispatchIndependently() {
        let registrar = FakeHotkeyRegistrar()
        let manager = HotkeyManager(registrar: registrar)
        var a = 0, b = 0
        let idA = manager.register(Hotkey.f1) { a += 1 }
        let idB = manager.register(Hotkey(keyCode: 45, modifiers: ModifierKey.command)) { b += 1 }
        registrar.onTrigger?(idA!)
        registrar.onTrigger?(idB!)
        XCTAssertEqual(a, 1)
        XCTAssertEqual(b, 1)
    }

    func test_registerFailure_returnsNil() {
        let manager = HotkeyManager(registrar: FailingRegistrar())
        XCTAssertNil(manager.register(Hotkey.f1) {})
    }
}

final class FakeHotkeyRegistrar: HotkeyRegistrar {
    var onTrigger: ((UInt32) -> Void)?
    var registered: [UInt32: Hotkey] = [:]
    func register(id: UInt32, keyCode: UInt32, modifiers: UInt32) -> Bool {
        registered[id] = Hotkey(keyCode: keyCode, modifiers: modifiers)
        return true
    }
    func unregister(id: UInt32) { registered.removeValue(forKey: id) }
}

final class FailingRegistrar: HotkeyRegistrar {
    var onTrigger: ((UInt32) -> Void)?
    func register(id: UInt32, keyCode: UInt32, modifiers: UInt32) -> Bool { false }
    func unregister(id: UInt32) {}
}
