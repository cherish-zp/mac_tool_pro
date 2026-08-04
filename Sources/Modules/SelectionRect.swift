import CoreGraphics

/// 选区缩放手柄类型（8 个边角 + 内部用于移动）。
public enum ResizeHandle: Equatable {
    case topLeft, top, topRight
    case left, right
    case bottomLeft, bottom, bottomRight
    case interior
}

/// 截图选区的几何计算工具：规范化拖拽矩形、夹取到屏幕边界、约束最小尺寸。
/// 纯函数，无副作用，便于单测。
public enum SelectionRect {
    /// 将任意方向的拖拽起止点规范为标准 CGRect（origin 在最小角，width/height 为正）。
    public static func normalize(start: CGPoint, end: CGPoint) -> CGRect {
        let minX = Swift.min(start.x, end.x)
        let minY = Swift.min(start.y, end.y)
        let maxX = Swift.max(start.x, end.x)
        let maxY = Swift.max(start.y, end.y)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// 将矩形夹取到 bounds 范围内，确保不超出屏幕边界。
    public static func clamp(_ rect: CGRect, to bounds: CGRect) -> CGRect {
        let originX = Swift.max(bounds.minX, Swift.min(rect.minX, bounds.maxX))
        let originY = Swift.max(bounds.minY, Swift.min(rect.minY, bounds.maxY))
        let maxX = Swift.max(bounds.minX, Swift.min(rect.maxX, bounds.maxX))
        let maxY = Swift.max(bounds.minY, Swift.min(rect.maxY, bounds.maxY))
        return CGRect(x: originX, y: originY, width: maxX - originX, height: maxY - originY)
    }

    /// 强制矩形至少达到 minimum 尺寸（不足时以 origin 为起点扩展）。
    public static func enforceMinimumSize(_ rect: CGRect, minimum: CGFloat) -> CGRect {
        let width = Swift.max(rect.width, minimum)
        let height = Swift.max(rect.height, minimum)
        return CGRect(x: rect.origin.x, y: rect.origin.y, width: width, height: height)
    }

    /// 判断矩形是否满足最小尺寸要求（宽高均 >= minimum）。
    public static func isValid(_ rect: CGRect, minimum: CGFloat) -> Bool {
        rect.width >= minimum && rect.height >= minimum
    }

   /// 将点坐标的选区缩放为像素坐标（用于 Retina 屏裁剪）。
   /// 视图坐标和图片坐标均为左下原点（标准坐标系），仅按比例缩放。
   public static func scaleToPixels(_ rect: CGRect, imageSize: CGSize, viewSize: CGSize) -> CGRect {
       let scaleX = viewSize.width > 0 ? imageSize.width / viewSize.width : 1
       let scaleY = viewSize.height > 0 ? imageSize.height / viewSize.height : 1
       return CGRect(x: rect.origin.x * scaleX, y: rect.origin.y * scaleY,
                     width: rect.width * scaleX, height: rect.height * scaleY)
   }

    /// 将标注的局部坐标（相对选区原点）还原为视图绝对坐标。
    /// 标注点以选区原点为基准存储，绘制时需加上选区 origin 才能落到正确位置。
    public static func toAbsolute(_ local: CGPoint, origin: CGPoint) -> CGPoint {
        CGPoint(x: local.x + origin.x, y: local.y + origin.y)
    }

    /// 将像素尺寸转换为点尺寸（用于 NSImage 的 size 属性，避免贴图变形）。
    public static func pointSize(pixelSize: CGSize, scaleFactor: CGFloat) -> CGSize {
        guard scaleFactor > 0 else { return pixelSize }
        return CGSize(width: pixelSize.width / scaleFactor, height: pixelSize.height / scaleFactor)
    }

    /// 根据鼠标位移计算贴图窗口新原点（拖拽移动）。
    public static func dragOrigin(initialOrigin: CGPoint, initialMouse: CGPoint, currentMouse: CGPoint) -> CGPoint {
        CGPoint(x: initialOrigin.x + (currentMouse.x - initialMouse.x),
                y: initialOrigin.y + (currentMouse.y - initialMouse.y))
    }

    // MARK: - 选区移动/缩放

    /// 命中检测：判断鼠标点落在选区的哪个手柄上（边角/内部/外部）。
    public static func hitTest(point: CGPoint, in rect: CGRect, handleSize: CGFloat) -> ResizeHandle? {
        let expanded = rect.insetBy(dx: -handleSize, dy: -handleSize)
        if !expanded.contains(point) { return nil }
        let nearLeft = point.x <= rect.minX + handleSize
        let nearRight = point.x >= rect.maxX - handleSize
        let nearBottom = point.y <= rect.minY + handleSize
        let nearTop = point.y >= rect.maxY - handleSize
        if nearLeft && nearBottom { return .bottomLeft }
        if nearLeft && nearTop { return .topLeft }
        if nearRight && nearBottom { return .bottomRight }
        if nearRight && nearTop { return .topRight }
        if nearLeft { return .left }
        if nearRight { return .right }
        if nearBottom { return .bottom }
        if nearTop { return .top }
        return .interior
    }

    /// 移动选区，夹取到 bounds 范围内。
    public static func move(_ rect: CGRect, by delta: CGVector, bounds: CGRect) -> CGRect {
        var r = rect.offsetBy(dx: delta.dx, dy: delta.dy)
        if r.minX < bounds.minX { r.origin.x = bounds.minX }
        if r.minY < bounds.minY { r.origin.y = bounds.minY }
        if r.maxX > bounds.maxX { r.origin.x = bounds.maxX - r.width }
        if r.maxY > bounds.maxY { r.origin.y = bounds.maxY - r.height }
        return r
    }

    /// 缩放选区：根据手柄和位移调整对应边，约束最小尺寸并夹取到 bounds。
   public static func resize(_ rect: CGRect, handle: ResizeHandle,
                             delta: CGVector, minSize: CGFloat, bounds: CGRect) -> CGRect {
       var r = rect
       switch handle {
       case .bottomLeft:
           r.origin.x += delta.dx; r.size.width -= delta.dx
           r.origin.y += delta.dy; r.size.height -= delta.dy
       case .bottom:
           r.origin.y += delta.dy; r.size.height -= delta.dy
       case .bottomRight:
           r.origin.y += delta.dy; r.size.height -= delta.dy
           r.size.width += delta.dx
       case .left:
           r.origin.x += delta.dx; r.size.width -= delta.dx
       case .right:
           r.size.width += delta.dx
       case .topLeft:
           r.origin.x += delta.dx; r.size.width -= delta.dx
           r.size.height += delta.dy
       case .top:
           r.size.height += delta.dy
       case .topRight:
           r.size.width += delta.dx; r.size.height += delta.dy
       case .interior:
           break
       }
       // 约束最小尺寸：左边/下边手柄收缩时固定对边
       if r.width < minSize {
           if [.left, .bottomLeft, .topLeft].contains(handle) {
               r.origin.x = r.maxX - minSize
           }
           r.size.width = minSize
       }
       if r.height < minSize {
           if [.bottom, .bottomLeft, .bottomRight].contains(handle) {
               r.origin.y = r.maxY - minSize
           }
           r.size.height = minSize
       }
       return clamp(r, to: bounds)
    }

    /// 计算 CGImage.cropping(to:) 所需的裁剪矩形。
    /// CGImage 原点在左上(top-left)，视图坐标原点在左下(bottom-left, isFlipped=false)，
    /// 需翻转 y 轴：cropY = (viewHeight - selection.maxY) * scaleY。
    public static func cropRectPixels(selection: CGRect, imageSize: CGSize, viewSize: CGSize) -> CGRect {
        let scaleX = viewSize.width > 0 ? imageSize.width / viewSize.width : 1
        let scaleY = viewSize.height > 0 ? imageSize.height / viewSize.height : 1
        let flippedY = (viewSize.height - selection.maxY) * scaleY
        return CGRect(x: selection.origin.x * scaleX,
                      y: flippedY,
                      width: selection.width * scaleX,
                      height: selection.height * scaleY)
    }
}
