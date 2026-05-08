# Mac Screenshot Tool - 调研报告

> 调研日期: 2026-05-07
> macOS 版本: 26.3 (Swift 6.3.1)
> 环境: 无 Xcode, 使用 Swift Package Manager

---

## 1. macOS 原生截图方案对比

| 方案 | API/命令 | 实测状态 | 性能 | 灵活性 | 权限 |
|------|----------|----------|------|--------|------|
| **screencapture 命令行** | `/usr/sbin/screencapture` | 已验证可用 | 快 | 中等 | 屏幕录制 |
| **CGWindowListCreateImage** | CoreGraphics | 可用 | 最快 | 高 | 屏幕录制 |
| **CGDisplayCreateImage** | CoreGraphics | 可用 | 快 | 中 | 屏幕录制 |
| **ScreenCaptureKit** | ScreenCaptureKit.framework | 可用（macOS 12.3+） | 快 | 最高 | 屏幕录制 |
| **Screenshot API + Region** | 系统区域选择器 | 可用 | 快 | 低（系统UI） | 屏幕录制 |

**关键发现：**
- `screencapture` 底层已链接 ScreenCaptureKit，两者性能接近
- `screencapture -R x,y,w,h` 可直接按坐标截取矩形区域，无需交互
- `screencapture -c` 可直接输出到剪贴板
- 实测截图成功：全屏 302KB PNG，500x500 区域 51KB PNG

### 推荐方案
**MVP 使用 `screencapture` 命令行，后续迭代升级到 ScreenCaptureKit。**
理由：系统自带，调用简单，无需额外依赖。MVP 阶段最重要的是验证核心功能。

---

## 2. SwiftUI 菜单栏应用推荐结构

```
ScreenshotApp/
├── ScreenshotApp.swift              # @main + MenuBarExtra 入口
├── Core/
│   ├── ScreenshotEngine.swift       # 截图核心（Process 调用 screencapture）
│   ├── ImageProcessor.swift         # 图片格式转换/压缩
│   └── HotKeyManager.swift          # 快捷键注册（需 Carbon/HotKey 库）
├── Services/
│   ├── FileService.swift            # 文件保存、路径管理、自动命名
│   ├── ClipboardService.swift       # NSPasteboard 操作
│   ├── NotificationService.swift    # 截图完成通知
│   └── SettingsService.swift        # UserDefaults 持久化
├── Models/
│   ├── AppSettings.swift            # @Observable 设置模型
│   └── ScreenshotItem.swift         # 截图历史数据模型
├── Views/
│   ├── MenuBarContent.swift         # 菜单栏主界面
│   ├── SettingsView.swift           # 设置面板
│   └── Components/
│       ├── FormatPicker.swift       # 格式选择
│       └── SavePathPicker.swift     # 保存路径选择
├── Resources/
│   ├── Assets.xcassets              # 图标
│   └── Info.plist                   # 权限声明
└── Extensions/
    └── URL+Extensions.swift
```

**关键设计点：**
- 使用 `MenuBarExtra`（macOS 14+）或 `NSStatusBar` 创建菜单栏入口
- 使用 `@AppStorage` 或 `UserDefaults` 保存用户设置
- 截图完成后通过 `NSWorkspace.shared.selectFile` 自动打开 Finder 预览
- 使用 `NSPasteboard` 实现复制到剪贴板

---

## 3. screencapture 命令完整用法（已实测验证）

### 全屏截图
```bash
screencapture -x -m ~/Desktop/screenshot.png        # 主显示器，无声音
screencapture -x ~/Desktop/full.png                 # 所有显示器
```

### 指定矩形区域（无需交互）
```bash
screencapture -x -R 0,0,1000,800 ~/Desktop/rect.png  # 坐标 x,y,width,height
```

### 交互式区域选择
```bash
screencapture -i -x ~/Desktop/selected.png           # 用户拖拽选择
screencapture -i -s -x ~/Desktop/selected.png        # 仅允许鼠标选择
```

### 窗口截图
```bash
screencapture -i -w -x ~/Desktop/window.png          # 交互式选窗口
screencapture -i -w -o -x ~/Desktop/window.png       # 不带窗口阴影
```

### 剪贴板
```bash
screencapture -x -c -m                               # 全屏到剪贴板
screencapture -x -c -R 0,0,500,500                   # 区域到剪贴板
```

### 延迟截图
```bash
screencapture -x -T 3 ~/Desktop/delayed.png          # 3秒后截图
```

### 格式控制
```bash
screencapture -x -t jpg ~/Desktop/screenshot.jpg     # JPG 格式
screencapture -x -t pdf ~/Desktop/screenshot.pdf     # PDF 格式
```

### 包含光标
```bash
screencapture -x -C -m ~/Desktop/with_cursor.png     # 截图中包含鼠标光标
```

### Swift 调用示例
```swift
import Foundation

enum CaptureMode {
    case fullScreen
    case region(x: Int, y: Int, width: Int, height: Int)
    case interactiveRegion
    case interactiveWindow
    case clipboard
}

class ScreenshotEngine {
    func capture(mode: CaptureMode, outputURL: URL? = nil) async throws -> URL? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        
        var args = ["-x"] // 无声音
        
        switch mode {
        case .fullScreen:
            args.append("-m")
        case .region(let x, let y, let w, let h):
            args.append("-R")
            args.append("\(x),\(y),\(w),\(h)")
        case .interactiveRegion:
            args.append("-i")
            args.append("-s")
        case .interactiveWindow:
            args.append("-i")
            args.append("-w")
        case .clipboard:
            args.append("-c")
            args.append("-m")
        }
        
        if case .clipboard = mode {
            // no file arg
        } else if let url = outputURL {
            args.append(url.path)
        }
        
        process.arguments = args
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw ScreenshotError.captureFailed(process.terminationStatus)
        }
        
        return outputURL
    }
}
```

---

## 4. macOS 权限

| 权限 | Key | 触发时机 | 说明 |
|------|-----|----------|------|
| **Screen Recording** | - | 首次截图时系统弹窗 | 系统自动弹窗，无需手动声明 Info.plist |
| **Accessibility** | NSAppleEventsUsageDescription | 需要控制其他应用窗口时 | 需要声明用途描述 |
| **Files** | - | 保存到非标准目录时 | 沙盒化应用需配置 |

**Info.plist 需要的声明（如果需要辅助功能）：**
```xml
<key>NSAppleEventsUsageDescription</key>
<string>需要辅助功能权限来检测窗口位置和大小</string>
```

**实测发现：** 当前系统已有屏幕录制权限（screencapture 测试通过，exit code 0）。

---

## 5. MVP 项目结构（精简版）

```
~/Projects/ScreenshotTool/
├── Package.swift                    # Swift Package（推荐，无需 Xcode）
├── Sources/ScreenshotTool/
│   ├── main.swift                   # 入口 + MenuBarExtra
│   ├── ScreenshotEngine.swift       # 截图逻辑
│   └── AppSettings.swift            # 设置
└── README.md
```

**MVP 功能优先级：**
1. P0: 菜单栏点击 -> 全屏截图保存到桌面
2. P0: 菜单栏点击 -> 区域截图（系统交互模式）
3. P1: 截图后自动复制剪贴板
4. P1: 设置面板（保存路径、格式、音效开关）
5. P2: 快捷键触发
6. P2: 截图历史列表

---

## 6. 风险清单

| 风险 | 严重程度 | 应对方案 |
|------|----------|----------|
| **MenuBarExtra 需要 macOS 14+** | 高 | 当前系统 macOS 26.3 满足，需确认目标版本 |
| **沙盒化应用限制** | 高 | MVP 建议关闭沙盒，避免文件访问问题 |
| **screencapture -i 交互模式阻塞** | 中 | Process.run() 异步，用户取消时正确处理 exit code != 0 |
| **用户取消截图的处理** | 中 | 用户按 ESC 取消时返回非 0，代码需处理 |
| **多显示器支持** | 低 | `-m` 只截主显示器，`-D N` 指定显示器 |
| **Retina 缩放** | 低 | screencapture 自动处理，输出实际像素尺寸 |
| **文件名冲突** | 低 | 需要自动命名机制（时间戳或递增序号） |
| **无 Xcode 环境** | 中 | 当前系统无 Xcode，可用 `swift build` 构建 SPM 项目 |

---

## 7. 给 Codex 的关键提示

1. 当前 macOS 版本是 26.3，Swift 6.3.1
2. 无 Xcode，使用 Swift Package Manager 构建
3. 使用 `Process` 调用 `screencapture` 而非 CGWindow API
4. 关闭沙盒（`com.apple.security.app-sandbox = false`）
5. 处理用户取消截图的情况（ESC 键）
6. `MenuBarExtra` 需要 macOS 14+（当前系统满足）
