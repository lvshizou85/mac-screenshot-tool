# Mac Screenshot Tool - MVP 实现计划

> 制定日期: 2026-05-07
> 负责人: Codex
> 输入: `docs/research.md`
> 目标: 先交付一个可运行的 macOS 菜单栏截图工具 MVP，使用 Swift Package Manager 构建，不依赖 Xcode 工程。

---

## 1. MVP 目标

交付一个常驻菜单栏的 macOS 应用，用户可以从菜单栏触发截图，并将截图保存到本地目录。MVP 采用 `/usr/sbin/screencapture` 作为截图后端，避免在第一版引入 ScreenCaptureKit、CGWindow API 或复杂权限模型。

### 必须完成

1. 菜单栏入口可启动、可退出。
2. 支持全屏截图保存到默认目录。
3. 支持交互式区域截图保存到默认目录。
4. 截图文件自动命名，避免覆盖。
5. 用户取消交互式截图时不报错、不弹失败通知。
6. 截图成功后发送系统通知，并可在 Finder 中定位文件。
7. 提供最小设置面板：保存目录、图片格式、是否复制到剪贴板。

### 暂不纳入 MVP

1. 全局快捷键。
2. 截图历史列表。
3. 自定义矩形坐标截图 UI。
4. 多显示器选择。
5. ScreenCaptureKit 后端。
6. App Store 沙盒化、签名、公证流程。

---

## 2. 技术路线

### 构建方式

使用 Swift Package Manager，项目根目录建议为：

```text
/Users/lvshizou/mac-screenshot-tool
├── Package.swift
├── Sources/
│   └── MacScreenshotTool/
│       ├── MacScreenshotToolApp.swift
│       ├── Core/
│       │   └── ScreenshotEngine.swift
│       ├── Models/
│       │   ├── AppSettings.swift
│       │   └── CaptureMode.swift
│       ├── Services/
│       │   ├── FileService.swift
│       │   ├── ClipboardService.swift
│       │   └── NotificationService.swift
│       └── Views/
│           ├── MenuBarContent.swift
│           └── SettingsView.swift
└── docs/
    ├── research.md
    └── plan.md
```

### 平台与框架

1. Swift 6.3.1。
2. macOS 14+。
3. SwiftUI `MenuBarExtra`。
4. AppKit 用于 `NSPasteboard`、`NSWorkspace`、`NSOpenPanel`。
5. UserNotifications 用于完成通知。

### 截图后端

第一版统一通过 `Process` 调用：

```text
/usr/sbin/screencapture
```

推荐参数：

1. 全屏截图：`-x -m <output-path>`
2. 交互式区域截图：`-x -i -s <output-path>`
3. 指定格式：`-t png|jpg|pdf`
4. 剪贴板：MVP 建议先截图到文件，再由应用读取文件写入 `NSPasteboard`，这样保存和复制逻辑一致。

---

## 3. 模块设计

### `CaptureMode`

定义截图模式：

```swift
enum CaptureMode {
    case mainDisplay
    case interactiveRegion
}
```

MVP 不需要先支持窗口截图和自定义矩形；保留扩展空间即可。

### `AppSettings`

职责：

1. 保存目录 URL。
2. 图片格式：`png`、`jpg`、`pdf`。
3. 是否截图后复制到剪贴板。
4. 是否截图后在 Finder 中显示。

实现建议：

1. 使用 `@Observable` 或 `ObservableObject`。
2. 用 `UserDefaults` 持久化。
3. 保存目录默认 `~/Desktop`。
4. 格式默认 `png`。

### `FileService`

职责：

1. 创建输出文件 URL。
2. 自动生成文件名。
3. 确保保存目录存在。

文件名建议：

```text
Screenshot yyyy-MM-dd HH.mm.ss.png
```

如果同一秒冲突，追加 `-1`、`-2`。

### `ScreenshotEngine`

职责：

1. 根据 `CaptureMode` 组装 `screencapture` 参数。
2. 异步启动进程，等待退出码。
3. 区分成功、失败、用户取消。

错误建议：

```swift
enum ScreenshotError: Error {
    case commandUnavailable
    case cancelled
    case failed(exitCode: Int32, stderr: String)
}
```

取消处理：

1. 交互式截图中用户按 ESC 时，`screencapture` 会返回非 0。
2. 如果输出文件不存在或文件大小为 0，优先视为取消。
3. 取消不应该展示错误通知。

### `ClipboardService`

职责：

1. 将成功截图文件写入 `NSPasteboard`。
2. PNG/JPG 使用 `NSImage` 写入 TIFF 或文件 URL。
3. PDF 可先写文件 URL，MVP 不做复杂转换。

### `NotificationService`

职责：

1. 首次启动请求通知权限。
2. 截图成功后通知用户。
3. 通知内容包含文件名。

MVP 即使通知权限被拒绝，也不阻断截图流程。

### `MenuBarContent`

菜单项建议：

1. `Capture Full Screen`
2. `Capture Selected Area`
3. `Settings...`
4. `Quit`

截图动作执行期间：

1. 禁用截图菜单项或显示 `Capturing...`。
2. 避免重复触发多个 `screencapture` 进程。

### `SettingsView`

最小设置：

1. 保存目录选择器。
2. 格式选择器：PNG/JPG/PDF。
3. 复制到剪贴板开关。
4. 截图后在 Finder 中显示开关。

---

## 4. 实现顺序

### 阶段 1: 建立可运行应用骨架

1. 创建 `Package.swift`。
2. 创建 `@main` SwiftUI app。
3. 添加 `MenuBarExtra`，包含基础菜单项和退出功能。
4. 确认 `swift build` 能通过。

验收：

1. `swift build` 成功。
2. `swift run MacScreenshotTool` 后菜单栏出现入口。
3. 菜单里 `Quit` 可退出应用。

### 阶段 2: 实现文件截图

1. 实现 `FileService` 自动生成输出路径。
2. 实现 `ScreenshotEngine`。
3. 接入全屏截图菜单项。
4. 接入交互式区域截图菜单项。
5. 处理取消截图。

验收：

1. 全屏截图生成文件到桌面。
2. 区域截图生成文件到桌面。
3. 区域截图按 ESC 取消时不产生错误弹窗，也不留下空文件。

### 阶段 3: 设置与持久化

1. 实现 `AppSettings`。
2. 实现 `SettingsView`。
3. 支持选择保存目录。
4. 支持选择输出格式。
5. 支持设置是否复制到剪贴板、是否 Finder 定位。

验收：

1. 退出重启后设置仍保留。
2. 改保存目录后截图写入新目录。
3. 改格式后输出扩展名和 `screencapture -t` 参数一致。

### 阶段 4: 完成体验闭环

1. 实现 `ClipboardService`。
2. 实现 `NotificationService`。
3. 截图成功后按设置复制到剪贴板。
4. 截图成功后按设置 Finder 定位。
5. 补充 README 运行说明。

验收：

1. 开启复制后，截图完成可直接粘贴到支持图片的应用。
2. 开启 Finder 定位后，截图完成自动选中新文件。
3. 通知权限拒绝不影响截图。

---

## 5. 命令与验证

### 构建

```bash
swift build
```

### 运行

```bash
swift run MacScreenshotTool
```

### 手动验证截图权限

```bash
/usr/sbin/screencapture -x -m ~/Desktop/mvp-fullscreen-test.png
/usr/sbin/screencapture -x -i -s ~/Desktop/mvp-region-test.png
```

### 建议最终检查

1. `swift build`
2. 启动应用，确认菜单栏出现。
3. 执行全屏截图。
4. 执行区域截图。
5. ESC 取消区域截图。
6. 修改保存目录后再次截图。
7. 修改格式为 JPG 后截图。
8. 开启复制到剪贴板后截图并粘贴验证。

---

## 6. 关键实现注意事项

1. 不要把 `screencapture` 放到主线程同步等待；使用 async 包装，避免 UI 卡死。
2. `Process` 的 `executableURL` 使用绝对路径 `/usr/sbin/screencapture`。
3. 参数数组不要手动拼接成 shell 字符串，避免路径空格问题。
4. 保存目录 URL 持久化时保存 bookmark data 或 path；MVP 非沙盒模式可先用 path。
5. 默认关闭沙盒，降低文件访问复杂度。
6. `MenuBarExtra` 要设置合理的 `LSUIElement`，避免 Dock 图标干扰菜单栏应用体验。
7. 用户取消交互截图是正常路径，不要作为失败通知。

---

## 7. Hermes 下一步实现任务

建议 Hermes 从阶段 1 和阶段 2 开始：

1. 在 `/Users/lvshizou/mac-screenshot-tool` 创建 SwiftPM 应用骨架。
2. 实现 `MenuBarExtra` 菜单栏入口。
3. 实现 `FileService` 和 `ScreenshotEngine`。
4. 接通全屏截图与交互式区域截图。
5. 先跑通 `swift build`，再用 `swift run MacScreenshotTool` 手动验证。

阶段 3、阶段 4 可以在基础截图闭环稳定后继续补齐。
