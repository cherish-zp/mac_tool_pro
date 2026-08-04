import CoreGraphics

/// 缩放手柄对应的光标类型，用于鼠标悬停和拖拽时改变光标样式。
public enum ResizeCursorKind: Equatable {
    case move               // 选区内部拖拽移动
    case resizeVertical     // 上下边
    case resizeHorizontal   // 左右边
    case resizeDiagonalTLBR // 左上-右下对角线
    case resizeDiagonalBLTR // 左下-右上对角线
    case crosshair          // 默认十字光标
}

public extension ResizeHandle {
    /// 根据手柄位置返回对应的光标类型。
    var cursorKind: ResizeCursorKind {
        switch self {
        case .top, .bottom: return .resizeVertical
        case .left, .right: return .resizeHorizontal
        case .topLeft, .bottomRight: return .resizeDiagonalTLBR
        case .topRight, .bottomLeft: return .resizeDiagonalBLTR
        case .interior: return .move
        }
    }
}
