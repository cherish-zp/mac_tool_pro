import CoreGraphics

/// 提示文字垂直居中：根据字体度量计算文字基线 y 坐标。
/// NSTextField 默认渲染偏上（ascender > |descender| 时），
/// 此模块用字体度量精确计算基线，使文字在容器内视觉居中。
public enum TooltipTextCentering {

    /// 计算文字绘制基线的 y 坐标（容器坐标系，底部为 0），使文字视觉居中。
    /// - Parameters:
    ///   - containerHeight: 容器高度
    ///   - ascender: 字体 ascender（基线到字符顶部，正值）
    ///   - descender: 字体 descender（基线到字符底部，负值）
    /// - Returns: 基线 y 坐标
    public static func baselineY(
        containerHeight: CGFloat, ascender: CGFloat, descender: CGFloat
    ) -> CGFloat {
        containerHeight / 2 - (ascender + descender) / 2
    }
}
