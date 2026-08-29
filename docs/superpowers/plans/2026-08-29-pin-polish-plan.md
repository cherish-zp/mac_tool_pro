# 贴图呼吸灯美化 + 右键复制 计划

日期：2026-08-29
来源：用户两项需求（多子代理开发）

## Global Constraints（摘自 AGENTS.md，对所有任务生效）

- Swift 5，4 空格缩进，中文注释；逻辑纯函数、副作用藏于协议注入之后。
- TDD：RED → GREEN，必须先观察到测试失败再写实现。
- 测试命令：
  `export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && cd /Users/zhangpeng/code_bigmodel/mac_tool_pro && xcodebuild test -scheme mac_tool_proTests -destination 'platform=macOS' -derivedDataPath build/DerivedData CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO`
- 新增文件后必须 `xcodegen generate`。
- 视图层（NSView/NSWindow 子类）不做单测——仓库既有惯例；可测逻辑放 Sources/Modules 或 Sources/Shared。
- 禁止触碰 entitlements / Info.plist；禁止安装到 /Applications 或运行 package.sh（由控制者统一构建安装）；禁止提交 build/ dist/ *.xcodeproj。
- 提交规范：`fix:`/`feat:` + 简洁中文摘要。
- 签名教训：构建一律 adhoc 测试用；正式安装由控制者用 package.sh。

## Task 1: 呼吸灯美化（2px + 贴图同弧度 + 悬停 X 减半）

文件：`Sources/App/Screenshot/PinWindow.swift`、`Sources/Modules/PinScaler.swift`、`Tests/mac_tool_proTests/PinScalerTests.swift`、`Sources/App/Screenshot/ScreenshotCoordinator.swift`（仅两处 PinWindow 构造传参）。

1. `PinIndicatorBar.barHeight` 1 → **2**。
2. 呼吸灯贴合贴图圆角：贴图图片钉住时已按 `CornerRounding` 烘焙圆角（透明四角）。要求：
   - `PinWindow.init` 增加 `cornerRadius: CGFloat` 参数（点空间，默认 0）。
   - `PinImageView` 保存 baseRadius；`PinIndicatorBar` 绘制时把顶部条裁剪到「整张图片 bounds、半径 R」的圆角矩形路径内（R = baseRadius × currentScale，随滚轮缩放同步更新），使横条两端跟随图片圆角弧度。路径在 bar 自身坐标系中以 bar 顶边为圆角矩形顶边。
   - `pinToDesktop` 创建点：传入与 `renderFinalImage` 相同口径的半径（`CornerRounding.clampedRadius(overlay 视图 cornerRadius, for: sel.size)`，注意从 activeOverlay 取视图）；滚动截图贴图（`finishScrollCapture`）传 0（该图未做圆角）。
3. 悬停浮现的红色 X 按钮（topBar 模式）尺寸减半：
   - `PinScaler` 新增 `originalRevealButtonSize = 11`、`minRevealButtonSize = 8`、`maxRevealButtonSize = 30`、`scaledRevealButtonSize(scaleFactor:)`、`scaledRevealButtonFrame(viewBounds:scaleFactor:)`（边距沿用 originalMargin × scaleFactor，定位逻辑与 scaledButtonFrame 一致）。
   - `PinCloseButton` 暴露当前 mode；`PinImageView.updateCloseButtonFrame` 按模式选 frame 函数（cornerDot 维持 22 系）。
   - X 图标绘制改为随按钮尺寸等比（r ≈ 0.18 × 宽度，线宽 ≈ max(1.5, 0.09 × 宽度)），保持 22pt 时与现状视觉一致。
4. TDD：先在 `PinScalerTests` 写 reveal 系列失败测试（RED）再实现；视图改动不做单测。
5. 单独一个 `fix:` 提交。

## Task 2: 贴图右键复制图片到剪贴板

文件：`Sources/Shared/Clipboard.swift`、`Tests/mac_tool_proTests/`（新测试文件 + 更新既有 PasteboardSpy）、新增 `Sources/App/Screenshot/PinContextMenu.swift`、`Sources/App/Screenshot/PinWindow.swift`（仅加 rightMouseDown 接线）。

1. `Pasteboard` 协议增加 `func copyImage(_ image: CGImage)`；`SystemPasteboard` 改为可注入 `init(pasteboard: NSPasteboard = .general)`；实现与 `ScreenshotCoordinator.copyToClipboard` 现有行为一致（clearContents + writeObjects）。同步更新 `CopyPathToolTests.swift` 中 `PasteboardSpy`。
2. 测试（RED→GREEN）：用 `NSPasteboard(name:)` 私有剪贴板注入 SystemPasteboard，copyImage 后能读回 NSImage 且尺寸与原图一致；既有 copy(string:) 行为回归。
3. 新文件 `PinContextMenu.swift`：为贴图构建右键菜单，菜单项「复制图片」，点击回调执行注入的 `Pasteboard.copyImage(原始 CGImage 全分辨率)`；`PinImageView.rightMouseDown(with:)` 在鼠标处弹出。
4. 新增文件后 `xcodegen generate`。
5. 单独一个 `feat:` 提交。

## 冲突扫描（控制者预检）

| 项 | 结论 |
|---|---|
| Task1 与 Task2 共享 PinWindow.swift | Ruling：**顺序派发**（并行会编辑冲突 + 共享构建系统），Task1 先行 |
| Task1 不新增文件，Task2 新增文件需 xcodegen | 顺序执行下无 pbxproj 竞争 |
| Task1 产出的 PinCloseButton.mode 供自身使用；Task2 不依赖 | 无接口冲突 |
| Task1 动 PinScaler/PinScalerTests；Task2 动 Clipboard/新测试 | 文件集无交集 |
