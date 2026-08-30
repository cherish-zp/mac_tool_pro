import AppKit

/// 呼吸灯颜色工具：hex ↔ NSColor 解析与预设色板。
/// 纯逻辑，便于单测；视图层据此渲染色板与横条颜色。
public enum PinIndicatorColor {

    /// 默认呼吸灯颜色：亮绿色（与历史版本一致的观感）。
    public static let defaultHex = "4DD94F"

    /// 预设色板（hex，不含 #），默认色必须包含在内。
    public static let paletteHexes: [String] = [
        "4DD94F",  // 绿（默认）
        "FF3B30",  // 红
        "FF9F0A",  // 橙
        "FFD60A",  // 黄
        "FF2D92",  // 粉
        "0A84FF",  // 蓝
        "FFFFFF",  // 白
        "1C1C1E",  // 黑
    ]

    /// 解析 6 位 hex（容忍前缀 #）；非法输入返回 nil。
    public static func color(fromHex hex: String) -> NSColor? {
        let trimmed = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard trimmed.count == 6, let value = UInt32(trimmed, radix: 16) else { return nil }
        return NSColor(calibratedRed: CGFloat((value >> 16) & 0xFF) / 255.0,
                       green: CGFloat((value >> 8) & 0xFF) / 255.0,
                       blue: CGFloat(value & 0xFF) / 255.0,
                       alpha: 1.0)
    }
}
