import CoreGraphics

/// 截图选区圆角工具：预设半径、循环切换、夹取到选区尺寸上限。
/// 纯函数，无副作用，便于单测。
public enum CornerRounding {
   /// 圆角半径预设（点），0 = 关闭圆角。
   public static let presets: [CGFloat] = [0, 8, 16, 24, 32]

    /// 默认圆角半径（截图选区完成后自动启用），16 点。
    public static let defaultRadius: CGFloat = 16

    /// 循环切换到下一个预设半径。
    public static func nextRadius(_ current: CGFloat) -> CGFloat {
        guard let idx = presets.firstIndex(where: { $0 == current }) else {
            return presets.first ?? 0
        }
        return presets[(idx + 1) % presets.count]
    }

    /// 将圆角半径夹取到选区尺寸允许的最大值（不超过宽高最小值的一半）。
    public static func clampedRadius(_ radius: CGFloat, for size: CGSize) -> CGFloat {
        let maxRadius = Swift.min(size.width, size.height) / 2
        return Swift.max(0, Swift.min(radius, maxRadius))
    }

    /// 圆角是否启用（半径 > 0）。
    public static func isEnabled(_ radius: CGFloat) -> Bool {
        radius > 0
    }
}
