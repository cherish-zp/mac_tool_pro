import Foundation

/// 贴图呼吸灯样式变更通知：设置窗口切换后，已打开的贴图立即生效。
public extension Notification.Name {
    static let pinIndicatorStyleDidChange =
        Notification.Name("com.zp.mac-tool-pro.pin-indicator-style-did-change")
}

/// 贴图呼吸灯样式：顶部横条（默认）或左上角圆点。
public enum PinIndicatorStyle: String, Codable, Equatable, CaseIterable {
    /// 顶部 2pt 横条呼吸灯，宽度与贴图等宽。
    case topBar
    /// 左上角圆点闪烁指示（兼关闭按钮）。
    case cornerDot
}

/// 贴图设置状态（可扩展更多字段）。
public struct PinSettingsState: Codable, Equatable {
    public var indicatorStyle: PinIndicatorStyle

    public init(indicatorStyle: PinIndicatorStyle = .topBar) {
        self.indicatorStyle = indicatorStyle
    }
}

/// 贴图设置持久化：JSON 存 Application Support，损坏/缺失回退默认。
/// 通过 fileURL 注入便于单测；副作用（文件系统）藏在此处。
public struct PinSettingsStore {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// App 默认存储位置。
    public static func defaultStore() -> PinSettingsStore {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let dir = base.appendingPathComponent("mac_tool_pro", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return PinSettingsStore(fileURL: dir.appendingPathComponent("pin_settings.json"))
    }

    public func load() -> PinSettingsState {
        guard let data = try? Data(contentsOf: fileURL),
              let state = try? JSONDecoder().decode(PinSettingsState.self, from: data) else {
            return PinSettingsState()
        }
        return state
    }

    public func save(_ state: PinSettingsState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
