import AppKit
import CoreGraphics

/// 截图协调器：串联「捕获画面 -> 全屏覆盖层选区 -> 工具条编辑 -> 复制/保存/贴图」全流程。
final class ScreenshotCoordinator {

    private let captureService = ScreenCaptureService()
    private var overlayWindows: [ScreenshotOverlayWindow] = []
    private var toolbar: ScreenshotToolbar?
    private var pinWindows: [PinWindow] = []
    private let config = ScreenshotConfig()
    private var activeOverlay: ScreenshotOverlayWindow?
    private var selectionRect: CGRect?
    private var escMonitor: Any?
    /// 选区超时定时器：覆盖层显示后若用户长时间未操作（如全屏下覆盖层不可见），自动清理。
    private var idleTimeoutTimer: Timer?

    /// 截图会话结束时回调（用于重置 ScreenshotSession 状态）。
    var onFinished: (() -> Void)?

    func start() {
        DiagLog.write("ScreenshotCoordinator.start()")

        // 0. 先清理可能残留的旧覆盖层（防止叠加变黑）
        cleanupExistingOverlays()

        // 1. 请求屏幕录制权限
        captureService.requestPermission()

        // 2. 捕获所有屏幕画面（在显示覆盖层之前）
        let displays = captureService.captureAllDisplays()
        DiagLog.write("Captured \(displays.count) display(s)")
        guard !displays.isEmpty else { finish(); return }

        // 不切换 activationPolicy：accessory App 切到 .regular 会导致系统切换 Space，
        // 在其他 App 全屏时覆盖层无法显示。保持 .accessory + activate 即可在当前 Space 显示。
        NSApp.activate(ignoringOtherApps: true)

        // 4. 为每个屏幕创建覆盖层窗口
        overlayWindows = displays.compactMap { display -> ScreenshotOverlayWindow? in
            DiagLog.write("Display: id=\(display.displayID) frame=\(display.frame) imageSize=\(display.image.width)x\(display.image.height)")
            guard let screen = screenMatching(displayID: display.displayID, frame: display.frame) else {
                DiagLog.write("screenMatching returned nil for display \(display.displayID)")
                return nil
            }
            DiagLog.write("Matched screen: \(screen.frame)")
            let window = ScreenshotOverlayWindow(screen: screen, capturedImage: display.image)
            window.acceptsMouseMovedEvents = true
            let view = window.overlayView!
            view.onSelectionComplete = { [weak self, weak window] rect in
                self?.handleSelectionComplete(rect: rect, window: window)
            }
            view.onCancel = { [weak self] in self?.cancel() }
            window.orderFrontRegardless()
            DiagLog.write("Window ordered front: frame=\(window.frame) level=\(window.level.rawValue)")
            return window
        }

        DiagLog.write("Created \(overlayWindows.count) overlay window(s)")

        // 仅将主显示器窗口设为 key，确保键盘事件和首次鼠标点击直达视图
        if let keyWindow = overlayWindows.first(where: { $0.screen == NSScreen.main }) ?? overlayWindows.first {
            keyWindow.makeKeyAndOrderFront(nil)
            keyWindow.makeFirstResponder(keyWindow.overlayView)
            DiagLog.write("Key window set: frame=\(keyWindow.frame)")
        }

       // 5. 安装 ESC 本地事件监听（不依赖 first responder）
       installEscMonitor()

       // 6. 自动检测鼠标下窗口区域作为初始选区
       autoDetectSelection()

       // 6. 空闲超时安全网：若覆盖层不可见（如全屏 Space 下），15 秒后自动清理
       // 7. 空闲超时安全网：若覆盖层不可见（如全屏 Space 下），15 秒后自动清理
       startIdleTimeout()
    }

    /// 启动空闲超时定时器：用户未做任何操作（选区）时自动结束会话。
    private func startIdleTimeout() {
        idleTimeoutTimer?.invalidate()
        idleTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { [weak self] _ in
            guard let self = self, !self.overlayWindows.isEmpty else { return }
            DiagLog.write("Idle timeout: no interaction within 15s, finishing screenshot (overlay may not be visible)")
            self.finish()
        }
    }

    /// 取消空闲超时定时器（用户已开始操作）。
    private func cancelIdleTimeout() {
        idleTimeoutTimer?.invalidate()
        idleTimeoutTimer = nil
    }

    /// 自动检测鼠标所在屏幕下最顶层窗口的区域，作为初始选区。
    private func autoDetectSelection() {
        let mouseLocation = NSEvent.mouseLocation
        guard let mouseScreen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) else { return }
        guard let overlay = overlayWindows.first(where: { $0.screen == mouseScreen }) else { return }
        guard let detected = detectWindowUnderMouse(on: mouseScreen) else { return }

        let view = overlay.overlayView!
        let clamped = SelectionRect.clamp(detected, to: view.bounds)
        guard SelectionRect.isValid(clamped, minimum: 10) else { return }
        view.selectionRect = clamped
        view.needsDisplay = true
        DiagLog.write("Auto-detected selection: \(clamped) on screen \(mouseScreen.frame)")
    }

    /// 通过 CGWindowList 检测鼠标下最顶层的普通窗口（排除自身），返回视图坐标矩形。
    private func detectWindowUnderMouse(on screen: NSScreen) -> CGRect? {
        let mouse = NSEvent.mouseLocation
        let primaryHeight = NSScreen.screens.first?.frame.height ?? screen.frame.height
        // CG 坐标原点在主屏左上，NSScreen 原点在左下，需翻转 y 轴
        let cgMouse = CGPoint(x: mouse.x, y: primaryHeight - mouse.y)

        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID
        ) as? [[String: Any]] else { return nil }

        let ourPid = ProcessInfo.processInfo.processIdentifier
        let windows: [WindowInfo] = windowList.compactMap { info in
            guard let boundsRef = info[kCGWindowBounds as String] as? NSDictionary,
                  let bounds = CGRect(dictionaryRepresentation: boundsRef),
                  let layer = info[kCGWindowLayer as String] as? Int,
                  let pid = info[kCGWindowOwnerPID as String] as? Int,
                  let windowId = info[kCGWindowNumber as String] as? Int else { return nil }
            return WindowInfo(bounds: bounds, layer: layer, ownerPid: Int32(pid), windowId: windowId)
        }

        guard let detected = WindowDetector.topmostWindow(
            at: cgMouse, in: windows, excludingPids: [ourPid]
        ) else { return nil }

        return ScreenCoordinateConverter.cgRectToViewRect(
            detected.bounds, screenFrame: screen.frame, primaryScreenHeight: primaryHeight
        )
    }

    /// 清理残留的旧覆盖层窗口（防止多次 F1 导致叠加变黑）。
    private func cleanupExistingOverlays() {
        if !overlayWindows.isEmpty {
            DiagLog.write("Cleaning up \(overlayWindows.count) existing overlay window(s)")
            for w in overlayWindows { w.orderOut(nil) }
            overlayWindows.removeAll()
        }
        toolbar?.cleanupColorPanel()
        toolbar?.orderOut(nil)
        toolbar = nil
        activeOverlay = nil
        selectionRect = nil
    }

    /// 安装 ESC 键本地监听：无论 first responder 是谁都能捕获 ESC。
    private func installEscMonitor() {
        escMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == ScreenshotSession.escKeyCode {
                // 优先取消文字编辑；无文字编辑时才取消整个截图
                if self?.activeOverlay?.overlayView?.cancelTextEditingIfActive() == true {
                    return nil
                }
               DiagLog.write("ESC pressed via local monitor, cancelling screenshot")
               self?.cancel()
               return nil // 消费事件
           }
            // F3 = 贴图当前选区（本地监听备份，覆盖层为 key 窗口时可靠触发）
            if event.keyCode == ScreenshotHotkeyAction.f3KeyCode {
                DiagLog.write("F3 pressed via local monitor, pinning selection")
                self?.pinCurrentSelection()
                return nil
            }
            return event
        }
        DiagLog.write("ESC + F3 local monitor installed")
    }

    // MARK: 选区完成

    private func handleSelectionComplete(rect: CGRect, window: ScreenshotOverlayWindow?) {
        guard let window = window else { return }
        // 用户已开始操作，取消空闲超时
        cancelIdleTimeout()
        activeOverlay = window
        selectionRect = rect
       window.overlayView!.isEditMode = true
        // 不自动选标注工具：默认光标模式，用户从工具条选择后才开始画标注
        window.overlayView!.currentTool = nil
        // 默认圆角夹取到选区尺寸上限，同步工具条按钮状态
        window.overlayView!.cornerRadius = CornerRounding.clampedRadius(
            window.overlayView!.cornerRadius, for: rect.size)
        window.overlayView!.needsDisplay = true
        // 选区移动/缩放后同步协调器的 selectionRect，确保后续贴图/保存裁剪正确
       window.overlayView!.onSelectionChanged = { [weak self] newRect in
           self?.selectionRect = newRect
       }
        // 标注变化时同步撤销按钮可用状态
        window.overlayView!.onAnnotationsChanged = { [weak self] in
            guard let view = self?.activeOverlay?.overlayView else { return }
            self?.toolbar?.updateUndoButton(canUndo: view.annotations.canUndo)
        }

        let toolbar = ScreenshotToolbar()
        toolbar.toolbarDelegate = self
        let tbFrame = toolbar.frame
        let screen = window.screen ?? NSScreen.main!
        // 工具条定位在选区正上方（含屏幕 origin 偏移，支持多屏）
        let pos = ToolbarPositioner.position(
            forSelection: rect, toolbarSize: tbFrame.size, screenFrame: screen.frame
        )
        toolbar.setFrameOrigin(pos)
        // 工具条为 nonactivatingPanel，仅显示不抢占 key；保持覆盖层为 key 窗口，
        // 否则点击覆盖层时首击被窗口激活吞掉、无法绘制标注
       toolbar.orderFrontRegardless()
        self.toolbar = toolbar
        // 同步圆角按钮状态（默认已启用圆角）
        toolbar.updateCornerRadius(window.overlayView!.cornerRadius)

        for w in overlayWindows where w !== window {
            w.orderOut(nil)
        }
        // 不调用 window.makeKey()：那会把覆盖层提到最前面遮住工具条。
        // nonactivatingPanel 不抢 key，覆盖层从 start() 起即为 key，可正常接收鼠标事件。
        DiagLog.write("Edit mode ready: currentTool=nil, toolbar shown above overlay")
    }

    // MARK: 截取最终图片

    private func renderFinalImage() -> NSImage? {
        guard let sel = selectionRect, let cg = renderFinalCGImage() else { return nil }
        return NSImage(cgImage: cg, size: sel.size)
    }

    /// 渲染最终 CGImage（裁剪 + 标注合成），供贴图直接使用，避免 NSImage 转换丢精度。
    private func renderFinalCGImage() -> CGImage? {
        guard let overlay = activeOverlay, let sel = selectionRect else { return nil }
        let view = overlay.overlayView!
        let image = view.capturedImage
        // 选区为视图点坐标(左下原点)，CGImage 原点在左上，需翻转 y 轴后裁剪
        let cropRect = SelectionRect.cropRectPixels(selection:
            sel, imageSize: CGSize(width: image.width, height: image.height),
            viewSize: view.bounds.size
        )
      guard let cropped = image.cropping(to: cropRect) else { return nil }
       DiagLog.write("renderFinalImage: full=\(image.width)x\(image.height) cropRect=\(cropRect) cropped=\(cropped.width)x\(cropped.height) selPts=\(sel.size) annotations=\(view.annotations.count)")

       var finalImage: CGImage
        if view.annotations.count > 0 || view.drawingAnnotation != nil {
           finalImage = compositeAnnotations(on: cropped, from: overlay) ?? cropped
        } else {
            finalImage = cropped
        }

        // 应用圆角蒙版（半径 > 0 时裁剪为圆角，四角透明）
        let ptRadius = CornerRounding.clampedRadius(view.cornerRadius, for: sel.size)
        if ptRadius > 0 {
            let scaleX = view.bounds.width > 0 ? CGFloat(cropped.width) / view.bounds.width : 1
            let pxRadius = ptRadius * scaleX
            if let rounded = applyRoundedCorners(to: finalImage, radius: pxRadius) {
                finalImage = rounded
            }
        }
        return finalImage
    }

    /// 将 CGImage 四角裁剪为圆角（透明），用于圆角截图输出。
    private func applyRoundedCorners(to image: CGImage, radius: CGFloat) -> CGImage? {
        let w = image.width
        let h = image.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil, width: w, height: h,
                                  bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        let bounds = CGRect(x: 0, y: 0, width: w, height: h)
        ctx.addPath(CGPath(roundedRect: bounds, cornerWidth: radius, cornerHeight: radius, transform: nil))
        ctx.clip()
        ctx.draw(image, in: bounds)
        return ctx.makeImage()
    }

    private func compositeAnnotations(on cropped: CGImage, from overlay: ScreenshotOverlayWindow) -> CGImage? {
        let width = cropped.width
        let height = cropped.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil, width: width, height: height,
                                  bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        // 标准上下文（原点左下），直接绘制裁剪后的图片即正立
        ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: width, height: height))

        // 按 Retina 缩放比缩放 CTM，使标注点坐标（视图点）映射到像素
        let view = overlay.overlayView!
        let viewSize = view.bounds.size
        let scaleX = viewSize.width > 0 ? CGFloat(view.capturedImage.width) / viewSize.width : 1
        let scaleY = viewSize.height > 0 ? CGFloat(view.capturedImage.height) / viewSize.height : 1
        ctx.scaleBy(x: scaleX, y: scaleY)

        let nsContext = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSGraphicsContext.current = nsContext
        for annotation in view.annotations.annotations {
            view.drawAnnotationPublic(annotation, in: ctx)
        }
        NSGraphicsContext.current = nil
        return ctx.makeImage()
    }

    // MARK: 操作

    private func copyToClipboard() {
        guard let image = renderFinalImage() else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([image])
    }

    private func saveToFile() {
        guard let image = renderFinalImage() else { return }
        let dir = config.saveDirectory
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let existing = (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
        let name = ScreenshotFileNameBuilder.uniqueFileName(date: Date(), config: config, existingNames: Set(existing))
        let url = dir.appendingPathComponent(name)
        if let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) {
            let data: Data?
            switch config.format {
            case .png: data = rep.representation(using: .png, properties: [:])
            case .jpg: data = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
            }
            if let data = data { try? data.write(to: url) }
        }
        // 保存后在 Finder 中显示文件，方便用户找到
        DiagLog.write("Saved screenshot to: \(url.path)")
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private func pinToDesktop() {
        guard let sel = selectionRect, let cgImage = renderFinalCGImage() else { return }
        let pinPoint = CGPoint(x: sel.origin.x, y: sel.origin.y)
        let pin = PinWindow(cgImage: cgImage, displaySize: sel.size, at: pinPoint)
        pin.onClose = { [weak self, weak pin] in
            guard let pin = pin else { return }
            self?.pinWindows.removeAll { $0 === pin }
        }
        pin.makeKeyAndOrderFront(nil)
        pinWindows.append(pin)
    }

    /// 贴图当前选区并结束截图会话（F3 触发）。无选区时为空操作。
    func pinCurrentSelection() {
        guard selectionRect != nil else {
            DiagLog.write("pinCurrentSelection: no selection, ignoring")
            return
        }
        pinToDesktop()
        finish()
    }

    /// 结束截图会话：关闭所有覆盖层窗口、工具条，移除事件监听，恢复 App 策略。
    func finish() {
        cancelIdleTimeout()
        for w in overlayWindows { w.orderOut(nil) }
        toolbar?.cleanupColorPanel()
        toolbar?.orderOut(nil)
        overlayWindows.removeAll()
        toolbar = nil
        activeOverlay = nil
        selectionRect = nil

        if let escMonitor = escMonitor {
            NSEvent.removeMonitor(escMonitor)
            self.escMonitor = nil
        }

        DiagLog.write("Screenshot finished")
        onFinished?()
    }

    func cancel() {
        DiagLog.write("Screenshot cancelled")
        finish()
    }

    // MARK: 辅助

    private func screenMatching(displayID: CGDirectDisplayID, frame: CGRect) -> NSScreen? {
        for screen in NSScreen.screens {
            let sid = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
            if sid == displayID { return screen }
        }
        return NSScreen.screens.first
    }
}

// MARK: - ScreenshotToolbarDelegate

extension ScreenshotCoordinator: ScreenshotToolbarDelegate {

    func toolbarDidSelect(tool: AnnotationType?) {
        DiagLog.write("toolbarDidSelect: tool=\(String(describing: tool)) activeOverlay=\(activeOverlay != nil)")
        activeOverlay?.overlayView!.currentTool = tool
    }

    func toolbarDidSelectColor(_ color: AnnotationColor) {
        DiagLog.write("toolbarDidSelectColor: color=\(color) activeOverlay=\(activeOverlay != nil)")
        activeOverlay?.overlayView!.currentColor = color
        // 未选工具时点颜色，默认矩形工具，使「点红色即可画红框」
        if let view = activeOverlay?.overlayView, view.currentTool == nil {
            let tool = AnnotationModel.defaultTool(whenColorSelected: view.currentTool)
            view.currentTool = tool
            toolbar?.selectTool(tool)
            DiagLog.write("toolbarDidSelectColor: auto-selected tool=\(String(describing: tool))")
        }
    }

    func toolbarDidToggleCornerRadius() {
        guard let view = activeOverlay?.overlayView, let sel = selectionRect else { return }
        let next = CornerRounding.nextRadius(view.cornerRadius)
        view.cornerRadius = CornerRounding.clampedRadius(next, for: sel.size)
        toolbar?.updateCornerRadius(view.cornerRadius)
        view.needsDisplay = true
        DiagLog.write("toolbarDidToggleCornerRadius: radius=\(view.cornerRadius)")
    }

    func toolbarDidUndo() {
        guard let view = activeOverlay?.overlayView else { return }
        view.annotations.undo()
        view.needsDisplay = true
        toolbar?.updateUndoButton(canUndo: view.annotations.canUndo)
        DiagLog.write("toolbarDidUndo: remaining=\(view.annotations.count)")
    }

    func toolbarDidCopy() { copyToClipboard(); finish() }
    func toolbarDidSave() { saveToFile(); finish() }
    func toolbarDidPin() { pinToDesktop(); finish() }
    func toolbarDidCancel() { cancel() }

    func toolbarDidScroll() {
        guard let overlay = activeOverlay, let sel = selectionRect else { return }
        let screen = overlay.screen ?? NSScreen.main!
        let displayID = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID) ?? CGMainDisplayID()
        for w in overlayWindows { w.orderOut(nil) }
        toolbar?.cleanupColorPanel()
        toolbar?.orderOut(nil)

        let controller = ScrollCaptureController()
        controller.capture(displayID: displayID, rect: sel) { [weak self] image in
            DispatchQueue.main.async {
                if let image = image {
                    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                        self?.finish(); return
                    }
                    let pinPoint = CGPoint(x: sel.origin.x, y: sel.origin.y)
                    let pin = PinWindow(cgImage: cgImage, displaySize: image.size, at: pinPoint)
                    pin.onClose = { [weak self, weak pin] in
                        guard let pin = pin else { return }
                        self?.pinWindows.removeAll { $0 === pin }
                    }
                    pin.makeKeyAndOrderFront(nil)
                    self?.pinWindows.append(pin)
                }
                self?.finish()
            }
        }
    }
}
