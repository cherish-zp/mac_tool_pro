import XCTest
import CoreGraphics

/// TDD: OCR 文字排序与格式化 - 按阅读顺序排列、行分组、输出可复制文本。
final class OCRTextSorterTests: XCTestCase {

    private func item(_ text: String, x: CGFloat = 0.1, y: CGFloat = 0.5, conf: Float = 0.9) -> OCRTextItem {
        OCRTextItem(text: text, confidence: conf,
                     boundingBox: CGRect(x: x, y: y, width: 0.1, height: 0.05))
    }

    func test_sortByReadingOrder_topToBottom() {
        // y 越大 = 越靠上 = 排前面
        let items = [item("下", x: 0.1, y: 0.2), item("上", x: 0.1, y: 0.8)]
        let sorted = OCRTextSorter.sortByReadingOrder(items)
        XCTAssertEqual(sorted[0].text, "上")
        XCTAssertEqual(sorted[1].text, "下")
    }

    func test_sortByReadingOrder_leftToRightWithinRow() {
        // 同一行内按 x 从左到右
        let items = [item("右", x: 0.7, y: 0.5), item("左", x: 0.1, y: 0.5)]
        let sorted = OCRTextSorter.sortByReadingOrder(items)
        XCTAssertEqual(sorted[0].text, "左")
        XCTAssertEqual(sorted[1].text, "右")
    }

    func test_filterByConfidence_removesLowConfidence() {
        let items = [item("高", conf: 0.9), item("低", conf: 0.3)]
        let filtered = OCRTextSorter.filterByConfidence(items, minConfidence: 0.5)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].text, "高")
    }

    func test_toText_sameLineJoinedWithSpace() {
        let items = [item("你", x: 0.1, y: 0.5), item("好", x: 0.3, y: 0.5)]
        let text = OCRTextSorter.toText(items)
        XCTAssertEqual(text, "你 好")
    }

    func test_toText_differentLinesJoinedWithNewline() {
        let items = [item("第一行", x: 0.1, y: 0.8), item("第二行", x: 0.1, y: 0.2)]
        let text = OCRTextSorter.toText(items)
        XCTAssertEqual(text, "第一行\n第二行")
    }

    func test_toText_emptyItems_returnsEmptyString() {
        XCTAssertEqual(OCRTextSorter.toText([]), "")
    }

    func test_toText_multipleItemsMultipleLines() {
        let items = [
            item("A", x: 0.1, y: 0.8),
            item("B", x: 0.4, y: 0.8),
            item("C", x: 0.1, y: 0.4),
            item("D", x: 0.4, y: 0.4),
        ]
        let text = OCRTextSorter.toText(items)
        XCTAssertEqual(text, "A B\nC D")
    }
}
