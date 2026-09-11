# MyTempo iOS 版 —— 编译打包说明

> 本说明写给「有 Mac、负责编译」的同学。
> 目标是把这个项目编译成一个能在 iPhone 上运行的 App，全程免费、无需付费开发者账号。

---

## 一、需要打包的文件清单（重点）

编译 App 只需要下面 **4 个 Swift 源码文件**（外加本说明文件）。打包时把这 5 个文件发给同学即可。

```
MyTempo/
├── MyTempoApp.swift        # App 入口（@main）
├── ContentView.swift       # 界面 UI
├── MetronomeEngine.swift   # 核心音频引擎（采样级精准打拍）
└── Models.swift            # 拍号、音色等数据模型
iOS-Build-Guide.md          # 本编译说明（给编译的同学看）
```

| 文件 | 相对路径 | 作用 |
|------|----------|------|
| `MyTempoApp.swift` | `MyTempo/MyTempoApp.swift` | App 入口，`@main` |
| `ContentView.swift` | `MyTempo/ContentView.swift` | 界面 UI（速度/节拍型/音效/灯珠/播放按钮） |
| `MetronomeEngine.swift` | `MyTempo/MetronomeEngine.swift` | 核心：AVAudioEngine 采样级计时 + 声音合成 |
| `Models.swift` | `MyTempo/Models.swift` | 拍号、音色枚举等数据模型 |
| `iOS-Build-Guide.md` | `iOS-Build-Guide.md` | 本说明文件 |

> ⚠️ 4 个 `.swift` 文件**缺一不可**，否则编译会报错。
> 获取方式二选一：
> - `git clone https://github.com/Xu-JHDBL/mytempo.git`（推荐，文件最新最全）
> - 或从仓库手动下载上面 4 个 `.swift` 文件打包。

---

## 二、编译步骤

### 1. 准备

1. 一台 **Mac**，安装 **Xcode**（App Store 免费下载，登录一个 Apple ID，约 12 GB）。
2. 拿到第一节的 4 个源码文件。

### 2. 新建 Xcode 工程

1. 打开 Xcode → 菜单 **File → New → Project…**
2. 模板选 **iOS → App**，点 **Next**
3. 填写：
   - **Product Name**：`MyTempo`
   - **Interface**：`SwiftUI`
   - **Language**：`Swift`
   - 取消勾选 **Include Tests**
4. 选保存位置，点 **Create**

### 3. 放入源码

1. 在左侧导航栏，选中 Xcode 自动生成的 `MyTempoApp.swift` 和 `ContentView.swift`，右键 → **Delete → Move to Trash**。
2. 把 4 个 `.swift` 文件**拖进** Xcode 左侧导航栏（拖到 MyTempo 项目根下）。
   弹出框勾选：
   - ✅ **Copy items if needed**
   - ✅ **Add to targets: MyTempo**

### 4. 运行

**方式 A：模拟器（最简单，先看效果）**
1. 顶部设备选择器选任意一台 iPhone 模拟器。
2. 点 **▶** 运行即可。

**方式 B：真机（装到 iPhone 上）**
1. 数据线连 iPhone 到 Mac。
2. 顶部设备选择器选你的 iPhone。
3. 选中 `MyTempo` 项目 → `MyTempo` target → **Signing & Capabilities**。
4. 勾选 **Automatically manage signing**，**Team** 选自己的 Apple ID（免费账号即可）。
5. 若报 bundle identifier 冲突，把 **Bundle Identifier** 改成唯一的，如 `com.你的名字.MyTempo`。
6. 点 **▶**。首次装机会提示「未受信任的开发者」，去 iPhone **设置 → 通用 → VPN 与设备管理** → 信任证书。

---

## 三、注意事项

- **免费证书的 App 有效期 7 天**，到期重连电脑运行一次即续期；长期使用建议上架 App Store 或走 TestFlight。
- **模拟器听不到声音**（模拟器无扬声器输出，实际能出声但建议真机测音质和节拍精准度）。

---

## 四、常见问题

| 问题 | 解决 |
|------|------|
| 编译报错「No such module / Cannot find type」 | 确认 4 个文件都拖进了 target（Add to targets 勾选 MyTempo），且删除了自动生成的两个同名文件 |
| 真机提示证书不受信任 | 去 设置→通用→VPN与设备管理 信任证书 |
| 模拟器没声音 | 正常现象，换真机测试 |
