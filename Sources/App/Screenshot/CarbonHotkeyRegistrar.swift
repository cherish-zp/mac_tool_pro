import Carbon.HIToolbox
import Foundation

/// 生产环境热键注册器：基于 Carbon RegisterEventHotKey 实现全局快捷键。
/// 运行在非沙盒菜单栏 App 内，可响应 F1 等全局按键。
final class CarbonHotkeyRegistrar: HotkeyRegistrar {
    var onTrigger: ((UInt32) -> Void)?

    private var registered: [UInt32: EventHotKeyRef] = [:]
    init() {
        DiagLog.write("CarbonHotkeyRegistrar init")

        // 安装 Carbon 事件处理器（全局热键回调）。
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let handler: EventHandlerUPP = { _, eventRef, userData in
            guard let userData = userData, let eventRef = eventRef else { return noErr }
            let `self` = Unmanaged<CarbonHotkeyRegistrar>.fromOpaque(userData).takeUnretainedValue()
            // 修复：读取完整 EventHotKeyID（8 字节），取 .id 字段。
            // 旧代码只读 4 字节(UInt32)，拿到的是 signature 而非 id，导致回调分发失败。
            var hotKeyID = EventHotKeyID(signature: 0, id: 0)
            let status = GetEventParameter(eventRef,
                                           EventParamName(kEventParamDirectObject),
                                           EventParamType(typeEventHotKeyID),
                                           nil,
                                           MemoryLayout<EventHotKeyID>.size,
                                           nil,
                                           &hotKeyID)
            if status != noErr {
                DiagLog.write("GetEventParameter failed: \(status)")
                return noErr
            }
            DiagLog.write("hotkey callback: id=\(hotKeyID.id) signature=0x\(String(hotKeyID.signature, radix: 16))")
            self.onTrigger?(hotKeyID.id)
            return noErr
        }
        let installStatus = InstallEventHandler(GetApplicationEventTarget(), handler, 1, &spec,
                                                Unmanaged.passUnretained(self).toOpaque(), nil)
        DiagLog.write("InstallEventHandler status: \(installStatus)")
    }

    @discardableResult
    func register(id: UInt32, keyCode: UInt32, modifiers: UInt32) -> Bool {
        let hotKeyID = EventHotKeyID(signature: OSType(0x6D745F70), id: id)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID,
                                         GetApplicationEventTarget(), 0, &ref)
        DiagLog.write("RegisterEventHotKey id=\(id) keyCode=\(keyCode) modifiers=\(modifiers) status=\(status)")
        guard status == noErr, let ref = ref else {
            DiagLog.write("RegisterEventHotKey FAILED for id=\(id)")
            return false
        }
        registered[id] = ref
        DiagLog.write("RegisterEventHotKey success for id=\(id)")
        return true
    }

    func unregister(id: UInt32) {
        guard let ref = registered.removeValue(forKey: id) else { return }
        UnregisterEventHotKey(ref)
        DiagLog.write("unregister id=\(id)")
    }

}
