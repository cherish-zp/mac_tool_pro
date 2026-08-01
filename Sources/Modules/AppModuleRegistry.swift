import Foundation

/// App 模块注册表：登记模块、管理启用状态，并把启用模块的默认热键绑定到 HotkeyManager。
public final class AppModuleRegistry {
    public private(set) var modules: [AppModule] = []
    private var enabled: [String: Bool] = [:]
    private let hotkeyManager: HotkeyManager

    public init(hotkeyManager: HotkeyManager) {
        self.hotkeyManager = hotkeyManager
    }

    public func register(_ module: AppModule) {
        modules.append(module)
        if isEnabled(module.id) {
            bind(module)
        }
    }

    public func module(for id: String) -> AppModule? {
        modules.first { $0.id == id }
    }

    public func isEnabled(_ id: String) -> Bool {
        enabled[id] ?? true
    }

    public func setEnabled(_ id: String, _ on: Bool) {
        enabled[id] = on
        guard let module = module(for: id) else { return }
        if on {
            bind(module)
        } else {
            hotkeyManager.unregister(module.defaultHotkey)
        }
    }

    private func bind(_ module: AppModule) {
        hotkeyManager.register(module.defaultHotkey) { [weak module] in
            module?.perform()
        }
    }
}
