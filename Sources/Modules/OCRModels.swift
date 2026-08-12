import CoreGraphics
import Foundation

/// OCR 识别结果项：文字、置信度、归一化边界框（原点左下，0-1）。
public struct OCRTextItem: Equatable {
    public let text: String
    public let confidence: Float
    public let boundingBox: CGRect

    public init(text: String, confidence: Float, boundingBox: CGRect) {
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
    }
}

/// OCR 文字排序与格式化：按阅读顺序排列（从上到下、从左到右）、行分组、输出可复制文本。
public enum OCRTextSorter {

    /// 行分组阈值（归一化 Y 坐标差），小于此值视为同一行。
    public static let rowThreshold: CGFloat = 0.03

    /// 按阅读顺序排序：Y 越大（越靠上）排前面，同行内 X 从小到大（从左到右）。
    public static func sortByReadingOrder(_ items: [OCRTextItem]) -> [OCRTextItem] {
        items.sorted { a, b in
            let aCY = a.boundingBox.midY
            let bCY = b.boundingBox.midY
            if abs(aCY - bCY) > rowThreshold {
                return aCY > bCY
            }
            return a.boundingBox.minX < b.boundingBox.minX
        }
    }

    /// 按置信度过滤，移除低于阈值的项。
    public static func filterByConfidence(_ items: [OCRTextItem], minConfidence: Float = 0.5) -> [OCRTextItem] {
        items.filter { $0.confidence >= minConfidence }
    }

    /// 将识别结果转为可复制文本：同行用空格连接，不同行用换行分隔。
    public static func toText(_ items: [OCRTextItem]) -> String {
        guard !items.isEmpty else { return "" }
        let sorted = sortByReadingOrder(items)
        var lines: [String] = []
        var currentLine: [String] = []
        var lastCenterY: CGFloat?

        for item in sorted {
            if let lastY = lastCenterY, abs(item.boundingBox.midY - lastY) > rowThreshold {
                lines.append(currentLine.joined(separator: " "))
                currentLine = []
            }
            currentLine.append(item.text)
            lastCenterY = item.boundingBox.midY
        }
        if !currentLine.isEmpty {
            lines.append(currentLine.joined(separator: " "))
        }
        return lines.joined(separator: "\n")
    }
}
