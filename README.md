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
-   Open sourced front-end and back-end
    -   [x] [Flat Web][flat-web]
    -   [x] Flat Desktop ([Windows][flat-homepage] and [macOS][flat-homepage])
    -   [x] [Flat Android][flat-android]
    -   [x] [Flat Server][flat-server]
-   Optimized teaching experience
    -   [x] Big class
    -   [x] Small class
    -   [x] One on one
-   Real-time interaction
    -   [x] Multifunctional interactive whiteboard
    -   [x] Real-time video/audio chat(RTC)
    -   [x] Real-time messaging(RTM)
    -   [x] Participant hand raising
-   Login via
    -   [x] Wechat
    -   [x] GitHub
    -   [ ] Google
-   Classroom management
    -   [x] Join and create classrooms
    -   [ ] Support periodic rooms
    -   [ ] schedule classrooms
    -   [x] View room history
-   [x] Cloud Storage for multi-media courseware
-   [ ] Screen sharing
# Development

Flat is written entirely in swift.

## Requirements

iOS Deployment Target | Xcode Version | Swift Language Version
------------ | ------------- | -------------
12.0 | 13.0 | Swift 5

### Installation
1. Install [CocoaPods](https://cocoapods.org).
2. Go to the Flat directory in terminal and execute `pod install`.

### Configure Signing
1. Open `Flat.xcworkspace` with Xcode.
2. In Xcode navigate to the [Signing & Capabilities pane](https://developer.apple.com/documentation/xcode/adding_capabilities_to_your_app) of the project editor for the `Flat-DEV` target.
3. Change `Team` to your team.
4. Change `Bundle identifier` to something unique.

### Run
1. In Xcode use the Scheme menu to select the Flat-DEV scheme.

2. Run ⌘R the app.

# Disclaimer

This project is only for learning and communication use, please comply with the laws and 

regulations of the host country, do not use it in the field of politics, religion, pornography, 

crime, etc., all illegal consequences please bear.

# License
Copyright © Agora Corporation. All rights reserved.

Licensed under the MIT license.

When using the Flat or other GitHub logos, be sure to follow the GitHub logo guidelines.