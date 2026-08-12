import CoreGraphics

/// 阴影边框：在截图最外边缘绘制深色边线，不改变图片尺寸。
/// 阴影透明度控制边线颜色深浅（默认 16%）。
/// 与 ShadowLayout（投影式阴影，扩大图片）不同，此模块仅描边。
public enum ShadowBorder {

    /// 边框宽度（像素），1 像素。
    public static let borderWidth: CGFloat = 1

    /// 边框颜色：黑色 + 指定透明度（夹取到 0-1）。
    public static func borderColor(opacity: CGFloat) -> CGColor {
        let clamped = Swift.max(0, Swift.min(1, opacity))
        return CGColor(red: 0, green: 0, blue: 0, alpha: clamped)
    }

    /// 输出尺寸 = 原图尺寸（不扩大）。
    public static func outputSize(imageSize: CGSize) -> CGSize {
        imageSize
    }

    /// 边框绘制矩形：内缩半个边框宽度，使描边居中于边缘。
    public static func borderRect(imageSize: CGSize) -> CGRect {
        let half = borderWidth / 2
        return CGRect(x: half, y: half,
                      width: imageSize.width - borderWidth,
                      height: imageSize.height - borderWidth)
    }
}
