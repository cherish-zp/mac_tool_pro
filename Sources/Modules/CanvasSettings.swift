import CoreGraphics

/// 画布设置：圆角 + 阴影（开关、透明度、模糊半径、偏移）。
/// 纯值类型，便于单测；渲染副作用由调用方处理。
public struct CanvasSettings: Equatable {

    /// 圆角半径（点），0 = 直角。
    public var cornerRadius: CGFloat

    /// 阴影是否启用。
    public var shadowEnabled: Bool

    /// 阴影透明度（0-1），默认 0.16 = 16%。
    public var shadowOpacity: CGFloat

    /// 阴影模糊半径（点）。
    public var shadowBlur: CGFloat

    /// 阴影偏移（点）。
    public var shadowOffset: CGSize

    /// 默认画布设置：圆角 16 点，阴影开启，透明度 16%，模糊 30 点。
    public static let `default` = CanvasSettings(
        cornerRadius: CornerRounding.defaultRadius,
        shadowEnabled: true,
        shadowOpacity: 0.16,
        shadowBlur: 20,
        shadowOffset: CGSize(width: 0, height: -4)
    )

    public init(
        cornerRadius: CGFloat = CornerRounding.defaultRadius,
        shadowEnabled: Bool = true,
        shadowOpacity: CGFloat = 0.16,
        shadowBlur: CGFloat = 20,
        shadowOffset: CGSize = CGSize(width: 0, height: -4)
    ) {
        self.cornerRadius = cornerRadius
        self.shadowEnabled = shadowEnabled
        self.shadowOpacity = shadowOpacity
        self.shadowBlur = shadowBlur
        self.shadowOffset = shadowOffset
    }

    /// 切换阴影开关，保留其余设置。
    public func toggledShadow() -> CanvasSettings {
        var copy = self
        copy.shadowEnabled.toggle()
        return copy
    }

    /// 设置阴影透明度（夹取到 0-1）。
    public func withShadowOpacity(_ opacity: CGFloat) -> CanvasSettings {
        var copy = self
        copy.shadowOpacity = Swift.max(0, Swift.min(1, opacity))
        return copy
    }

    /// 循环切换到下一个圆角半径预设，并根据选区尺寸夹取。
    public func withNextCornerRadius(selectionSize: CGSize) -> CanvasSettings {
        var copy = self
        let next = CornerRounding.nextRadius(cornerRadius)
        copy.cornerRadius = CornerRounding.clampedRadius(next, for: selectionSize)
        return copy
    }
}
