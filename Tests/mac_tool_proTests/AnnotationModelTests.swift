import XCTest
import CoreGraphics

/// TDD: 截图标注数据模型 - 添加/删除/撤销/清空标注，支持矩形/箭头/文字/马赛克。
final class AnnotationModelTests: XCTestCase {

    func test_addAndCount() {
        let model = AnnotationModel()
        XCTAssertEqual(model.count, 0)
        model.add(makeAnnotation(.rectangle))
        model.add(makeAnnotation(.arrow))
        XCTAssertEqual(model.count, 2)
    }

    func test_undo_removesLast() {
        let model = AnnotationModel()
        let a1 = makeAnnotation(.rectangle)
        let a2 = makeAnnotation(.arrow)
        model.add(a1)
        model.add(a2)
        let removed = model.undo()
        XCTAssertEqual(removed?.id, a2.id)
        XCTAssertEqual(model.count, 1)
    }

    func test_undo_emptyReturnsNil() {
        let model = AnnotationModel()
        XCTAssertNil(model.undo())
    }

    func test_removeAt() {
        let model = AnnotationModel()
        model.add(makeAnnotation(.rectangle))
        model.add(makeAnnotation(.arrow))
        model.remove(at: 0)
        XCTAssertEqual(model.count, 1)
        XCTAssertEqual(model.annotations.first?.type, .arrow)
    }

    func test_clear() {
        let model = AnnotationModel()
        model.add(makeAnnotation(.rectangle))
        model.add(makeAnnotation(.text))
        model.clear()
        XCTAssertEqual(model.count, 0)
    }

    func test_codableRoundTrip() throws {
        let model = AnnotationModel()
        model.add(makeAnnotation(.rectangle))
        model.add(makeAnnotation(.text, text: "你好"))
        let data = try JSONEncoder().encode(model)
        let back = try JSONDecoder().decode(AnnotationModel.self, from: data)
        XCTAssertEqual(back.count, 2)
        XCTAssertEqual(back.annotations[1].text, "你好")
    }

    // MARK: - Helpers

    // MARK: - 选颜色时默认工具

    // MARK: - 文字标注创建

    func test_textAnnotation_nonEmpty() {
        let ann = AnnotationModel.textAnnotation(at: CGPoint(x: 50, y: 60), text: "你好世界", color: .red)
        XCTAssertEqual(ann?.type, .text)
        XCTAssertEqual(ann?.text, "你好世界")
        XCTAssertEqual(ann?.color, .red)
        XCTAssertEqual(ann?.points, [CGPoint(x: 50, y: 60)])
    }

    func test_textAnnotation_emptyReturnsNil() {
        XCTAssertNil(AnnotationModel.textAnnotation(at: .zero, text: "", color: .red))
        XCTAssertNil(AnnotationModel.textAnnotation(at: .zero, text: "   ", color: .red))
    }

    func test_defaultTool_whenColorSelected_noTool() {
        // 未选工具时点颜色，应默认矩形工具，使「点红色即可画红框」
        XCTAssertEqual(AnnotationModel.defaultTool(whenColorSelected: nil), .rectangle)
    }

    func test_defaultTool_whenColorSelected_hasTool() {
        // 已选工具时点颜色，保持原工具不变
        XCTAssertEqual(AnnotationModel.defaultTool(whenColorSelected: .arrow), .arrow)
    }

    private func makeAnnotation(_ type: AnnotationType, text: String? = nil) -> Annotation {
        Annotation(
            type: type,
            points: [CGPoint(x: 10, y: 10), CGPoint(x: 100, y: 100)],
            text: text,
            color: .red,
            strokeWidth: 3
        )
    }
}
