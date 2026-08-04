import AppKit
import CoreGraphics

/// 基于 CGEventTap 的全局热键监听器。
/// 在系统处理功能键（亮度/音量等）之前拦截 F1，可消费事件阻止系统默认行为。
/// 需要辅助功能权限（Accessibility）。
final class CGEventTapHotkeyListener {

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var targetKeyCodes: Set<CGKeyCode> = []
    private var handler: ((CGKeyCode) -> Bool)?
    private var hasLoggedAnyKey = false

    /// 启动事件监听，同时监听多个键码。
    /// handler 接收匹配到的键码，返回 true 表示消费该事件（阻止系统默认行为）。
    func start(keyCodes: [CGKeyCode], handler: @escaping (CGKeyCode) -> Bool) {
        self.targetKeyCodes = Set(keyCodes)
        self.handler = handler

        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
            let listener = Unmanaged<CGEventTapHotkeyListener>.fromOpaque(refcon).takeUnretainedValue()

            if type == .keyDown {
                let code = event.getIntegerValueField(.keyboardEventKeycode)
                // 首次收到任意按键时记录一次，确认 tap 在工作
                if !listener.hasLoggedAnyKey {
                    listener.hasLoggedAnyKey = true
                    DiagLog.write("CGEventTap: first keyDown received, keyCode=\(code)")
                }
                let cgCode = CGKeyCode(code)
                if listener.targetKeyCodes.contains(cgCode) {
                    DiagLog.write("CGEventTap: keyCode=\(code) matched target set, dispatching handler")
                    if listener.handler?(cgCode) == true {
                        return nil // 消费事件，阻止系统默认行为
                    }
                    // handler 返回 false -> 不消费，放行给系统
                }
            }
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                DiagLog.write("CGEventTap: was disabled (type=\(type.rawValue)), re-enabling")
                if let tap = listener.eventTap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
            }
            return Unmanaged.passUnretained(event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            DiagLog.write("CGEventTap: tapCreate FAILED")
            return
        }

        DiagLog.write("CGEventTap: tapCreate success for keyCodes=\(keyCodes)")
        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        let enabled = CGEvent.tapIsEnabled(tap: tap)
        DiagLog.write("CGEventTap: tapIsEnabled=\(enabled)")
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            runLoopSource = nil
        }
        eventTap = nil
        handler = nil
    }
}
