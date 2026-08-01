import Carbon.HIToolbox

/// 生产环境热键注册器：基于 Carbon RegisterEventHotKey 实现全局快捷键。
/// 运行在非沙盒菜单栏 App 内，可响应 F1 等全局按键。
final class CarbonHotkeyRegistrar: HotkeyRegistrar {
    var onTrigger: ((UInt32) -> Void)?

    private var registered: [UInt32: EventHotKeyRef] = [:]

    init() {
        // 安装 Carbon 事件处理器（全局热键回调）。
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let handler: EventHandlerUPP = { _, eventRef, userData in
            guard let userData = userData, let eventRef = eventRef else { return noErr }
            let `self` = Unmanaged<CarbonHotkeyRegistrar>.fromOpaque(userData).takeUnretainedValue()
            var refCon: UInt32 = 0
            GetEventParameter(eventRef,
                              EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID),
                              nil,
                              MemoryLayout<UInt32>.size,
                              nil,
                              &refCon)
            self.onTrigger?(refCon)
            return noErr
        }
        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &spec,
                            Unmanaged.passUnretained(self).toOpaque(), nil)
    }

    @discardableResult
    func register(id: UInt32, keyCode: UInt32, modifiers: UInt32) -> Bool {
        let hotKeyID = EventHotKeyID(signature: OSType(0x6D745F70), id: id)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID,
                                         GetApplicationEventTarget(), 0, &ref)
        guard status == noErr, let ref = ref else { return false }
        registered[id] = ref
        return true
    }

    func unregister(id: UInt32) {
        guard let ref = registered.removeValue(forKey: id) else { return }
        UnregisterEventHotKey(ref)
    }
}
