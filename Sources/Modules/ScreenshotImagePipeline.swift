import CoreGraphics

/// 截图渲染管线：圆角蒙版 + 阴影描边（纯函数，副作用仅在位图上下文内）。
/// 均匀性约束：均匀颜色输入经任何环节后必须保持逐像素均匀，
/// 不得引入纵向亮度渐变（有单测锁定）。
public enum ScreenshotImagePipeline {

    /// 应用圆角蒙版（半径 > 0 时裁剪为圆角，四角透明），颜色空间与原一致（设备 RGB）。
    public static func applyRoundedCorners(to image: CGImage, radius: CGFloat) -> CGImage? {
        let w = image.width
        let h = image.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil, width: w, height: h,
                                  bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        let bounds = CGRect(x: 0, y: 0, width: w, height: h)
        ctx.addPath(CGPath(roundedRect: bounds, cornerWidth: radius, cornerHeight: radius, transform: nil))
        ctx.clip()
        ctx.draw(image, in: bounds)
        return ctx.makeImage()
    }

    /// 在图片最外边缘描深色边线（阴影边框），不改变图片尺寸。
    public static func applyShadowBorder(to image: CGImage, cornerRadius: CGFloat,
                                         opacity: CGFloat) -> CGImage? {
        let w = image.width
        let h = image.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil, width: w, height: h,
                                  bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        let bounds = CGRect(x: 0, y: 0, width: w, height: h)
        ctx.draw(image, in: bounds)
        let borderRect = ShadowBorder.borderRect(imageSize: bounds.size)
        ctx.setStrokeColor(ShadowBorder.borderColor(opacity: opacity))
        ctx.setLineWidth(ShadowBorder.borderWidth)
        let r = CornerRounding.clampedRadius(cornerRadius, for: bounds.size)
        if r > 0 {
            ctx.addPath(CGPath(roundedRect: borderRect, cornerWidth: r, cornerHeight: r, transform: nil))
        } else {
            ctx.addRect(borderRect)
        }
        ctx.strokePath()
        return ctx.makeImage()
    }
}
