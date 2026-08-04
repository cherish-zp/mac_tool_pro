import CoreGraphics
import Foundation

/// 标注类型：矩形、箭头、文字、马赛克。
public enum AnnotationType: String, Codable, CaseIterable {
    case rectangle
    case arrow
    case text
    case mosaic
}

/// 标注颜色（限定调色板，便于工具条统一管理）。
public enum AnnotationColor: String, Codable, CaseIterable {
    case red, yellow, green, blue, white, black
}

/// 单个标注：类型 + 点序列 + 可选文字 + 颜色 + 线宽。
/// - 矩形：points[0]=origin, points[1]=对角点
/// - 箭头：points[0]=起点, points[1]=终点
/// - 文字：points[0]=左上角定位点，text 存内容
/// - 马赛克：points[0]=origin, points[1]=对角点
public struct Annotation: Codable, Equatable, Identifiable {
    public let id: UUID
    public var type: AnnotationType
    public var points: [CGPoint]
    public var text: String?
    public var color: AnnotationColor
    public var strokeWidth: CGFloat

    public init(
        id: UUID = UUID(),
        type: AnnotationType,
        points: [CGPoint],
        text: String? = nil,
        color: AnnotationColor = .red,
        strokeWidth: CGFloat = 3
    ) {
        self.id = id
        self.type = type
        self.points = points
        self.text = text
        self.color = color
        self.strokeWidth = strokeWidth
    }
}

/// 标注集合：管理添加/删除/撤销/清空，支持 Codable 序列化。
public final class AnnotationModel: Codable {
    public private(set) var annotations: [Annotation] = []

    public init() {}

    public var count: Int { annotations.count }

    /// 是否有可撤销的标注（用于启用/禁用撤销按钮）。
    public var canUndo: Bool { !annotations.isEmpty }

    public func add(_ annotation: Annotation) {
        annotations.append(annotation)
    }

    public func remove(at index: Int) {
        guard annotations.indices.contains(index) else { return }
        annotations.remove(at: index)
    }

    /// 撤销最后一个标注，返回被移除的标注（空时返回 nil）。
    @discardableResult
    public func undo() -> Annotation? {
        annotations.popLast()
    }

    public func clear() {
        annotations.removeAll()
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case annotations
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        annotations = try container.decode([Annotation].self, forKey: .annotations)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(annotations, forKey: .annotations)
    }

    /// 选颜色时确定使用的标注工具：未选工具则默认矩形，使「点颜色即可画框」。
    public static func defaultTool(whenColorSelected currentTool: AnnotationType?) -> AnnotationType? {
        currentTool ?? .rectangle
    }

    /// 创建文字标注：空文本返回 nil（不创建无效标注）。
    public static func textAnnotation(at point: CGPoint, text: String, color: AnnotationColor) -> Annotation? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Annotation(type: .text, points: [point], text: trimmed, color: color)
    }
}
