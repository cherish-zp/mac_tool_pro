import XCTest
import Carbon.HIToolbox

/// TDD: 验证 Carbon EventHotKeyID 的内存布局，证明 GetEventParameter 只读 4 字节
/// 会得到 signature 而非 id——这正是 F1 无反应的根因。
final class CarbonHotkeyIDTests: XCTestCase {

    /// EventHotKeyID = { signature: UInt32, id: UInt32 }，id 在偏移 4 处。
    func test_eventHotKeyID_idAtOffset4() {
        let signature: UInt32 = 0x6D745F70
        let id: UInt32 = 42
        let hotKeyID = EventHotKeyID(signature: signature, id: id)

        // 前 4 字节是 signature（旧代码只读 4 字节 -> 拿到 signature，bug！）
        let firstWord = withUnsafeBytes(of: hotKeyID) { $0.load(as: UInt32.self) }
        XCTAssertEqual(firstWord, signature, "前 4 字节应为 signature")

        // 偏移 4 处才是 id
        let idWord = withUnsafeBytes(of: hotKeyID) { $0.load(fromByteOffset: 4, as: UInt32.self) }
        XCTAssertEqual(idWord, id, "偏移 4 处应为 id")

        // 直接取 .id 字段
        XCTAssertEqual(hotKeyID.id, id)
    }

    /// 只读 4 字节（旧 bug）得到的是 signature，不是 id。
    func test_readingOnly4Bytes_givesSignatureNotID() {
        let signature: UInt32 = 0x6D745F70
        let id: UInt32 = 7
        let hotKeyID = EventHotKeyID(signature: signature, id: id)

        // 模拟旧代码：只读 4 字节到 UInt32
        var buffer: UInt32 = 0
        withUnsafeBytes(of: hotKeyID) { bytes in
            buffer = bytes.load(as: UInt32.self)  // 只取前 4 字节
        }
        XCTAssertEqual(buffer, signature, "旧代码只读 4 字节得到 signature 而非 id")
        XCTAssertNotEqual(buffer, id, "旧代码无法得到正确的 id")
    }

    /// 修复后：读取完整 EventHotKeyID（8 字节）再取 .id。
    func test_readingFullStruct_givesCorrectID() {
        let signature: UInt32 = 0x6D745F70
        let id: UInt32 = 7
        let hotKeyID = EventHotKeyID(signature: signature, id: id)

        // 模拟修复后代码：读完整 8 字节
        var full = EventHotKeyID(signature: 0, id: 0)
        withUnsafeMutableBytes(of: &full) { dst in
            withUnsafeBytes(of: hotKeyID) { src in
                dst.copyBytes(from: src)
            }
        }
        XCTAssertEqual(full.id, id, "修复后应正确提取 id")
        XCTAssertEqual(full.signature, signature)
    }
}
