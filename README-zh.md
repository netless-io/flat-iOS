<div align="center">
    <img width="200" height="200" style="display: block;" src="art/flat-logo.png">
</div>

<!-- 
<div align="center">
    <img alt="GitHub" src="https://img.shields.io/github/license/netless-io/flat?color=9cf&style=flat-square">
</div> 
-->

<div align="center">
    <h1>Agora Flat iOS</h1>
    <p>Flat是 <a href="https://flat.whiteboard.agora.io/en/">Agora Flat</a> 开源教室的 iOS 客户端。</p>
    <img src="art/flat-showcase.png">
    <p><a href="./README-zh.md">En</a></p>
</div>

# 特性
-   前后端完全开源
    -   [x] [Flat Web][flat-web]
    -   [x] Flat 桌面端 ([Windows][flat-homepage] and [macOS][flat-homepage])
    -   [x] [Flat Android][flat-android]
    -   [x] [Flat Server 服务器][flat-server]
-   多场景课堂
    -   [x] 大班课
    -   [x] 小班课
    -   [x] 一对一
-   实时交互
    -   [x] 多功能互动白板
    -   [x] 实时音视频（RTC）通讯
    -   [x] 即时消息（RTM）聊天
    -   [x] 举手上麦发言
-   帐户系统
    -   [x] 微信登陆
    -   [x] GitHub 登陆
    -   [ ] 谷歌登陆
-   房间管理
    -   [x] 加入、创建
    -   [ ] 预定房间
    -   [x] 支持周期性房间
    -   [x] 查看历史房间
-   课堂录制回放
    -   [x] 白板信令回放
    -   [x] 音视频云录制回放
    -   [x] 群聊信令回放
-   [x] 多媒体课件云盘
-   [ ] 设备检测
-   [ ] 自动检查更新  
# 开发环境

Flat完全由Swift编写。

## 环境配置

iOS 最低版本 | Xcode版本 | Swift 版本
------------ | ------------- | -------------
12.0 | 13.0 | Swift 5

### 安装
1. 安装 [CocoaPods](https://cocoapods.org)。
2. Run `pod install`.

### 配置签名
1. 用Xcode打开 `Flat.xcworkspace` 。
2. 在Xcode中前往编辑'Flat-DEV'这个Target的 [Signing & Capabilities pane](https://developer.apple.com/documentation/xcode/adding_capabilities_to_your_app) 。
3. 切换到你的 `Team`。
4. 换一个不一样的 `Bundle identifier`。

### 运行
1. 选择Scheme Flat-DEV .
2. 按 ⌘R 启动 app.

[flat-homepage]: https://flat.whiteboard.agora.io/en/#download
[flat-web]: https://flat-web.whiteboard.agora.io/
[flat-server]: https://github.com/netless-io/flat-server
[flat-android]: https://github.com/netless-io/flat-android
[flat-storybook]: https://netless-io.github.io/flat/storybook/
[open-wechat]: https://open.weixin.qq.com/
[netless-auth]: https://docs.agora.io/en/whiteboard/generate_whiteboard_token_at_app_server?platform=RESTful
[agora-app-id-auth]: https://docs.agora.io/en/Agora%20Platform/token#a-name--appidause-an-app-id-for-authentication
[cloud-recording]: https://docs.agora.io/en/cloud-recording/cloud_recording_api_rest?platform=RESTful#storageConfig
[cloud-recording-background]: https://docs.agora.io/en/cloud-recording/cloud_recording_layout?platform=RESTful#background
[electron-updater]: https://github.com/electron-userland/electron-builder/tree/master/packages/electron-updater
