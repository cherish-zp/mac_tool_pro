import AppKit
import CoreGraphics

/// 截图协调器：串联「捕获画面 → 全屏覆盖层选区 → 工具条编辑 → 复制/保存/贴图」全流程。
final class ScreenshotCoordinator {

    private let captureService = ScreenCaptureService()
    private var overlayWindows: [ScreenshotOverlayWindow] = []
    private var toolbar: ScreenshotToolbar?
    private var pinWindows: [PinWindow] = []
    private let config = ScreenshotConfig()
    private var activeOverlay: ScreenshotOverlayWindow?
    private var selectionRect: CGRect?

    func start() {
        DiagLog.write("ScreenshotCoordinator.start()")
        // 1. 请求屏幕录制权限
        captureService.requestPermission()

        // 2. 捕获所有屏幕画面（在显示覆盖层之前）
        let displays = captureService.captureAllDisplays()
        DiagLog.write("Captured \(displays.count) display(s)")
        guard !displays.isEmpty else { return }

        // 3. 为每个屏幕创建覆盖层窗口
        overlayWindows = displays.compactMap { display in
            guard let screen = screenMatching(displayID: display.displayID, frame: display.frame) else { return nil }
            let window = ScreenshotOverlayWindow(screen: screen, capturedImage: display.image)
            let view = window.overlayView
            view.onSelectionComplete = { [weak self, weak window] rect in
                self?.handleSelectionComplete(rect: rect, window: window)
            }
            view.onCancel = { [weak self] in self?.cancel() }
            window.makeKeyAndOrderFront(nil)
            window.overlayView.window?.makeFirstResponder(view)
            return window
        }

        // 4. 激活 App 以接收键盘事件
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: 选区完成

    private func handleSelectionComplete(rect: CGRect, window: ScreenshotOverlayWindow?) {
        guard let window = window else { return }
        activeOverlay = window
        selectionRect = rect
        window.overlayView.isEditMode = true
        window.overlayView.currentTool = .rectangle
        window.overlayView.needsDisplay = true

        // 显示工具条（定位在选区下方）
        let toolbar = ScreenshotToolbar()
        toolbar.toolbarDelegate = self
        let tbFrame = toolbar.frame
        let screen = window.screen ?? NSScreen.main!
        var originX = rect.midX - tbFrame.width / 2
        var originY = rect.maxY + 8
        // 如果超出屏幕底部，放到选区上方
        if originY + tbFrame.height > screen.frame.maxY {
            originY = rect.minY - tbFrame.height - 8
        }
        originX = max(screen.frame.minX, min(originX, screen.frame.maxX - tbFrame.width))
        toolbar.setFrameOrigin(NSPoint(x: originX, y: originY))
        toolbar.makeKeyAndOrderFront(nil)
        self.toolbar = toolbar

        // 其他覆盖层窗口关闭（只在选中屏幕操作）
        for w in overlayWindows where w !== window {
            w.orderOut(nil)
        }
    }

    // MARK: 截取最终图片

    /// 将选区内的画面 + 标注合成为最终 NSImage。
    private func renderFinalImage() -> NSImage? {
        guard let overlay = activeOverlay,
              let sel = selectionRect else { return nil }

        let image = overlay.overlayView.capturedImage
        // 选区在视图坐标系（翻转）中的位置 -> CGImage 坐标系一致（都是左上原点）
        let cropRect = CGRect(
            x: sel.origin.x,
            y: sel.origin.y,
            width: sel.width,
            height: sel.height
        )

        guard let cropped = image.cropping(to: cropRect) else { return nil }

        // 合成标注
        let finalImage: CGImage
        if overlay.overlayView.annotations.count > 0 || overlay.overlayView.drawingAnnotation != nil {
            finalImage = compositeAnnotations(on: cropped, from: overlay, selectionOrigin: sel.origin) ?? cropped
        } else {
            finalImage = cropped
        }

        return NSImage(cgImage: finalImage, size: NSSize(width: finalImage.width, height: finalImage.height))
    }

    /// 在裁剪后的图片上合成标注（标注坐标是相对于选区原点的）。
    private func compositeAnnotations(on cropped: CGImage, from overlay: ScreenshotOverlayWindow,
                                       selectionOrigin: CGPoint) -> CGImage? {
        let width = cropped.width
        let height = cropped.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil, width: width, height: height,
                                  bitsPerComponent: 8, bytesPerRow: 0,
                                  space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        // CGContext 原点在左下，而 CGImage 原点在左上 -> 需要翻转
        ctx.translateBy(x: 0, y: CGFloat(height))
        ctx.scaleBy(x: 1, y: -1)
        ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: width, height: height))

        // 翻转回来绘制标注（标注用左上原点坐标系）
        ctx.scaleBy(x: 1, y: -1)
        ctx.translateBy(x: 0, y: -CGFloat(height))

        let view = overlay.overlayView
        // 借用视图的标注绘制逻辑：直接调用 NSGraphicsContext
        let nsContext = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSGraphicsContext.current = nsContext
        for annotation in view.annotations.annotations {
            // 标注坐标是相对于选区原点的，这里直接用（因为裁剪图就是从选区原点开始的）
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
        let name = ScreenshotFileNameBuilder.uniqueFileName(
            date: Date(), config: config, existingNames: Set(existing)
        )
        let url = dir.appendingPathComponent(name)
        if let tiff = image.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff) {
            let data: Data?
            switch config.format {
            case .png: data = rep.representation(using: .png, properties: [:])
            case .jpg: data = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
            }
            if let data = data {
                try? data.write(to: url)
            }
        }
    }

    private func pinToDesktop() {
        guard let image = renderFinalImage(), let sel = selectionRect else { return }
        // 贴图位置：选区当前位置
        let pinPoint = CGPoint(x: sel.origin.x, y: sel.origin.y)
        let pin = PinWindow(image: image, at: pinPoint)
        pin.makeKeyAndOrderFront(nil)
        pinWindows.append(pin)
    }

    private func finish() {
        for w in overlayWindows { w.orderOut(nil) }
        toolbar?.orderOut(nil)
        overlayWindows.removeAll()
        toolbar = nil
        activeOverlay = nil
        selectionRect = nil
    }

    private func cancel() {
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
        activeOverlay?.overlayView.currentTool = tool
    }

    func toolbarDidSelectColor(_ color: AnnotationColor) {
        activeOverlay?.overlayView.currentColor = color
    }

    func toolbarDidCopy() {
        copyToClipboard()
        finish()
    }

    func toolbarDidSave() {
        saveToFile()
        finish()
    }

    func toolbarDidPin() {
        pinToDesktop()
        finish()
    }

    func toolbarDidCancel() {
        cancel()
    }

    func toolbarDidScroll() {
        guard let overlay = activeOverlay,
              let sel = selectionRect else { return }

        // 获取目标显示器 ID
        let screen = overlay.screen ?? NSScreen.main!
        let displayID = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID) ?? CGMainDisplayID()

        // 先隐藏覆盖层，避免截到自身
        for w in overlayWindows { w.orderOut(nil) }
        toolbar?.orderOut(nil)

        let controller = ScrollCaptureController()
        controller.capture(displayID: displayID, rect: sel) { [weak self] image in
            DispatchQueue.main.async {
                if let image = image {
                    // 贴图展示滚动截图结果
                    let pinPoint = CGPoint(x: sel.origin.x, y: sel.origin.y)
                    let pin = PinWindow(image: image, at: pinPoint)
                    pin.makeKeyAndOrderFront(nil)
                    self?.pinWindows.append(pin)
                }
                self?.finish()
            }
        }
    }
}
