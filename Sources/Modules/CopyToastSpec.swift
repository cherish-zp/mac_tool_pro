import Foundation

/// 快速片段复制成功 Toast 规格：苹果风 HUD，淡入 -> 停留 -> 淡出。
public enum CopyToastSpec {
    public static let successMessage = "已复制"
    public static let symbolName = "checkmark.circle.fill"

    public static let fadeInDuration: TimeInterval = 0.18
    public static let visibleDuration: TimeInterval = 1.2
    public static let fadeOutDuration: TimeInterval = 0.28

    public static var totalDuration: TimeInterval {
        fadeInDuration + visibleDuration + fadeOutDuration
    }

    public static let cornerRadius: CGFloat = 14
    /// Toast 顶边距菜单栏下方间距。
    public static let topGap: CGFloat = 8
}
