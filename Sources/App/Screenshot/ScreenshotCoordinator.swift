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

        // 3. 临时切换为常规应用以获得焦点
        NSApp.setActivationPolicy(.regular)
        // 强制激活 App（ignoringOtherApps 更可靠，避免首击被窗口激活吞掉）
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
    }

    /// 清理残留的旧覆盖层窗口（防止多次 F1 导致叠加变黑）。
    private func cleanupExistingOverlays() {
        if !overlayWindows.isEmpty {
            DiagLog.write("Cleaning up \(overlayWindows.count) existing overlay window(s)")
            for w in overlayWindows { w.orderOut(nil) }
            overlayWindows.removeAll()
        }
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
            return event
        }
        DiagLog.write("ESC local monitor installed")
    }

    // MARK: 选区完成

    private func handleSelectionComplete(rect: CGRect, window: ScreenshotOverlayWindow?) {
        guard let window = window else { return }
        activeOverlay = window
        selectionRect = rect
        window.overlayView!.isEditMode = true
        // 不自动选标注工具：默认光标模式，用户从工具条选择后才开始画标注
        window.overlayView!.currentTool = nil
        window.overlayView!.needsDisplay = true

        let toolbar = ScreenshotToolbar()
        toolbar.toolbarDelegate = self
        let tbFrame = toolbar.frame
        let screen = window.screen ?? NSScreen.main!
        var originX = rect.midX - tbFrame.width / 2
        var originY = rect.maxY + 8
        if originY + tbFrame.height > screen.frame.maxY {
            originY = rect.minY - tbFrame.height - 8
        }
        originX = max(screen.frame.minX, min(originX, screen.frame.maxX - tbFrame.width))
        toolbar.setFrameOrigin(NSPoint(x: originX, y: originY))
        // 工具条为 nonactivatingPanel，仅显示不抢占 key；保持覆盖层为 key 窗口，
        // 否则点击覆盖层时首击被窗口激活吞掉、无法绘制标注
        toolbar.orderFrontRegardless()
        self.toolbar = toolbar

        for w in overlayWindows where w !== window {
            w.orderOut(nil)
        }
        // 不调用 window.makeKey()：那会把覆盖层提到最前面遮住工具条。
        // nonactivatingPanel 不抢 key，覆盖层从 start() 起即为 key，可正常接收鼠标事件。
        DiagLog.write("Edit mode ready: currentTool=nil, toolbar shown above overlay")
    }

    // MARK: 截取最终图片

    private func renderFinalImage() -> NSImage? {
        guard let overlay = activeOverlay, let sel = selectionRect else { return nil }
        let view = overlay.overlayView!
        let image = view.capturedImage
        // 选区为视图点坐标，图片为像素坐标（Retina 2x），需缩放后裁剪
        let cropRect = SelectionRect.scaleToPixels(
            sel, imageSize: CGSize(width: image.width, height: image.height),
            viewSize: view.bounds.size
        )
        guard let cropped = image.cropping(to: cropRect) else { return nil }

        let finalImage: CGImage
        if view.annotations.count > 0 || view.drawingAnnotation != nil {
           finalImage = compositeAnnotations(on: cropped, from: overlay) ?? cropped
        } else {
            finalImage = cropped
        }
        // NSImage size 用选区点尺寸(sel.size)，而非像素尺寸(finalImage.width/height)，
        // 否则贴图窗口按像素尺寸创建会放大变形。
        return NSImage(cgImage: finalImage, size: sel.size)
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
        guard let image = renderFinalImage(), let sel = selectionRect else { return }
        let pinPoint = CGPoint(x: sel.origin.x, y: sel.origin.y)
        let pin = PinWindow(image: image, at: pinPoint)
        pin.onClose = { [weak self, weak pin] in
            guard let pin = pin else { return }
            self?.pinWindows.removeAll { $0 === pin }
        }
        pin.makeKeyAndOrderFront(nil)
        pinWindows.append(pin)
    }

    /// 结束截图会话：关闭所有覆盖层窗口、工具条，移除事件监听，恢复 App 策略。
    func finish() {
        for w in overlayWindows { w.orderOut(nil) }
        toolbar?.orderOut(nil)
        overlayWindows.removeAll()
        toolbar = nil
        activeOverlay = nil
        selectionRect = nil

        if let escMonitor = escMonitor {
            NSEvent.removeMonitor(escMonitor)
            self.escMonitor = nil
        }

        NSApp.setActivationPolicy(.accessory)
        DiagLog.write("Screenshot finished, restored accessory policy")
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

    func toolbarDidCopy() { copyToClipboard(); finish() }
    func toolbarDidSave() { saveToFile(); finish() }
    func toolbarDidPin() { pinToDesktop(); finish() }
    func toolbarDidCancel() { cancel() }

    func toolbarDidScroll() {
        guard let overlay = activeOverlay, let sel = selectionRect else { return }
        let screen = overlay.screen ?? NSScreen.main!
        let displayID = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID) ?? CGMainDisplayID()
        for w in overlayWindows { w.orderOut(nil) }
        toolbar?.orderOut(nil)

        let controller = ScrollCaptureController()
        controller.capture(displayID: displayID, rect: sel) { [weak self] image in
            DispatchQueue.main.async {
                if let image = image {
                    let pinPoint = CGPoint(x: sel.origin.x, y: sel.origin.y)
                    let pin = PinWindow(image: image, at: pinPoint)
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
