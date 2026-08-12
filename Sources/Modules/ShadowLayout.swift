import CoreGraphics

/// 阴影布局：计算紧凑的阴影输出尺寸和绘制位置。
/// 使用 60% 模糊半径作为内边距，避免过多透明边距。
public enum ShadowLayout {

    /// 阴影内边距：紧凑模式，取模糊半径 60% + 偏移最大值 + 1。
    public static func padding(blur: CGFloat, offset: CGSize) -> CGFloat {
        if blur <= 0 && offset.width == 0 && offset.height == 0 { return 0 }
        return ceil(blur * 0.6) + max(abs(offset.width), abs(offset.height)) + 1
    }

    /// 阴影输出图片尺寸 = 原图 + 两侧内边距。
    public static func outputSize(imageSize: CGSize, blur: CGFloat, offset: CGSize) -> CGSize {
        let pad = padding(blur: blur, offset: offset)
        return CGSize(width: imageSize.width + pad * 2, height: imageSize.height + pad * 2)
    }

    /// 原图在输出画布中的绘制矩形（居中，四周留内边距）。
    public static func drawImageRect(imageSize: CGSize, blur: CGFloat, offset: CGSize) -> CGRect {
        let pad = padding(blur: blur, offset: offset)
        return CGRect(x: pad, y: pad, width: imageSize.width, height: imageSize.height)
    }
}
