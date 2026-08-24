import AppKit
import CoreGraphics

/// 全局鼠标拖拽监听：CGEventTap 监听按下/拖动/松开，
/// 用 TransferShelfDragPolicy 判定拖拽会话，驱动顶部中转面板显示。
final class MouseDragMonitor {

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var policy = TransferShelfDragPolicy()
    private var onDragStart: (() -> Void)?
    private var onDragEnd: (() -> Void)?
    private var onHotZoneHover: (() -> Void)?

    /// 启动监听。回调自动派发到主线程。
    /// onHotZoneHover：拖拽过程中鼠标进入任意屏幕顶部中央热区（几何兜底）。
    func start(onDragStart: @escaping () -> Void,
               onDragEnd: @escaping () -> Void,
               onHotZoneHover: @escaping () -> Void) {
        stop()
        self.onDragStart = onDragStart
        self.onDragEnd = onDragEnd
        self.onHotZoneHover = onHotZoneHover
        policy.reset()

        let mask: CGEventMask =
            (1 << CGEventType.leftMouseDown.rawValue) |
            (1 << CGEventType.leftMouseDragged.rawValue) |
            (1 << CGEventType.leftMouseUp.rawValue)

        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
            let monitor = Unmanaged<MouseDragMonitor>.fromOpaque(refcon).takeUnretainedValue()
            monitor.handle(type: type, event: event)
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let tap = monitor.eventTap {
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
            DiagLog.write("MouseDragMonitor: tapCreate FAILED")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        DiagLog.write("MouseDragMonitor: started")
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            runLoopSource = nil
        }
        eventTap = nil
        onDragStart = nil
        onDragEnd = nil
        policy.reset()
    }

    private func handle(type: CGEventType, event: CGEvent) {
        // CG 全局坐标（左上原点）转 AppKit 坐标（左下原点）
        let cg = event.location
        let mainScreenHeight = NSScreen.screens.first?.frame.height ?? 0
        let location = CGPoint(x: cg.x, y: mainScreenHeight - cg.y)

        switch type {
        case .leftMouseDown:
            policy.mouseDown(at: location)
        case .leftMouseDragged:
            if policy.mouseDragged(to: location) {
                DispatchQueue.main.async { [weak self] in
                    self?.onDragStart?()
                }
            }
            if policy.isDragging {
                let inHotZone = NSScreen.screens.contains { screen in
                    TransferShelfLayoutSpec.isInHotZone(
                        location: location,
                        visibleFrame: screen.visibleFrame
                    )
                }
                if policy.hotZoneHoverChanged(inside: inHotZone), inHotZone {
                    DispatchQueue.main.async { [weak self] in
                        self?.onHotZoneHover?()
                    }
                }
            }
        case .leftMouseUp:
            if policy.isDragging {
                policy.mouseUp()
                DispatchQueue.main.async { [weak self] in
                    self?.onDragEnd?()
                }
            } else {
                policy.mouseUp()
            }
        default:
            break
        }
    }
}
