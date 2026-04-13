# SimpleBili 开发文档

> 基于 Flutter 的哔哩哔哩第三方客户端，支持 Windows / Android 双平台。

---

## 目录

1. [技术栈](#1-技术栈)
2. [项目结构总览](#2-项目结构总览)
3. [核心层 (core/)](#3-核心层-core)
4. [功能模块 (features/)](#4-功能模块-features)
   - 4.1 [auth — 认证/登录](#41-auth--认证登录)
   - 4.2 [feed — 动态推荐流](#42-feed--动态推荐流)
   - 4.3 [search — 搜索](#43-search--搜索)
   - 4.4 [player — 视频播放器](#44-player--视频播放器)
   - 4.5 [favorite — 收藏夹](#45-favorite--收藏夹)
   - 4.6 [up — UP 主空间](#46-up--up-主空间)
5. [共享组件 (shared/)](#5-共享组件-shared)
6. [平台配置](#6-平台配置)
7. [数据流架构](#7-数据流架构)
8. [B 站 API 接口一览](#8-b-站-api-接口一览)
9. [安全机制](#9-安全机制)
10. [构建与发布](#10-构建与发布)

---

## 1 技术栈

| 类别 | 库 | 用途 |
|---|---|---|
| 框架 | Flutter 3.x | UI / 跨平台 |
| 状态管理 | flutter_riverpod ^2.4.9 | 全局状态 / DI |
| 路由 | go_router ^17.1.0 | 声明式路由 + 守卫 |
| 网络 | dio ^5.9.2 | HTTP 客户端 / 拦截器 |
| 本地存储 | shared_preferences ^2.5.4 | Cookie / 配置持久化 |
| 视频播放 | media_kit ^1.2.6 + media_kit_video | 硬件加速视频 |
| 加密 | encrypt ^5.0.3 + pointycastle | RSA 密码加密 |
| 哈希 | crypto ^3.0.7 | MD5 / WBI 签名 |
| WebView | flutter_inappwebview ^6.1.5 | 极验验证码 |
| 二维码 | qr_flutter ^4.1.0 | 扫码登录展示 |
| 文件选择 | file_picker ^10.3.10 | 通用文件访问 |

---

## 2 项目结构总览

```
SimpleBili/
├── lib/
│   ├── main.dart                  # 应用入口
│   ├── core/                      # 核心基础设施
│   │   ├── bili_client.dart       # HTTP 客户端 + Cookie 管理
│   │   ├── router.dart            # 路由配置与鉴权守卫
│   │   ├── wbi_sign.dart          # WBI 请求签名算法
│   │   └── rsa_utils.dart         # RSA 密码加密工具
│   ├── features/                  # 业务功能模块
│   │   ├── auth/                  # 登录认证
│   │   ├── feed/                  # 推荐流
│   │   ├── search/                # 搜索
│   │   ├── player/                # 视频播放器
│   │   ├── favorite/              # 收藏夹
│   │   └── up/                    # UP 主空间
│   └── shared/                    # 跨模块共享组件
│       ├── app_theme.dart         # 全局主题
│       ├── video_card.dart        # 视频卡片组件
│       ├── dynamic_card.dart      # 动态卡片组件
│       └── image_cache_manager.dart # LRU 图片缓存
├── android/                       # Android 平台配置
├── windows/                       # Windows 平台配置
├── pubspec.yaml                   # 依赖声明
└── DEVELOPMENT.md                 # 本文件
```

每个 `features/` 子目录均遵循三层结构：

```
<feature>/
├── <feature>_service.dart    # 数据层：直接调用 B 站 API
├── <feature>_provider.dart   # 状态层：Riverpod Notifier + State
└── <feature>_page.dart       # UI 层：ConsumerWidget / ConsumerStatefulWidget
```

---

## 3 核心层 (core/)

### 3.1 `main.dart` — 应用入口

```
WidgetsFlutterBinding.ensureInitialized()
MediaKit.ensureInitialized()
runApp(ProviderScope(child: SimpleBiApp()))
```

- 初始化 Flutter 绑定和 media_kit 视频引擎。
- 用 `ProviderScope` 包裹整个应用，激活 Riverpod 全局容器。
- 固定使用深色主题（`AppTheme.darkTheme`），强制 `ThemeMode.dark`。

---

### 3.2 `core/bili_client.dart` — HTTP 客户端

**职责**：所有 B 站 API 请求的统一入口，管理 Cookie 生命周期。

#### Provider

```dart
final biliClientProvider = Provider<BiliClient>((ref) => BiliClient());
```

#### 类成员

| 成员 | 类型 | 说明 |
|---|---|---|
| `_dio` | `Dio` | 配置好 BaseURL / Header 的 Dio 实例 |
| `_cookie` | `String` | 当前完整 Cookie 字符串 |
| `_refreshToken` | `String?` | B 站 refresh_token，用于 Cookie 续期 |
| `_isInitialized` | `bool` | 是否已从 SharedPreferences 加载 |
| `_isRefreshing` | `bool` | 防止 refresh 并发的标志位 |
| `wbiImgKey` | `String?` | WBI 签名所需 img_key |
| `wbiSubKey` | `String?` | WBI 签名所需 sub_key |

#### 公开 API

| 方法 | 签名 | 说明 |
|---|---|---|
| `init` | `Future<void>` | 从 SharedPreferences 加载 Cookie 和 refresh_token，首次调用后幂等 |
| `saveCookie` | `Future<void> saveCookie(String cookie)` | 持久化新 Cookie |
| `saveRefreshToken` | `Future<void> saveRefreshToken(String token)` | 持久化 refresh_token |
| `clearCookie` | `Future<void>` | 清除本地全部登录信息（登出） |
| `checkCookieValid` | `Future<bool>` | 调用 `/x/web-interface/nav` 验证登录态，失败时尝试 refresh |
| `fetchWbiKeys` | `Future<void>` | 调用 `/x/web-interface/nav` 提取 WBI img/sub key |
| `dio` | `Dio` getter | 外部直接引用 Dio 实例发起请求 |
| `cookie` | `String` getter | 获取当前 Cookie 字符串 |

#### 拦截器行为

1. **onRequest**：自动在请求 Header 注入 `Cookie`，首次请求触发 `init()`。
2. **onResponse**：
   - 自动解析 `set-cookie` 响应头，合并更新本地 Cookie（`_mergeCookies`）。
   - 检测到 B 站返回 `code: -101`（未登录）且有 refresh_token 时，自动调用 `_tryRefreshCookie()` 并重试原请求。

#### 私有方法

| 方法 | 说明 |
|---|---|
| `_generateBuvid()` | 生成符合 B 站格式的设备指纹（buvid3/buvid4） |
| `_ensureBuvidCookies()` | 若 Cookie 缺少 buvid3/buvid4/b_nut 则自动补全 |
| `_parseCookieMap()` | 将 Cookie 字符串解析为 `Map<String, String>` |
| `_mergeCookies(List<String>)` | 将 set-cookie 头合并进本地 Cookie |
| `_tryRefreshCookie()` | 调用 `POST /x/passport-login/web/cookie/refresh` 刷新 Cookie |

---

### 3.3 `core/router.dart` — 路由配置

**职责**：声明全部路由及登录守卫（未登录重定向至 `/login`）。

#### Provider

```dart
final routerProvider = Provider<GoRouter>((ref) { ... });
```

#### 路由表

| 路径 | 页面 | 参数 | 是否需要登录 |
|---|---|---|---|
| `/login` | `LoginPage` | — | 否 |
| `/` | `FeedPage` | — | 是 |
| `/search` | `SearchPage` | — | 是 |
| `/player/:bvid` | `PlayerPage` | `bvid`（视频 BV 号） | 是 |
| `/up/:mid` | `UpSpacePage` | `mid`（用户 UID） | 是 |
| `/favorite` | `FavoritePage` | — | 是 |
| `/favorite/:mediaId` | `FavoriteDetailPage` | `mediaId`（收藏夹 ID） | 是 |

#### 守卫逻辑

```
未认证 → 非 /login 页面 → 跳转 /login
已认证 → 访问 /login → 跳转 /
```

`RouterRefreshNotifier` 监听 `authProvider` stream，认证状态变化时自动触发路由重新计算。

---

### 3.4 `core/wbi_sign.dart` — WBI 签名

**职责**：对部分需要鉴权的 B 站 API 参数进行签名，防止接口爬取。

#### 算法流程

```
1. imgKey + subKey 拼接，按 mixinKeyEncTab 乱序提取前 32 位 → mixinKey
2. 在参数中追加 wts（当前 Unix 时间戳秒）
3. 对参数 key 排序，拼装 URL 查询字符串（过滤特殊字符 !'()*）
4. MD5(queryString + mixinKey) → w_rid
5. 返回带 wts 和 w_rid 的完整参数 Map
```

#### 公开 API

| 方法 | 签名 | 说明 |
|---|---|---|
| `getMixinKey` | `static String getMixinKey(String imgKey, String subKey)` | 生成混淆密钥 |
| `sign` | `static Map<String, dynamic> sign(Map params, String imgKey, String subKey)` | 对请求参数签名，返回含 `w_rid` 和 `wts` 的新 Map |

---

### 3.5 `core/rsa_utils.dart` — RSA 加密

**职责**：对密码登录时的密码进行 RSA-PKCS1 公钥加密。

#### 公开 API

| 方法 | 签名 | 说明 |
|---|---|---|
| `encryptPassword` | `static String encryptPassword(String password, String publicKeyPem, String hash)` | 返回 Base64 编码的密文；加密内容为 `hash + password` |

---

## 4 功能模块 (features/)

### 4.1 auth — 认证/登录

#### 文件一览

| 文件 | 说明 |
|---|---|
| `auth_provider.dart` | 认证状态机（AuthNotifier + AuthState） |
| `auth_service.dart` | 登录相关 API 封装 |
| `login_page.dart` | 登录 UI（短信/Cookie/扫码） |
| `geetest_captcha_page.dart` | 极验验证码 WebView 页面 |

---

#### `auth_provider.dart`

##### `AuthStatus` 枚举

| 值 | 含义 |
|---|---|
| `initial` | 启动中，尚未检查本地登录态 |
| `unauthenticated` | 未登录 |
| `loading` | 正在加载（二维码/验证码获取中） |
| `waitingScan` | 二维码已生成，等待扫码 |
| `waitingConfirm` | 已扫码，等待手机端确认 |
| `sendingSms` | 短信验证码发送中 |
| `loggingIn` | 正在提交登录请求 |
| `authenticated` | 已登录 |
| `qrcodeExpired` | 二维码已过期 |
| `error` | 出错 |

##### `LoginMethod` 枚举

`qrcode` / `cookie` / `password` / `sms`

##### `AuthState` 字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `status` | `AuthStatus` | 当前状态 |
| `loginMethod` | `LoginMethod` | 当前选择的登录方式 |
| `qrcodeUrl` | `String?` | 扫码登录二维码 URL |
| `errorMessage` | `String?` | 错误信息 |
| `captchaKey` | `String?` | 短信发送后服务器返回的 captcha_key |
| `smsCountdown` | `int` | 重新发送短信倒计时（秒） |
| `phone` | `String` | 当前输入的手机号 |

##### `AuthNotifier` 公开方法

| 方法 | 说明 |
|---|---|
| `setLoginMethod(LoginMethod)` | 切换登录方式，重置状态 |
| `setPhone(String)` | 更新手机号 |
| `startQrLogin()` | 获取二维码并开始轮询（每 3 秒） |
| `loginWithCookie({sessdata, biliJct, dedeUserId})` | Cookie 直接登录 |
| `loginWithPassword({phone, password, captchaToken, challenge, validate, seccode})` | 密码登录（含 RSA 加密） |
| `sendSmsCode({phone, captchaToken, challenge, validate, seccode})` | 发送短信验证码，成功后启动 60 秒倒计时 |
| `loginWithSms({phone, code})` | 短信验证码登录 |
| `prepareCaptchaForUi()` | 获取极验验证码初始化参数（返回 token/gt/challenge） |
| `logout()` | 清除登录态，取消所有定时器 |

---

#### `auth_service.dart`

##### Provider

```dart
final authServiceProvider = Provider<AuthService>((ref) { ... });
```

##### 公开方法

| 方法 | 返回 | B 站 API | 说明 |
|---|---|---|---|
| `getQrcode()` | `Future<Map>` | `GET /x/passport-login/web/qrcode/generate` | 返回 `{url, qrcode_key}` |
| `pollQrcode(String qrcodeKey)` | `Future<Map>` | `GET /x/passport-login/web/qrcode/poll` | 返回 `{code, message}`，code 含义详见 §8 |
| `queryCaptcha()` | `Future<Map>` | `GET /x/passport-login/captcha?source=main_web` | 返回极验参数 `{status, data:{token, geetest:{gt, challenge}}}` |
| `getWebKey()` | `Future<Map>` | `GET /x/passport-login/web/key` | 返回 RSA `{hash, key}` |
| `encryptPassword({hash, publicKeyPem, password})` | `String` | — | RSA-PKCS1 加密，返回 Base64 |
| `loginByWebPassword({username, encryptedPassword, token, challenge, validate, seccode})` | `Future<Map>` | `POST /x/passport-login/web/login` | 密码登录 |
| `sendWebSmsCode({tel, token, challenge, validate, seccode, cid})` | `Future<Map>` | `POST /x/passport-login/web/sms/send` | 发送短信，成功返回 `{status, data:{captcha_key}}` |
| `loginByWebSmsCode({tel, code, captchaKey, cid})` | `Future<Map>` | `POST /x/passport-login/web/login/sms` | 短信验证码登录 |

---

#### `geetest_captcha_page.dart`

展示包含极验 GT3 SDK 的 WebView 页面，通过 JavaScript Bridge 将验证结果回传 Flutter。

**构造参数**：`gt`（极验 id）、`challenge`（本次挑战 token）

**返回值**：`GeetestResult`

```dart
class GeetestResult {
  final String validate;   // geetest_validate
  final String seccode;    // geetest_seccode
  final String challenge;  // geetest_challenge
}
```

**关键实现细节**：
- 动态通过 JS 加载 `gt.js`（避免 `initialData` 下脚本时序问题）
- 显式传入 `protocol: "https://"` + `api_server: "api.geetest.com"`，解决 WebView `about:blank` 环境下协议解析失败的问题
- 15 秒超时兜底，防止用户无限等待

---

### 4.2 feed — 动态推荐流

#### `feed_service.dart`

| 方法 | 返回 | B 站 API | 参数 |
|---|---|---|---|
| `getVideoFeed({offset})` | `Future<Map>` | `GET /x/polymer/web-dynamic/v1/feed/all` | `type=video` `offset` `timezone_offset=-480` |

返回结构：`{items: [...], offset: String, has_more: bool}`

#### `feed_provider.dart`

##### `FeedState`

| 字段 | 类型 | 说明 |
|---|---|---|
| `isLoading` | `bool` | 加载中 |
| `error` | `String?` | 错误信息 |
| `items` | `List<dynamic>` | 动态列表数据 |
| `offset` | `String` | 下一页游标 |
| `hasMore` | `bool` | 是否有更多 |

##### `FeedNotifier` 方法

| 方法 | 说明 |
|---|---|
| `refresh()` | 清空并重新加载第一页 |
| `fetchMore()` | 追加加载下一页（使用 offset） |

```dart
final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) { ... });
```

---

### 4.3 search — 搜索

#### `search_service.dart`

| 方法 | 返回 | B 站 API | 说明 |
|---|---|---|---|
| `searchVideo(String keyword, int page)` | `Future<Map>` | `GET /x/web-interface/wbi/search/type` | 需要 WBI 签名，参数：`keyword, search_type=video, page` |

返回结构：`{result: [...], numPages: int, ...}`

#### `search_provider.dart`

##### `SearchState`

| 字段 | 类型 | 说明 |
|---|---|---|
| `isLoading` | `bool` | 加载中 |
| `error` | `String?` | 错误信息 |
| `items` | `List<dynamic>` | 搜索结果列表 |
| `page` | `int` | 当前页码 |
| `hasMore` | `bool` | 是否有更多结果 |
| `keyword` | `String` | 当前搜索关键词 |

##### `SearchNotifier` 方法

| 方法 | 说明 |
|---|---|
| `search(String keyword)` | 重置状态，发起第一页搜索 |
| `fetchMore()` | 加载下一页结果 |

```dart
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) { ... });
```

---

### 4.4 player — 视频播放器

#### `video_service.dart`

| 方法 | 返回 | B 站 API | 说明 |
|---|---|---|---|
| `getVideoInfo(String bvid)` | `Future<Map>` | `GET /x/web-interface/view` | 视频基本信息，含 cid、分 P 列表、合集信息 |
| `getPlayUrl(String bvid, int cid, {int qn})` | `Future<Map>` | `GET /x/player/wbi/playurl` | DASH 流地址，需 WBI 签名；fnval=4048 支持 DASH+HDR+4K+杜比 |
| `getCurrentUserMid()` | `Future<int?>` | `GET /x/web-interface/nav` | 获取当前登录用户的 mid |
| `getFavoriteFolders(int mid)` | `Future<List<Map>>` | `GET /x/v3/fav/folder/created/list-all` | 获取用户全部收藏夹 |
| `addToFavorite({int aid, List<int> folderIds})` | `Future<void>` | `POST /x/v3/fav/resource/deal` | 收藏视频，需要 Cookie 中的 `bili_jct` 作为 csrf |

**`fnval` 位掩码说明**（当前使用 `4048`）：

| 位 | 值 | 功能 |
|---|---|---|
| DASH | 16 | DASH 格式（音视频分离流） |
| HDR | 64 | HDR 真彩 |
| 4K | 128 | 4K 超清 |
| Dolby Audio | 256 | 杜比全景声 |
| Dolby Vision | 512 | 杜比视界 |
| 8K | 1024 | 8K 超高清 |
| AV1 | 2048 | AV1 编码 |

4048 = 16 + 64 + 128 + 256 + 512 + 1024 + 2048（启用全部高质量选项）

#### `player_provider.dart`

##### `VideoPlayerState`

| 字段 | 类型 | 说明 |
|---|---|---|
| `isLoading` | `bool` | 加载中 |
| `error` | `String?` | 错误信息 |
| `videoInfo` | `Map?` | 视频基本信息（title、desc、owner、stat 等） |
| `playUrlInfo` | `Map?` | 播放地址信息（含 DASH dash.video / dash.audio 列表） |
| `speed` | `double` | 播放速度（默认 1.0） |
| `currentQuality` | `int` | 当前画质 qn 值（默认 80 = 1080P） |
| `availableQualities` | `List<Map>` | 可选画质列表（从 DASH 响应提取） |
| `isFavoriting` | `bool` | 收藏操作进行中 |
| `currentCid` | `int?` | 当前播放的分 P cid |
| `pages` | `List<Map>` (getter) | 分 P 列表（来自 videoInfo.pages） |
| `ugcSeason` | `Map?` (getter) | 合集信息（来自 videoInfo.ugc_season） |
| `hasMultiPages` | `bool` (getter) | 是否多分 P |
| `hasUgcSeason` | `bool` (getter) | 是否属于合集 |

##### `PlayerNotifier` 方法

| 方法 | 说明 |
|---|---|
| `loadVideo({int? cid})` | 加载视频信息和播放地址，自动提取可用画质 |
| `switchPage(int cid)` | 切换分 P，重新拉取播放地址 |
| `changeQuality(int qn)` | 切换画质，重新拉取播放地址 |
| `setSpeed(double speed)` | 设置播放速度（本地状态，由 UI 传递给 media_kit） |
| `addToFavorite({int aid, List<int> folderIds})` | 收藏视频，完成后刷新 videoInfo |

##### 画质 qn 对应表

| qn | 说明 |
|---|---|
| 127 | 8K 超高清 |
| 126 | 杜比视界 |
| 125 | HDR 真彩 |
| 120 | 4K 超清 |
| 116 | 1080P 60FPS |
| 112 | 1080P 高码率 |
| 80 | 1080P |
| 74 | 720P 60FPS |
| 64 | 720P |
| 32 | 480P |
| 16 | 360P |

```dart
// playerProvider 为 family，按 bvid 分离实例
final playerProvider = StateNotifierProvider.family<PlayerNotifier, VideoPlayerState, String>(...);
```

---

### 4.5 favorite — 收藏夹

#### `favorite_service.dart`

| 方法 | 返回 | B 站 API | 说明 |
|---|---|---|---|
| `getFavoriteList()` | `Future<List>` | `GET /x/web-interface/nav` + `GET /x/v3/fav/folder/created/list-all` | 先获取自身 mid，再获取全部收藏夹列表 |
| `getFavoriteVideos(int mediaId, {int page, int pageSize})` | `Future<Map>` | `GET /x/v3/fav/resource/list` | 获取指定收藏夹内的视频，支持分页 |

#### `favorite_provider.dart`

提供两个独立 Provider：

**`favoriteListProvider`** — 收藏夹列表

| 状态字段 | 类型 | 说明 |
|---|---|---|
| `isLoading` | `bool` | 加载中 |
| `error` | `String?` | 错误信息 |
| `folders` | `List` | 收藏夹列表（含 id、title、media_count 等） |

方法：`load()` — 加载全部收藏夹。

**`favoriteDetailProvider`** — 收藏夹内视频（family，按 mediaId）

| 状态字段 | 类型 | 说明 |
|---|---|---|
| `isLoading` | `bool` | 加载中 |
| `error` | `String?` | 错误信息 |
| `videos` | `List` | 当前页视频列表 |
| `page` | `int` | 当前页码 |
| `hasMore` | `bool` | 是否有更多 |
| `info` | `Map?` | 收藏夹基本信息 |

方法：`load()` / `fetchMore()` — 首次加载和追加分页。

---

### 4.6 up — UP 主空间

#### `up_service.dart`

| 方法 | 返回 | B 站 API | 说明 |
|---|---|---|---|
| `getUpInfo(String mid)` | `Future<Map>` | `GET /x/space/wbi/acc/info` | UP 主基本信息，需 WBI 签名（name、face、sign、fans 等） |
| `getUpStat(String mid)` | `Future<Map>` | `GET /x/space/upstat` | UP 主数据统计（视频播放量、文章阅读量等） |
| `getUpVideos(String mid, {int page, int pageSize})` | `Future<List>` | `GET /x/space/wbi/arc/search` | 按发布时间排序的投稿列表，需 WBI 签名 |

#### `up_provider.dart`

##### `UpSpaceState`

| 字段 | 类型 | 说明 |
|---|---|---|
| `isLoading` | `bool` | 加载中 |
| `error` | `String?` | 错误信息 |
| `info` | `Map?` | UP 主个人信息 |
| `stat` | `Map?` | UP 主数据统计 |
| `videos` | `List` | 投稿视频列表 |
| `page` | `int` | 当前页码 |
| `hasMore` | `bool` | 是否有更多投稿 |

##### `UpNotifier` 方法

| 方法 | 说明 |
|---|---|
| `loadData()` | 并行加载 info + stat + 第一页视频 |
| `fetchMoreVideos()` | 追加加载下一页投稿 |

```dart
// upProvider 为 family，按 mid 分离实例
final upProvider = StateNotifierProvider.family<UpNotifier, UpSpaceState, String>(...);
```

---

## 5 共享组件 (shared/)

### 5.1 `app_theme.dart` — 全局主题

| 常量 | 色值 | 说明 |
|---|---|---|
| `bilibiliPink` | `#FB7299` | 主品牌色，用于按钮/高亮 |
| `bilibiliBlue` | `#00AEEC` | 辅助色 |
| `background` | `#0F1012` | 页面背景 |
| `surface` | `#1B1C20` | 卡片背景 |
| `surfaceVariant` | `#26272C` | 输入框/次级容器背景 |

- Windows 平台自动使用 `Microsoft YaHei UI` 字体
- 通过 `AppTheme.darkTheme` 导出完整 `ThemeData`（Material 3）

### 5.2 `video_card.dart` — 视频卡片

通用视频封面+信息卡片，展示封面图、标题、UP 主名称、播放量、弹幕数等。接收来自 feed / search / favorite 的视频数据对象并统一渲染。

### 5.3 `dynamic_card.dart` — 动态卡片

用于 feed 页中展示 B 站动态条目，根据 `type` 字段分别渲染视频动态、文章转发、纯文字等不同样式。

### 5.4 `image_cache_manager.dart` — LRU 图片缓存

**单例**：`ImageCacheManager.instance`

| 成员 | 类型 | 说明 |
|---|---|---|
| `maxCacheBytes` | `int` | 最大缓存上限，默认 50 MB |
| `currentBytes` | `int` getter | 当前已用缓存大小 |

| 方法 | 说明 |
|---|---|
| `get(String url)` | 命中时提升 LRU 顺序，返回 `Uint8List?` |
| `put(String url, Uint8List data)` | 写入缓存，超限时驱逐最旧条目 |
| `remove(String url)` | 移除单条 |
| `clear()` | 清空全部缓存 |
| `fetch(String url)` | 带防重入（pending map）的异步加载：先查缓存，未命中则 Dio 下载并写入 |

请求携带 `Referer: https://www.bilibili.com` 绕过 B 站图片防盗链。

---

## 6 平台配置

### Android (`android/`)

| 文件 | 说明 |
|---|---|
| `app/build.gradle.kts` | 应用级构建配置（minSdk, targetSdk, applicationId） |
| `build.gradle.kts` | 项目级构建配置 |
| `app/src/main/AndroidManifest.xml` | 权限声明（INTERNET 等）、Activity 配置 |

### Windows (`windows/`)

| 文件 | 说明 |
|---|---|
| `CMakeLists.txt` | 顶级 CMake 配置，定义 `BINARY_NAME = SimpleBili` |
| `runner/CMakeLists.txt` | Runner 可执行文件构建规则 |
| `runner/main.cpp` | Win32 入口，创建窗口标题 `SimpleBili`，初始尺寸 1280×720 |
| `runner/Runner.rc` | Windows 资源文件（版本信息、图标、FileDescription/ProductName） |
| `runner/flutter_window.cpp` | Flutter 引擎与 Win32 窗口集成 |
| `flutter/CMakeLists.txt` | Flutter 工具链集成（flutter_assemble 目标） |
| `flutter/generated_plugins.cmake` | 插件 CMake 规则（flutter pub 自动生成，勿手动修改） |

---

## 7 数据流架构

```
UI (ConsumerWidget)
   │ ref.watch(xxxProvider)
   ▼
StateNotifier (XxxNotifier)
   │ 调用 Service 方法
   ▼
Service (XxxService)
   │ 调用 BiliClient.dio
   ▼
BiliClient (Dio + 拦截器)
   │ HTTPS 请求（含 WBI 签名 / Cookie）
   ▼
B 站 API (api.bilibili.com / passport.bilibili.com)
```

**状态管理规则**：
- 所有状态读取使用 `ref.watch`，触发 UI 重建。
- 所有 Notifier 调用使用 `ref.read(...).notifier.method()`，不触发重建。
- family Provider 按资源 ID（bvid / mid / mediaId）隔离实例，页面关闭后自动销毁。

---

## 8 B 站 API 接口一览

### 认证相关

| 接口 | 方法 | 路径 | 是否需要签名 |
|---|---|---|---|
| 获取 RSA 公钥 | GET | `/x/passport-login/web/key` | 否 |
| 获取极验验证码 | GET | `/x/passport-login/captcha` | 否（需 `source=main_web`） |
| 密码登录 | POST | `/x/passport-login/web/login` | 否（form-data） |
| 发送短信验证码 | POST | `/x/passport-login/web/sms/send` | 否（form-data） |
| 短信验证码登录 | POST | `/x/passport-login/web/login/sms` | 否（form-data） |
| 生成扫码二维码 | GET | `/x/passport-login/web/qrcode/generate` | 否 |
| 轮询扫码状态 | GET | `/x/passport-login/web/qrcode/poll` | 否（需 `qrcode_key`） |
| Cookie 刷新 | POST | `/x/passport-login/web/cookie/refresh` | 否（需 `refresh_token`） |

扫码状态码说明：

| code | 含义 |
|---|---|
| 0 | 登录成功 |
| 86101 | 未扫码 |
| 86090 | 已扫码，等待确认 |
| 86038 | 二维码已过期 |

### 用户/导航

| 接口 | 方法 | 路径 | 是否需要签名 |
|---|---|---|---|
| 导航信息（含登录态/WBI keys） | GET | `/x/web-interface/nav` | 否 |

### 视频/播放

| 接口 | 方法 | 路径 | 是否需要签名 |
|---|---|---|---|
| 视频详细信息 | GET | `/x/web-interface/view` | 否（需 `bvid`） |
| 视频播放地址（DASH） | GET | `/x/player/wbi/playurl` | WBI |
| 搜索视频 | GET | `/x/web-interface/wbi/search/type` | WBI |

### 动态

| 接口 | 方法 | 路径 | 是否需要签名 |
|---|---|---|---|
| 推荐动态流 | GET | `/x/polymer/web-dynamic/v1/feed/all` | 否（需 `type=video`） |

### 收藏夹

| 接口 | 方法 | 路径 | 是否需要签名 |
|---|---|---|---|
| 获取用户收藏夹列表 | GET | `/x/v3/fav/folder/created/list-all` | 否（需 `up_mid`） |
| 获取收藏夹内容 | GET | `/x/v3/fav/resource/list` | 否（需 `media_id`） |
| 收藏/取消收藏视频 | POST | `/x/v3/fav/resource/deal` | 否（需 `bili_jct` csrf） |

### UP 主

| 接口 | 方法 | 路径 | 是否需要签名 |
|---|---|---|---|
| UP 主基本信息 | GET | `/x/space/wbi/acc/info` | WBI |
| UP 主数据统计 | GET | `/x/space/upstat` | 否（需 `mid`） |
| UP 主投稿列表 | GET | `/x/space/wbi/arc/search` | WBI |

---

## 9 安全机制

### 9.1 WBI 签名

作用于部分 API（搜索、播放地址、UP 主信息等），防止接口未授权调用。  
签名密钥（imgKey / subKey）从 `/x/web-interface/nav` 响应中的 `data.wbi_img` 动态获取，存储在 `BiliClient` 实例中，每次构建时按需刷新。

### 9.2 RSA 密码加密

密码登录时在客户端使用 B 站提供的 RSA 公钥对 `hash + password` 加密后传输，服务端私钥解密。公钥和 hash 均从 `/x/passport-login/web/key` 实时获取，避免使用硬编码值。

### 9.3 Cookie 管理

- 登录成功后的 Cookie（SESSDATA / bili_jct / DedeUserID 等）持久化在 `SharedPreferences` 中。
- 所有请求通过 Dio 拦截器自动注入 Cookie，并同步合并响应中的 `set-cookie` 更新。
- `bili_jct` 用作 CSRF token，收藏等写操作必须携带。
- 登录失效（-101）时自动尝试 `refresh_token` 续期，无需用户重新登录。

### 9.4 极验验证码

登录（密码/短信）前必须完成极验 GT3 滑块验证，返回 `validate` / `seccode` / `challenge` 后才能继续调用登录接口。验证码运行在独立 WebView 中，使用 `https://www.bilibili.com` 作为 base URL 确保请求协议正确。

---

## 10 构建与发布

### Windows

```bash
# 开发预览
flutter run -d windows

# 生产构建
flutter build windows --release
# 产物：build/windows/x64/runner/Release/SimpleBili.exe
```

### Android APK

```bash
# 按 ABI 分别构建（推荐）
flutter build apk --target-platform android-arm,android-arm64,android-x64 --split-per-abi --release
# 产物：build/app/outputs/flutter-apk/app-arm64-v8a-release.apk 等

# 单一 ABI（例如仅 arm64）
flutter build apk --target-platform android-arm64 --release
```

### Android App Bundle（推荐上传 Play 商店）

```bash
flutter build appbundle --release
# 产物：build/app/outputs/bundle/release/app-release.aab
```

### 版本号修改

在 `pubspec.yaml` 的 `version` 字段修改，格式 `主版本.次版本.补丁版本+构建号`，例如：

```yaml
version: 1.2.0+3
```
