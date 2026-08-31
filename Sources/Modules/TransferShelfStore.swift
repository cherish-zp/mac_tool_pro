import Foundation

/// 文件中转条目：只保存 URL 引用，不复制文件本体。
public struct TransferItem: Codable, Identifiable, Equatable {
    public let id: UUID
    public let url: URL
    public let name: String
    public let addedAt: Date

    public init(id: UUID = UUID(), url: URL, name: String? = nil, addedAt: Date = Date()) {
        self.id = id
        self.url = url
        self.name = name ?? url.lastPathComponent
        self.addedAt = addedAt
    }
}

/// 文件中转站存储纯逻辑：URL 引用式暂存，去重、删除、持久化、失效检测。
/// 文件系统访问通过 fileExists 闭包注入，便于单测。
public struct TransferShelfStore {
    public private(set) var items: [TransferItem] = []

    public init() {}

    /// 添加文件 URL。同一 URL 已存在时返回 nil（去重）。
    @discardableResult
    public mutating func add(url: URL) -> TransferItem? {
        guard !items.contains(where: { $0.url == url }) else { return nil }
        let item = TransferItem(url: url)
        items.append(item)
        return item
    }

    /// 移除指定条目。
    @discardableResult
    public mutating func remove(id: UUID) -> Bool {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return false }
        items.remove(at: idx)
        return true
    }

    /// 清空全部条目。
    public mutating func clear() {
        items.removeAll()
    }

    /// 是否已包含指定 URL。
    public func contains(url: URL) -> Bool {
        items.contains { $0.url == url }
    }

    /// 编码为 JSON 数据，交给调用方持久化。
    public func encode() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(items)
    }

    /// 从 JSON 数据恢复。
    public static func load(from data: Data) -> TransferShelfStore {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let items = try? decoder.decode([TransferItem].self, from: data) else {
            return TransferShelfStore()
        }
        var store = TransferShelfStore()
        store.items = items
        return store
    }

    /// 条目引用的文件是否仍存在（fileExists 注入便于测试）。
    public func isValid(_ item: TransferItem, fileExists: (URL) -> Bool) -> Bool {
        fileExists(item.url)
    }

    /// 移除所有文件已不存在（被移走/重命名/删除）的条目，返回被移除的条目（保持原顺序）。
    /// 文件存在性通过 fileExists 注入，便于单测。
    @discardableResult
    public mutating func purgeInvalid(fileExists: (URL) -> Bool) -> [TransferItem] {
        var kept: [TransferItem] = []
        var removed: [TransferItem] = []
        for item in items {
            if fileExists(item.url) {
                kept.append(item)
            } else {
                removed.append(item)
            }
        }
        items = kept
        return removed
    }
}
