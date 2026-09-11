# iOS 版编译指南（给有 Mac 的同学看）

> 目标是把这个项目编译成一个能在 iPhone 上运行的 App。
> 全程免费，不需要付费开发者账号。

## 一、准备

1. 一台 **Mac**，安装好 **Xcode**（App Store 免费下载，下载时需要登录一个 Apple ID，约 12 GB）。
2. 拿到源码，二选一：
   - 命令行：`git clone https://github.com/Xu-JHDBL/mytempo.git`
   - 或从仓库里下载 `MyTempo/` 文件夹下的 4 个文件：
     - `MyTempoApp.swift`
     - `ContentView.swift`
     - `MetronomeEngine.swift`
     - `Models.swift`

## 二、新建 Xcode 工程

1. 打开 Xcode → 菜单 **File → New → Project…**
2. 模板选 **iOS → App**，点 **Next**
3. 填写：
   - **Product Name**：`MyTempo`
   - **Interface**：`SwiftUI`
   - **Language**：`Swift`
   - 取消勾选 **Include Tests**
4. 选一个保存位置，点 **Create**

## 三、放入源码

1. 在左侧文件导航栏，选中 Xcode 自动生成的 `MyTempoApp.swift` 和 `ContentView.swift`，右键 → **Delete → Move to Trash**（删除自动生成的两个）。
2. 把上面 4 个 `.swift` 文件**拖进** Xcode 左侧导航栏（拖到 MyTempo 项目根下）。
   弹出框里勾选：
   - ✅ **Copy items if needed**
   - ✅ **Add to targets: MyTempo**

## 四、运行

### 方式 A：模拟器（最简单，先看效果）
1. 顶部设备选择器选任意一台 iPhone 模拟器。
2. 点 **▶** 运行。等它编译启动，就能看到节拍器界面了。
   （模拟器不需要任何签名配置。）

### 方式 B：真机（装到自己 iPhone 上）
1. 用数据线把 iPhone 连到 Mac。
2. 顶部设备选择器选你的 iPhone。
3. 左侧选中 `MyTempo` 项目 → 选中 **MyTempo** target → **Signing & Capabilities** 标签。
4. 勾选 **Automatically manage signing**，在 **Team** 里选你自己的 Apple ID（没有就先 Add an Account 登录一个，免费账号即可）。
5. 如果报 bundle identifier 冲突，把 **Bundle Identifier** 改成唯一一点，比如 `com.你的名字.MyTempo`。
6. 点 **▶** 运行。首次在 iPhone 上会提示「未受信任的开发者」：
   到 iPhone **设置 → 通用 → VPN 与设备管理** → 信任你的开发者证书。

## 五、说明

- **免费证书的 App 有效期 7 天**，到期后需重新连电脑运行一次即可续期。长期使用建议上架 App Store 或走 TestFlight。
- 模拟器只能「看」，听不到声音（模拟器没有麦克风/扬声器输出，实际能出声但建议真机测音质和节拍精准度）。

## 常见问题

| 问题 | 解决 |
|------|------|
| 编译报错「No such module ...」 | 确认四个文件都拖进了 target（Add to targets 勾选 MyTempo） |
| 真机提示证书不受信任 | 去 设置→通用→VPN与设备管理 信任证书 |
| 模拟器没声音 | 正常现象，换真机测试 |
