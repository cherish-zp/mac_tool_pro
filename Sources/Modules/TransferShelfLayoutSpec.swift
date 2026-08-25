import Foundation
import AppKit

/// 文件中转站布局规格：顶部横向面板、条目尺寸、动画参数。
public enum TransferShelfLayoutSpec {
    public static let panelHeight: CGFloat = 68
    public static let itemSize: CGFloat = 52
    public static let itemSpacing: CGFloat = 10
    public static let panelPadding: CGFloat = 12
    public static let cornerRadius: CGFloat = 20
    public static let fadeInDuration: TimeInterval = 0.2
    public static let fadeOutDuration: TimeInterval = 0.25
    public static let topGap: CGFloat = 4
    /// 面板从顶部上方滑入的距离。
    public static let slideInOffset: CGFloat = 12
    /// 顶部热区（拖拽会话期间激活，文件拖入即呼出面板）。
    public static let hotZoneWidth: CGFloat = 320
    public static let hotZoneHeight: CGFloat = 18
    /// 判断点是否位于指定屏幕可见区域顶部中央的热区内。
    public static func isInHotZone(location: NSPoint, visibleFrame: NSRect) -> Bool {
        let rect = NSRect(
            x: visibleFrame.midX - hotZoneWidth / 2,
            y: visibleFrame.maxY - hotZoneHeight,
            width: hotZoneWidth,
            height: hotZoneHeight
        )
        return NSPointInRect(location, rect)
    }

    /// 竖向排布：面板固定宽度与横向条目尺寸（图标左 + 文件名右）。
    public static let verticalPanelWidth: CGFloat = 180
    public static let verticalItemWidth: CGFloat = 156
    public static let verticalItemHeight: CGFloat = 44

    /// 竖向面板高度：随条目数增长，封顶 maxHeight。
    public static func panelHeight(itemCount: Int, maxHeight: CGFloat = 400) -> CGFloat {
        let content = verticalItemHeight * CGFloat(itemCount) + itemSpacing * CGFloat(max(0, itemCount - 1))
        return min(panelPadding * 2 + content, maxHeight)
    }

    /// 面板半透明背景不透明度（自绘圆角背景，彻底消除透明直角）。
    public static let panelBackgroundAlpha: CGFloat = 0.82

    /// 面板发丝描边宽度与条目圆角（苹果风细节）。
    public static let panelHairlineWidth: CGFloat = 1
    public static let itemCornerRadius: CGFloat = 12

    /// 条目右上角单独删除按钮。
    public static let itemClearButtonSize: CGFloat = 12
    public static let itemClearButtonOffset: CGFloat = 2

    /// 拖出条目时的预览图像帧（NSDraggingItem 必须设置非零 frame，否则崩溃）。
    public static let dragImageFrame: NSRect = NSRect(x: 0, y: 0, width: 64, height: 64)

    /// 面板宽度：随条目数增长，封顶 maxWidth。
    public static func panelWidth(itemCount: Int, maxWidth: CGFloat = 560) -> CGFloat {
        let content = itemSize * CGFloat(itemCount) + itemSpacing * CGFloat(max(0, itemCount - 1))
        return min(panelPadding * 2 + content, maxWidth)
    }
}
