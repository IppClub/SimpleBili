# SimpleBili

基于 Flutter 开发的第三方 Bilibili 跨平台客户端。

告别海量推荐视频、广告和臃肿的页面——SimpleBili 提供一个极简版的 B 站体验，让你专注于自己想看的视频和关注的 UP 主，而不是被推荐算法偷走注意力。

> 支持 **Windows 桌面** 和 **Android 手机**。

---

## 🌟 功能特性

### 🔑 登录认证
- **扫码登录** — 手机 B 站 APP 扫描二维码即可登录
- **Cookie 登录** — 支持手动粘贴 Cookie，适用于浏览器已登录的用户（在网页端按F12，再点击“应用程序”，再在下方找到“Cookie”并点击，找到并点击“https://www.bilibili.com”即可获取所需cookie）
- **Cookie 自动刷新** — 自动捕获服务端 `Set-Cookie` 响应并更新本地存储，保持登录不过期
- **退出确认** — 退出登录前弹窗确认，防止误操作

### 📺 首页动态
- 加载你关注的 UP 主的最新动态
- 视频卡片展示封面、标题、UP 主名称、播放量
- 下拉刷新 / 滚动加载更多

### ▶️ 视频播放
- 基于 [media_kit](https://github.com/media-kit/media-kit) (mpv 内核) 的高性能播放器
- **DASH 格式** — 自动选择最高画质视频流 + 最高音质音频流，画质媲美官方客户端
- **多清晰度切换** — 支持 360P ~ 4K 超清 / HDR / 杜比视界（取决于账号会员等级）
- **倍速播放** — 0.5x ~ 3.0x，长按右半屏（手机）/ 长按右方向键（桌面）快速 3 倍速
- **键盘快捷键**（桌面端）：
  - `空格` 暂停/播放
  - `→` 短按前进 4 秒，长按 3 倍速
  - `←` 短按后退 4 秒
- **手机全屏横屏** — 点击全屏自动切换到横屏沉浸模式，退出恢复竖屏
- **大缓冲区设计** — 32MB 播放器缓冲 + 64MB demuxer 缓冲，倍速播放更流畅

### 🔍 搜索
- 关键词搜索视频
- 搜索结果展示封面、标题、播放量、弹幕数、发布日期（含年份）
- 点击直接进入播放页

### ⭐ 收藏夹
- 查看账号所有收藏夹（名称、封面、视频数量）
- 进入收藏夹浏览视频列表，支持分页加载
- 播放页一键收藏到指定收藏夹

### 👤 UP 主主页
- 查看 UP 主的投稿视频列表
- 从动态卡片、搜索结果、播放页均可跳转

---

## 🏗️ 技术架构

```
lib/
├── main.dart                    # 应用入口、media_kit 初始化
├── core/
│   ├── bili_client.dart          # Dio HTTP 客户端、Cookie 管理、WBI 签名
│   ├── router.dart               # GoRouter 路由配置
│   ├── wbi_sign.dart             # B 站 WBI 接口签名算法
│   └── rsa_utils.dart            # RSA 加密工具
├── features/
│   ├── auth/                     # 登录认证（扫码 / Cookie / Geetest 验证）
│   ├── feed/                     # 首页动态流
│   ├── player/                   # 视频播放器（DASH 解析、倍速、全屏）
│   ├── search/                   # 搜索功能
│   ├── favorite/                 # 收藏夹
│   └── up/                       # UP 主主页
└── shared/
    ├── app_theme.dart            # 全局主题
    ├── video_card.dart           # 通用视频卡片组件
    └── dynamic_card.dart         # 动态卡片组件
```

**核心技术栈：**
| 技术 | 用途 |
|------|------|
| [Flutter](https://flutter.dev) | 跨平台 UI 框架 |
| [Riverpod](https://riverpod.dev) | 状态管理 |
| [Dio](https://pub.dev/packages/dio) | HTTP 网络请求 |
| [media_kit](https://pub.dev/packages/media_kit) | 视频播放 (mpv 内核) |
| [GoRouter](https://pub.dev/packages/go_router) | 声明式路由 |
| [shared_preferences](https://pub.dev/packages/shared_preferences) | 本地持久化存储 |

---

## 🚀 快速开始

### 环境要求

- **Flutter SDK** ≥ 3.11（推荐使用最新 Stable 版本）
- **Dart SDK** ≥ 3.11
- **Android Studio / VS Code**（推荐安装 Flutter 和 Dart 插件）
- **Windows**：Visual Studio 2022 (含 C++ 桌面开发工作负载) — 构建 Windows 版本需要
- **Android**：Android SDK、已连接的 Android 设备或模拟器

### 克隆与运行

```bash
# 1. 克隆项目
git clone https://github.com/hahavguoqu/SimpleBili.git
cd SimpleBili

# 2. 获取依赖
flutter pub get

# 3. 运行（自动检测已连接设备）
flutter run

# 指定平台运行：
flutter run -d windows    # Windows 桌面
flutter run -d <设备ID>   # Android 设备 (用 flutter devices 查看)
```

### 构建 Android APK

```bash
# 构建 Release APK（推荐）
flutter build apk --release

# APK 输出位置：
# build/app/outputs/flutter-apk/app-release.apk
```

将生成的 `app-release.apk` 文件传输到手机安装即可。

> **提示**：安装前需在手机设置中开启「允许安装未知来源应用」。

### 构建 Windows 可执行文件

```bash
flutter build windows --release

# 输出位置：
# build/windows/x64/runner/Release/
```

---

## 📖 使用说明

1. **登录** — 启动后进入登录页，选择「扫码登录」（推荐）或「Cookie 登录」
2. **浏览动态** — 登录后进入首页，展示关注 UP 主的最新动态
3. **搜索视频** — 点击顶部搜索图标，输入关键词搜索
4. **播放视频** — 点击视频卡片进入播放页，自动以最高可用画质播放
5. **切换清晰度** — 播放页底部控制栏点击清晰度标签选择
6. **倍速播放** — 点击倍速标签选择，或长按屏幕右半区域临时 3 倍速
7. **全屏播放** — 点击全屏图标（手机自动横屏）
8. **收藏夹** — 首页 AppBar 点击星标图标进入收藏夹列表
9. **退出登录** — 点击退出按钮，确认后退出

---

## ⚠️ 免责声明

1. **本项目仅供个人学习和技术交流使用，严禁用于任何商业用途。**
2. 本项目不存储、不传播任何视频内容，所有数据均来自 Bilibili 官方公开接口。
3. 本项目与哔哩哔哩（bilibili.com）无任何关联，不代表 Bilibili 官方立场。
4. 使用本项目所产生的一切后果由使用者本人承担，项目作者不承担任何法律责任。
5. **如果本项目侵犯了您的合法权益，请通过 [GitHub Issues](https://github.com/hahavguoqu/SimpleBili/issues) 联系我，我将在确认后第一时间处理（删除相关内容或下架项目）。**
6. 请尊重 Bilibili 的服务条款，合理使用本项目，避免高频请求对服务器造成负担。

---

## 📄 开源协议

本项目仅供学习交流，暂未选择开源许可证。未经作者许可，不得将本项目用于商业目的。
