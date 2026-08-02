import AppKit
import CoreGraphics

/// 截图覆盖层视图：显示捕获的画面 + 半透明遮罩 + 选区框 + 标注绘制。
/// 坐标系翻转（isFlipped=true），原点在左上，与 CGImage / 屏幕坐标一致。
final class ScreenshotOverlayView: NSView {

    let capturedImage: CGImage

    // MARK: 选区状态
    var selectionStart: CGPoint?
    var selectionRect: CGRect?
    let minimumSelection: CGFloat = 10

    // MARK: 编辑状态
    var isEditMode = false
    let annotations = AnnotationModel()
    var currentTool: AnnotationType?
    var drawingAnnotation: Annotation?
    var currentColor: AnnotationColor = .red
    var strokeWidth: CGFloat = 3

    // MARK: 回调
    var onSelectionComplete: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?
    var onAnnotationsChanged: (() -> Void)?

    init(capturedImage: CGImage, frame: NSRect) {
        self.capturedImage = capturedImage
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }
    override var mouseDownCanMoveWindow: Bool { false }

    // MARK: 绘制

    override func draw(_ dirtyRect: NSRect) {
        DiagLog.write("OverlayView.draw() bounds=\(bounds) hasSelection=\(selectionRect != nil) editMode=\(isEditMode)")
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            DiagLog.write("OverlayView.draw: NO graphics context!")
            return
        }
        // 1. 绘制捕获的画面
        ctx.saveGState()
        ctx.draw(capturedImage, in: bounds)
        ctx.restoreGState()

        if let sel = selectionRect, isEditMode {
            // 编辑模式：选区内正常显示，外部遮罩
            drawDarkMask(excluding: sel, in: ctx)
            drawSelectionBorder(sel, in: ctx)
            drawAnnotations(in: ctx, canvasRect: sel)
            if let drawing = drawingAnnotation {
                drawSingleAnnotation(drawing, in: ctx)
            }
        } else if let sel = selectionRect {
            // 选区拖拽中
            drawDarkMask(excluding: sel, in: ctx)
            drawSelectionBorder(sel, in: ctx)
            drawSizeLabel(sel)
        } else {
            // 未开始选区：全屏遮罩
            ctx.setFillColor(NSColor(white: 0, alpha: 0.35).cgColor)
            ctx.fill(bounds)
        }
    }

    private func drawDarkMask(excluding rect: CGRect, in ctx: CGContext) {
        ctx.setFillColor(NSColor(white: 0, alpha: 0.45).cgColor)
        // 上、下、左、右四条遮罩带
        ctx.fill(CGRect(x: 0, y: 0, width: bounds.width, height: rect.minY))
        ctx.fill(CGRect(x: 0, y: rect.maxY, width: bounds.width, height: bounds.height - rect.maxY))
        ctx.fill(CGRect(x: 0, y: rect.minY, width: rect.minX, height: rect.height))
        ctx.fill(CGRect(x: rect.maxX, y: rect.minY, width: bounds.width - rect.maxX, height: rect.height))
    }

    private func drawSelectionBorder(_ rect: CGRect, in ctx: CGContext) {
        ctx.setStrokeColor(NSColor(calibratedWhite: 1, alpha: 0.9).cgColor)
        ctx.setLineWidth(1)
        ctx.stroke(rect)
    }

    private func drawSizeLabel(_ rect: CGRect) {
        let ctx = NSGraphicsContext.current!.cgContext
        let text = "\(Int(rect.width)) × \(Int(rect.height))"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let size = str.size()
        let labelRect = CGRect(
            x: min(rect.maxX + 4, bounds.width - size.width - 4),
            y: min(rect.maxY + 4, bounds.height - size.height - 4),
            width: size.width, height: size.height
        )
        let bgRect = labelRect.insetBy(dx: -4, dy: -2)
        ctx.setFillColor(NSColor(white: 0, alpha: 0.7).cgColor)
        ctx.fill(bgRect)
        str.draw(in: labelRect)
    }

    // MARK: 标注绘制

    private func drawAnnotations(in ctx: CGContext, canvasRect: CGRect) {
        for annotation in annotations.annotations {
            drawSingleAnnotation(annotation, in: ctx)
        }
    }

    private func drawSingleAnnotation(_ annotation: Annotation, in ctx: CGContext) {
        let color = nsColor(annotation.color)
        ctx.saveGState()
        switch annotation.type {
        case .rectangle:
            guard annotation.points.count >= 2 else { break }
            let rect = SelectionRect.normalize(start: annotation.points[0], end: annotation.points[1])
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(annotation.strokeWidth)
            ctx.stroke(rect)
        case .arrow:
            guard annotation.points.count >= 2 else { break }
            let start = annotation.points[0]
            let end = annotation.points[1]
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(annotation.strokeWidth)
            ctx.setLineCap(.round)
            ctx.move(to: start)
            ctx.addLine(to: end)
            ctx.strokePath()
            drawArrowHead(from: start, to: end, color: color, in: ctx)
        case .text:
            guard let text = annotation.text, !annotation.points.isEmpty else { break }
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: color
            ]
            let str = NSAttributedString(string: text, attributes: attrs)
            str.draw(at: annotation.points[0])
        case .mosaic:
            guard annotation.points.count >= 2 else { break }
            let rect = SelectionRect.normalize(start: annotation.points[0], end: annotation.points[1])
            drawMosaic(in: rect, ctx: ctx)
        }
        ctx.restoreGState()
    }

    private func drawArrowHead(from start: CGPoint, to end: CGPoint, color: NSColor, in ctx: CGContext) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = sqrt(dx * dx + dy * dy)
        guard length > 0 else { return }
        let angle = atan2(dy, dx)
        let headLength: CGFloat = 14
        let headAngle: CGFloat = .pi / 6
        let p1 = CGPoint(x: end.x - headLength * cos(angle - headAngle),
                         y: end.y - headLength * sin(angle - headAngle))
        let p2 = CGPoint(x: end.x - headLength * cos(angle + headAngle),
                         y: end.y - headLength * sin(angle + headAngle))
        ctx.setFillColor(color.cgColor)
        ctx.move(to: end)
        ctx.addLine(to: p1)
        ctx.addLine(to: p2)
        ctx.closePath()
        ctx.fillPath()
    }

    private func drawMosaic(in rect: CGRect, ctx: CGContext) {
        let blockSize: CGFloat = 8
        let originX = rect.origin.x
        let originY = rect.origin.y
        let cols = Int(rect.width / blockSize)
        let rows = Int(rect.height / blockSize)
        // 从捕获画面中取对应区域做马赛克
        guard let provider = capturedImage.dataProvider,
              let data = provider.data else { return }
        let bytesPerRow = capturedImage.bytesPerRow
        let bpp = capturedImage.bitsPerPixel / 8
        let baseAddress = CFDataGetBytePtr(data)
        let imageWidth = capturedImage.width
        let imageHeight = capturedImage.height
        for row in 0..<rows {
            for col in 0..<cols {
                let px = Int(originX) + col * Int(blockSize) + Int(blockSize / 2)
                let py = Int(originY) + row * Int(blockSize) + Int(blockSize / 2)
                guard px >= 0, px < imageWidth, py >= 0, py < imageHeight else { continue }
                let offset = py * bytesPerRow + px * bpp
                guard offset + bpp <= CFDataGetLength(data) else { continue }
                let r = baseAddress![offset]
                let g = baseAddress![offset + 1]
                let b = baseAddress![offset + 2]
                ctx.setFillColor(CGColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255,
                                         blue: CGFloat(b) / 255, alpha: 1))
                ctx.fill(CGRect(x: originX + CGFloat(col) * blockSize,
                                y: originY + CGFloat(row) * blockSize,
                                width: blockSize, height: blockSize))
            }
        }
    }

    private func nsColor(_ color: AnnotationColor) -> NSColor {
        switch color {
        case .red: return .systemRed
        case .yellow: return .systemYellow
        case .green: return .systemGreen
        case .blue: return .systemBlue
        case .white: return .white
        case .black: return .black
        }
    }

    // MARK: 鼠标事件

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        if isEditMode {
            handleEditMouseDown(point)
            return
        }

        // 选区开始
        selectionStart = point
        selectionRect = CGRect(origin: point, size: .zero)
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        if isEditMode {
            handleEditMouseDrag(point)
            return
        }

        guard let start = selectionStart else { return }
        var rect = SelectionRect.normalize(start: start, end: point)
        rect = SelectionRect.clamp(rect, to: bounds)
        selectionRect = rect
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        if isEditMode {
            handleEditMouseUp(point)
            return
        }

        guard var rect = selectionRect else { return }
        rect = SelectionRect.enforceMinimumSize(rect, minimum: minimumSelection)
        if !SelectionRect.isValid(rect, minimum: minimumSelection) {
            // 选区太小 -> 取消
            onCancel?()
            return
        }
        selectionRect = rect
        needsDisplay = true
        onSelectionComplete?(rect)
    }

    // MARK: 编辑模式鼠标处理

    private func handleEditMouseDown(_ point: CGPoint) {
        guard let tool = currentTool, let sel = selectionRect else { return }
        let local = CGPoint(x: point.x - sel.origin.x, y: point.y - sel.origin.y)
        switch tool {
        case .text:
            // 文字标注：直接创建空标注，后续可弹输入框（MVP 先用占位）
            drawingAnnotation = Annotation(type: .text, points: [local], text: "文字", color: currentColor)
        default:
            drawingAnnotation = Annotation(type: tool, points: [local, local], color: currentColor, strokeWidth: strokeWidth)
        }
        needsDisplay = true
    }

    private func handleEditMouseDrag(_ point: CGPoint) {
        guard let sel = selectionRect else { return }
        let local = CGPoint(x: point.x - sel.origin.x, y: point.y - sel.origin.y)
        guard var drawing = drawingAnnotation else { return }
        if drawing.type != .text {
            drawing.points[drawing.points.count - 1] = local
            drawingAnnotation = drawing
        }
        needsDisplay = true
    }

    private func handleEditMouseUp(_ point: CGPoint) {
        guard let drawing = drawingAnnotation else { return }
        annotations.add(drawing)
        drawingAnnotation = nil
        onAnnotationsChanged?()
        needsDisplay = true
    }

    // MARK: 键盘

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC
            onCancel?()
        } else if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "z" {
            annotations.undo()
            onAnnotationsChanged?()
            needsDisplay = true
        }
    }
}

// MARK: - 公开标注绘制（供 Coordinator 合成最终图片时调用）

extension ScreenshotOverlayView {
    func drawAnnotationPublic(_ annotation: Annotation, in ctx: CGContext) {
        drawSingleAnnotation(annotation, in: ctx)
    }
}
