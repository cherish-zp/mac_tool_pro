import AppKit
import CoreGraphics

/// 将 ResizeCursorKind 映射到 NSCursor，含自定义对角线缩放光标。
/// macOS 公开 API 无对角线缩放光标，需手动绘制双箭头图片。
enum ResizeCursorFactory {

    /// 缓存自定义对角线光标，避免每次鼠标移动都重绘。
    private static let diagonalTLBR: NSCursor = makeDiagonalCursor(isTLBR: true)
    private static let diagonalBLTR: NSCursor = makeDiagonalCursor(isTLBR: false)

    /// 根据 ResizeCursorKind 返回对应的 NSCursor。
    static func cursor(for kind: ResizeCursorKind) -> NSCursor {
        switch kind {
        case .move:               return NSCursor.openHand
        case .resizeVertical:     return NSCursor.resizeUpDown
        case .resizeHorizontal:   return NSCursor.resizeLeftRight
        case .resizeDiagonalTLBR: return diagonalTLBR
        case .resizeDiagonalBLTR: return diagonalBLTR
        case .crosshair:          return NSCursor.crosshair
        }
    }

    /// 根据 CursorStyle 返回对应的 NSCursor。
    static func cursor(for style: CursorStyle) -> NSCursor {
        switch style {
        case .crosshair:          return NSCursor.crosshair
        case .arrow:              return NSCursor.arrow
        case .move:               return NSCursor.openHand
        case .resizeVertical:     return NSCursor.resizeUpDown
        case .resizeHorizontal:   return NSCursor.resizeLeftRight
        case .resizeDiagonalTLBR: return diagonalTLBR
        case .resizeDiagonalBLTR: return diagonalBLTR
        }
    }

    /// 绘制自定义对角线双箭头光标。
    /// - isTLBR=true: 左上↔右下方向；false: 左下↔右上方向。
    private static func makeDiagonalCursor(isTLBR: Bool) -> NSCursor {
        let s: CGFloat = 25
        let image = NSImage(size: NSSize(width: s, height: s))
        image.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return NSCursor.crosshair
        }

        // 线段两端（图像坐标系，原点左下）
        let p1 = isTLBR ? CGPoint(x: 6, y: 19) : CGPoint(x: 6, y: 6)
        let p2 = isTLBR ? CGPoint(x: 19, y: 6)  : CGPoint(x: 19, y: 19)

        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        let len = sqrt(dx * dx + dy * dy)
        let ux = dx / len
        let uy = dy / len
        let px = -uy
        let py = ux
        let aLen: CGFloat = 5
        let aSpread: CGFloat = 3.5

        func arrow(at tip: CGPoint, dirX: CGFloat, dirY: CGFloat) {
            let bx = tip.x + dirX * aLen
            let by = tip.y + dirY * aLen
            ctx.move(to: tip)
            ctx.addLine(to: CGPoint(x: bx + px * aSpread, y: by + py * aSpread))
            ctx.move(to: tip)
            ctx.addLine(to: CGPoint(x: bx - px * aSpread, y: by - py * aSpread))
        }

        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)

        // 黑色描边（外层，提高对比度）
        ctx.setStrokeColor(NSColor.black.cgColor)
        ctx.setLineWidth(3)
        ctx.move(to: p1); ctx.addLine(to: p2); ctx.strokePath()
        arrow(at: p1, dirX: -ux, dirY: -uy)
        arrow(at: p2, dirX: ux, dirY: uy)
        ctx.strokePath()

        // 白色主线（内层）
        ctx.setStrokeColor(NSColor.white.cgColor)
        ctx.setLineWidth(1.5)
        ctx.move(to: p1); ctx.addLine(to: p2); ctx.strokePath()
        arrow(at: p1, dirX: -ux, dirY: -uy)
        arrow(at: p2, dirX: ux, dirY: uy)
        ctx.strokePath()

        image.unlockFocus()
        return NSCursor(image: image, hotSpot: NSPoint(x: s / 2, y: s / 2))
    }
}
