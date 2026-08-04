import CoreGraphics

/// 光标所在的交互区域，用于决定光标样式。
public enum CursorContext: Equatable {
    case screenshotArea  // 截图选区内（编辑模式）
    case toolbarArea     // 工具条区域
    case background      // 选区外背景（选区阶段）
}

/// 光标样式枚举，映射到 NSCursor。
public enum CursorStyle: Equatable {
    case crosshair            // 十字光标
    case arrow                // 箭头光标
    case move                 // 移动光标
    case resizeVertical       // 垂直缩放
    case resizeHorizontal     // 水平缩放
    case resizeDiagonalTLBR   // 左上-右下对角缩放
    case resizeDiagonalBLTR   // 左下-右上对角缩放
}

public extension CursorContext {
    /// 该区域默认的光标样式。
    var defaultStyle: CursorStyle {
        switch self {
        case .screenshotArea: return .crosshair
        case .toolbarArea:    return .arrow
        case .background:     return .crosshair
        }
    }

    /// 是否需要切换动效（区域变化时触发）。
    static func shouldAnimate(from: CursorContext, to: CursorContext) -> Bool {
        from != to
    }
}
