import XCTest

/// TDD: 全局热键抽象。Carbon keyCode + 规范化修饰键，Codable 便于持久化与设置。
final class HotkeyTests: XCTestCase {

    func test_codableRoundTrip() throws {
        let h = Hotkey(keyCode: 122, modifiers: ModifierKey.command)
        let data = try JSONEncoder().encode(h)
        let back = try JSONDecoder().decode(Hotkey.self, from: data)
        XCTAssertEqual(back, h)
    }

    func test_normalizesExtraModifierBits() {
        // alphaLock(0x0400)、fnKey(0x8000) 等非主修饰键位应被丢弃
        let h = Hotkey(keyCode: 122, modifiers: ModifierKey.command | 0x0400 | 0x8000)
        XCTAssertEqual(h.modifiers, ModifierKey.command)
    }

    func test_f1_default() {
        XCTAssertEqual(Hotkey.f1, Hotkey(keyCode: 122, modifiers: 0))
    }

    func test_f3_default() {
        XCTAssertEqual(Hotkey.f3, Hotkey(keyCode: 99, modifiers: 0))
    }

    func test_equality() {
        XCTAssertEqual(Hotkey(keyCode: 122, modifiers: ModifierKey.command),
                       Hotkey(keyCode: 122, modifiers: ModifierKey.command))
        XCTAssertNotEqual(Hotkey(keyCode: 122, modifiers: 0),
                          Hotkey(keyCode: 122, modifiers: ModifierKey.command))
    }

    func test_hashableInSet() {
        let set: Set<Hotkey> = [Hotkey.f1, Hotkey.f1, Hotkey(keyCode: 45, modifiers: ModifierKey.command)]
        XCTAssertEqual(set.count, 2)
    }
}


/// TDD: 功能键显示名 - 菜单栏模块项标注快捷键（如「文件中转 (F2)」）。
final class HotkeyFunctionKeyLabelTests: XCTestCase {

    func test_f1Label() {
        XCTAssertEqual(Hotkey.f1.functionKeyLabel, "F1")
    }

    func test_f2Label() {
        XCTAssertEqual(Hotkey(keyCode: 120).functionKeyLabel, "F2")
    }

    func test_f3Label() {
        XCTAssertEqual(Hotkey.f3.functionKeyLabel, "F3")
    }

    func test_nonFunctionKeyReturnsNil() {
        XCTAssertNil(Hotkey(keyCode: 0).functionKeyLabel)
        XCTAssertNil(Hotkey(keyCode: 50, modifiers: ModifierKey.command).functionKeyLabel)
    }
}
