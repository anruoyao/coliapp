# Chatter — ColibriPlus Flutter 客户端

> 基于 Flutter 的社交 App 客户端，接入 [ColibriPlus](https://github.com/anruoyao/coli) 后端，支持双时间线、故事、即时通讯、翻译与多语言。

## 功能概览

### 信息流
- 关注 / 推荐双时间线切换，置顶帖与骨架屏加载
- 帖子卡片：图文 / 视频、点赞与表情回应、评论、书签、分享
- 故事条与故事查看器，支持发布故事
- 图片查看器、帖子详情与翻译（帖子 / 个人简介）

### 社交
- 个人主页、关注 / 粉丝列表、关注请求审批
- 隐私信息展示、拉黑 / 静音、黑名单管理
- 全局搜索、通知中心、访客态浏览

### 即时通讯
- 会话列表、单聊 / 群聊、文本与图片消息
- 已读回执、未读红点、消息删除
- 基于 Laravel Reverb（Pusher 协议）的 WebSocket 实时消息
- 断线自动重连、心跳保活、订阅恢复与本地系统通知

### 其他
- 22+ 语言本地化、Firebase Messaging、深链
- 版本检测、强制更新、维护模式与账号封禁提示

## 技术栈

| 模块 | 技术 |
| --- | --- |
| 框架 | Flutter / Dart |
| 状态与路由 | GetX |
| 本地存储 | GetStorage |
| 实时通信 | web_socket_channel（Laravel Reverb / Pusher 协议） |
| 推送与通知 | Firebase Messaging、flutter_local_notifications |
| 媒体 | cached_network_image、video_player、photo_view |
| 其他 | app_links、share_plus、permission_handler |

## 运行

环境要求：Flutter SDK（Dart 3.5+）、Android SDK。

```bash
flutter pub get
flutter run
```

构建 release APK：

```bash
flutter build apk --release
```

产物路径：`build/app/outputs/flutter-apk/app-release.apk`。

后端地址、API 与 WebSocket 地址在 `lib/utilities/const.dart` 中配置，部署到自己的域名时需要同步修改。

## 目录结构

```text
lib/screens/colibri_feed/        信息流、帖子卡片、故事、发布器、评论
lib/screens/colibri_chat/        会话列表与聊天详情
lib/screens/colibri_social/      个人主页、通知、搜索、书签、拉黑 / 静音
lib/screens/colibri_settings/    设置中心
lib/common/api_service/          后端 API 封装
lib/common/managers/             WebSocket、本地通知、未读状态、版本检查
lib/localization/languages/      22+ 语言文案
```

## 后端

服务端仓库：[anruoyao/coli](https://github.com/anruoyao/coli)

需要先部署 ColibriPlus 后端，并在 `lib/utilities/const.dart` 中填写对应的 API / WebSocket 地址。

## AI 辅助开发说明

本项目以 vibe coding 方式开发。作者负责产品需求拆解、界面与交互验收、测试和发布，具体代码在 Claude Code / Trae 辅助下生成并持续迭代。作者并非专业软件工程师，仓库用于学习与作品展示。

## 模板说明

客户端在 Chatter Flutter 社交模板基础上二次开发，接入自建 ColibriPlus 后端；原始模板版权归 RetryTech 所有。

## 相关仓库

- 客户端：[anruoyao/coliapp](https://github.com/anruoyao/coliapp)
- 后端：[anruoyao/coli](https://github.com/anruoyao/coli)
