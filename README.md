<div align="center">
    <img width="200" height="200" style="display: block;" src="art/flat-logo.png">
</div>
<div align="center">
    <img alt="GitHub" src="https://img.shields.io/github/license/netless-io/flat-ios?color=9cf&style=flat-square">
    <img alt="GitHub repo size" src="https://img.shields.io/github/repo-size/netless-io/flat-ios?color=9cf&style=flat-square">
    <br>
    <a target="_blank" href="https://twitter.com/AgoraFlat">
    <img alt="Twitter URL" src="https://img.shields.io/badge/Twitter-AgoraFlat-9cf.svg?logo=twitter&style=flat-square">
    </a>
    <a target="_blank" href="https://github.com/netless-io/flat/issues/926">
        <img alt="Slack URL" src="https://img.shields.io/badge/Slack-AgoraFlat-9cf.svg?logo=slack&style=flat-square">
    </a>
</div>

<div align="center">
    <h1>Agora Flat iOS</h1>
    <p>Project flat is the iOS client of <a href="https://flat.whiteboard.agora.io/en/">Agora Flat</a> open source classroom.</p>
    <p><a href="./README-zh.md">中文</a></p>
    <img src="art/flat-showcase.png">
</div>

# Features

- Open sourced front-end and back-end
  - [X] [Flat Web][flat-web]
  - [X] Flat Desktop ([Windows][flat-homepage] and [macOS][flat-homepage])
  - [X] [Flat Android][flat-android]
  - [X] [Flat iOS][flat-iOS]
  - [X] [Flat Server][flat-server]
- Optimized teaching experience
  - [X] Big class
  - [X] Small class
  - [X] One on one
- Real-time interaction
  - [X] Multifunctional interactive whiteboard
  - [X] Real-time video/audio chat(RTC)
  - [X] Real-time messaging(RTM)
  - [X] Participant hand raising
- Login via
  - [X] Wechat
  - [X] GitHub
- Classroom management
  - [X] Join and create classrooms
  - [X] Support periodic rooms
  - [X] View room history

- [X] Cloud Storage for multi-media courseware
- [X] Screen sharing

# Development

## Requirements

| iOS Deployment Target | Xcode Version | Swift Language Version |
| --------------------- | ------------- | ---------------------- |
| 13.0                  | 14.0          | Swift 5.7                |

### Installation

1. Install [CocoaPods](https://cocoapods.org).
2. Go to the Flat directory in terminal and execute `pod install`.

### Configure Signing

1. Open `Flat.xcworkspace` with Xcode.
2. In Xcode navigate to the [Signing &amp; Capabilities pane](https://developer.apple.com/documentation/xcode/adding_capabilities_to_your_app) of the project editor for the `Flat-DEV` target.
3. Change `Team` to your team.
4. Change `Bundle identifier` to something unique.

### Run

1. In Xcode use the Scheme menu to select the Flat-DEV scheme.
2. Press ⌘R to run the app.

# Disclaimer

You may use Flat for commercial purposes but please note that we do not accept customizational

commercial requirements and deployment supports. Nor do we offer customer supports for commercial

usage. Please head to [Flexible Classroom][Flexible Classroom] for such requirements.

This project is only for learning and communication use, please comply with the laws and

regulations of the host country, do not use it in the field of politics, religion, pornography,

crime, etc., all illegal consequences please bear.

# License

Copyright © Agora Corporation. All rights reserved.

Licensed under the MIT license.

When using the Flat or other GitHub logos, be sure to follow the GitHub logo guidelines.

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
[Flexible Classroom]: https://www.agora.io/en/products/flexible-classroom/
