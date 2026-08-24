import Foundation

/// 文件中转站布局规格：顶部横向面板、条目尺寸、动画参数。
public enum TransferShelfLayoutSpec {
    public static let panelHeight: CGFloat = 68
    public static let itemSize: CGFloat = 52
    public static let itemSpacing: CGFloat = 10
    public static let panelPadding: CGFloat = 12
    public static let cornerRadius: CGFloat = 20
    public static let fadeInDuration: TimeInterval = 0.2
    public static let fadeOutDuration: TimeInterval = 0.25
    public static let topGap: CGFloat = 8

    /// 面板宽度：随条目数增长，封顶 maxWidth。
    public static func panelWidth(itemCount: Int, maxWidth: CGFloat = 560) -> CGFloat {
        let content = itemSize * CGFloat(itemCount) + itemSpacing * CGFloat(max(0, itemCount - 1))
        return min(panelPadding * 2 + content, maxWidth)
    }
}
