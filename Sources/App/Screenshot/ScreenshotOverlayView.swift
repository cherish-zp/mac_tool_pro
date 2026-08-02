import AppKit
import CoreGraphics

/// 截图覆盖层视图：显示捕获的画面 + 半透明遮罩 + 选区框 + 标注绘制。
/// 标准坐标系（isFlipped=false，原点左下），鼠标坐标与 CGContext 一致；
/// 图片直接 ctx.draw 绘制（CGImage 原点左下，标准上下文下正立）。
final class ScreenshotOverlayView: NSView {

    let capturedImage: CGImage

    var selectionStart: CGPoint?
    var selectionRect: CGRect?
    let minimumSelection: CGFloat = 10

    var isEditMode = false
    let annotations = AnnotationModel()
    var currentTool: AnnotationType?
    var drawingAnnotation: Annotation?
    var currentColor: AnnotationColor = .red
    var strokeWidth: CGFloat = 3

    // 文字标注编辑状态
    private var activeTextField: NSTextField?
    private var textEditLocalPoint: CGPoint = .zero

    var onSelectionComplete: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?
    var onAnnotationsChanged: (() -> Void)?

    init(capturedImage: CGImage, frame: NSRect) {
        self.capturedImage = capturedImage
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var isFlipped: Bool { false }
    override var acceptsFirstResponder: Bool { true }
    override var mouseDownCanMoveWindow: Bool { false }

    // MARK: 绘制

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        // 1. 绘制捕获的画面（标准上下文，CGImage 原点左下，直接绘制即正立）
        ctx.draw(capturedImage, in: bounds)

        if let sel = selectionRect, isEditMode {
            drawDarkMask(excluding: sel, in: ctx)
            drawSelectionBorder(sel, in: ctx)
            // 标注点为相对选区原点的局部坐标，平移上下文至选区原点使其落到正确位置
            ctx.saveGState()
            ctx.translateBy(x: sel.origin.x, y: sel.origin.y)
            for annotation in annotations.annotations {
                drawSingleAnnotation(annotation, in: ctx)
            }
            if let drawing = drawingAnnotation {
                drawSingleAnnotation(drawing, in: ctx)
            }
            ctx.restoreGState()
        } else if let sel = selectionRect {
            drawDarkMask(excluding: sel, in: ctx)
            drawSelectionBorder(sel, in: ctx)
            drawSizeLabel(sel)
        } else {
            ctx.setFillColor(NSColor(white: 0, alpha: 0.35).cgColor)
            ctx.fill(bounds)
        }
    }

    private func drawDarkMask(excluding rect: CGRect, in ctx: CGContext) {
        ctx.setFillColor(NSColor(white: 0, alpha: 0.45).cgColor)
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
        let ctx = NSGraphicsContext.current!.cgContext
        ctx.setFillColor(NSColor(white: 0, alpha: 0.7).cgColor)
        ctx.fill(bgRect)
        str.draw(in: labelRect)
    }

    // MARK: 标注绘制

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
            NSAttributedString(string: text, attributes: attrs).draw(at: annotation.points[0])
        case .mosaic:
            guard annotation.points.count >= 2 else { break }
            let rect = SelectionRect.normalize(start: annotation.points[0], end: annotation.points[1])
            drawMosaic(in: rect, ctx: ctx)
        }
        ctx.restoreGState()
    }

    private func drawArrowHead(from start: CGPoint, to end: CGPoint, color: NSColor, in ctx: CGContext) {
        let dx = end.x - start.x, dy = end.y - start.y
        let length = sqrt(dx * dx + dy * dy)
        guard length > 0 else { return }
        let angle = atan2(dy, dx)
        let hl: CGFloat = 14, ha: CGFloat = .pi / 6
        let p1 = CGPoint(x: end.x - hl * cos(angle - ha), y: end.y - hl * sin(angle - ha))
        let p2 = CGPoint(x: end.x - hl * cos(angle + ha), y: end.y - hl * sin(angle + ha))
        ctx.setFillColor(color.cgColor)
        ctx.move(to: end)
        ctx.addLine(to: p1)
        ctx.addLine(to: p2)
        ctx.closePath()
        ctx.fillPath()
    }

    private func drawMosaic(in rect: CGRect, ctx: CGContext) {
        let bs: CGFloat = 8
        let cols = Int(rect.width / bs), rows = Int(rect.height / bs)
        guard let provider = capturedImage.dataProvider, let data = provider.data else { return }
        let bpr = capturedImage.bytesPerRow, bpp = capturedImage.bitsPerPixel / 8
        let ptr = CFDataGetBytePtr(data)
        let iw = capturedImage.width, ih = capturedImage.height
        let viewBounds = bounds
        let sx = iw > 0 ? CGFloat(iw) / viewBounds.width : 1
        let sy = ih > 0 ? CGFloat(ih) / viewBounds.height : 1
        for row in 0..<rows {
            for col in 0..<cols {
                let px = Int((rect.origin.x + CGFloat(col) * bs + bs / 2) * sx)
                let py = Int((rect.origin.y + CGFloat(row) * bs + bs / 2) * sy)
                guard px >= 0, px < iw, py >= 0, py < ih else { continue }
                let off = py * bpr + px * bpp
                guard off + bpp <= CFDataGetLength(data) else { continue }
                ctx.setFillColor(CGColor(red: CGFloat(ptr![off]) / 255, green: CGFloat(ptr![off + 1]) / 255,
                                     blue: CGFloat(ptr![off + 2]) / 255, alpha: 1))
                ctx.fill(CGRect(x: rect.origin.x + CGFloat(col) * bs, y: rect.origin.y + CGFloat(row) * bs,
                                width: bs, height: bs))
            }
        }
    }

    private func nsColor(_ color: AnnotationColor) -> NSColor {
        switch color {
        case .red: return .systemRed; case .yellow: return .systemYellow
        case .green: return .systemGreen; case .blue: return .systemBlue
        case .white: return .white; case .black: return .black
        }
    }

    // MARK: 鼠标事件（标准坐标系，原点在左下，与 CGContext 一致）

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if isEditMode { handleEditMouseDown(point); return }
        selectionStart = point
        selectionRect = CGRect(origin: point, size: .zero)
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if isEditMode { handleEditMouseDrag(point); return }
        guard let start = selectionStart else { return }
        var rect = SelectionRect.normalize(start: start, end: point)
        rect = SelectionRect.clamp(rect, to: bounds)
        selectionRect = rect
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if isEditMode { handleEditMouseUp(point); return }
        guard var rect = selectionRect else { return }
        rect = SelectionRect.enforceMinimumSize(rect, minimum: minimumSelection)
        if !SelectionRect.isValid(rect, minimum: minimumSelection) {
            onCancel?()
            return
        }
        selectionRect = rect
        needsDisplay = true
        onSelectionComplete?(rect)
    }

    // MARK: 编辑模式

    private func handleEditMouseDown(_ point: CGPoint) {
        DiagLog.write("handleEditMouseDown: point=\(point) tool=\(String(describing: currentTool)) hasSel=\(selectionRect != nil)")
        guard let tool = currentTool, let sel = selectionRect else { return }
        let local = CGPoint(x: point.x - sel.origin.x, y: point.y - sel.origin.y)
        if tool == .text {
            startTextEditing(at: point, localPoint: local)
        } else {
            drawingAnnotation = Annotation(type: tool, points: [local, local], color: currentColor, strokeWidth: strokeWidth)
        }
        needsDisplay = true
    }

    private func handleEditMouseDrag(_ point: CGPoint) {
        guard let sel = selectionRect else { return }
        let local = CGPoint(x: point.x - sel.origin.x, y: point.y - sel.origin.y)
        guard var d = drawingAnnotation, d.type != .text else { return }
        d.points[d.points.count - 1] = local
        drawingAnnotation = d
        needsDisplay = true
    }

    private func handleEditMouseUp(_ point: CGPoint) {
        guard let d = drawingAnnotation else { return }
        annotations.add(d)
        drawingAnnotation = nil
        onAnnotationsChanged?()
        needsDisplay = true
    }

    // MARK: 文字标注编辑

    /// 在点击位置弹出文本输入框，用户输入文字后回车提交。
    private func startTextEditing(at viewPoint: CGPoint, localPoint: CGPoint) {
        // 先提交正在编辑的文字（如有），再开始新的输入
        if activeTextField != nil { commitTextEditing() }
        textEditLocalPoint = localPoint
        let tf = NSTextField(frame: NSRect(x: viewPoint.x, y: viewPoint.y, width: 220, height: 28))
        tf.font = .systemFont(ofSize: 16, weight: .medium)
        tf.placeholderString = "输入文字，回车确认"
        tf.target = self
        tf.action = #selector(textFieldCommitted(_:))
        tf.delegate = nil
        tf.stringValue = ""
        addSubview(tf)
        window?.makeFirstResponder(tf)
        activeTextField = tf
        // 监听失焦（点击别处）自动提交
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldEndedEditing(_:)),
                                               name: NSControl.textDidEndEditingNotification, object: tf)
        DiagLog.write("startTextEditing at local=\(localPoint)")
    }

    @objc private func textFieldCommitted(_ sender: NSTextField) {
        commitTextEditing()
    }

    private func commitTextEditing() {
        guard let tf = activeTextField else { return }
        activeTextField = nil  // 先置空，防止 removeFromSuperview 触发 controlTextDidEndEditing 重入
        NotificationCenter.default.removeObserver(self, name: NSControl.textDidEndEditingNotification, object: tf)
        let text = tf.stringValue
        if let ann = AnnotationModel.textAnnotation(at: textEditLocalPoint, text: text, color: currentColor) {
            annotations.add(ann)
            onAnnotationsChanged?()
            DiagLog.write("Text annotation committed: \(text)")
        }
        tf.removeFromSuperview()
        needsDisplay = true
    }

    private func cancelTextEditing() {
        if let tf = activeTextField {
            NotificationCenter.default.removeObserver(self, name: NSControl.textDidEndEditingNotification, object: tf)
        }
        activeTextField?.removeFromSuperview()
        activeTextField = nil
        needsDisplay = true
        DiagLog.write("Text editing cancelled")
    }

    /// ESC 优先取消文字编辑；返回 true 表示已处理（不应再取消截图）。
    func cancelTextEditingIfActive() -> Bool {
        if activeTextField != nil {
            cancelTextEditing()
            return true
        }
        return false
    }

    // 失焦时自动提交（回车已由 action 提交，guard 防重复）
    @objc private func textFieldEndedEditing(_ notification: Notification) {
        if activeTextField != nil { commitTextEditing() }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == ScreenshotSession.escKeyCode {
            if activeTextField != nil { cancelTextEditing() } else { onCancel?() }
        }
        else if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "z" {
            annotations.undo(); onAnnotationsChanged?(); needsDisplay = true
        }
    }
}

extension ScreenshotOverlayView {
    func drawAnnotationPublic(_ annotation: Annotation, in ctx: CGContext) {
        drawSingleAnnotation(annotation, in: ctx)
    }
}
