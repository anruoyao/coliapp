# Feed 性能优化说明

更新时间：2026-10-31

## 背景

Chatter 的 Feed 在关注和推荐之间横向切换时存在掉帧。此次正式对照使用 Android Profile 模式，在同一台 120 Hz 真机上执行相同的纵向滚动和横向切换流程，并以 `FrameTiming.totalSpan` 和设备实际帧预算评价结果。

## 优化内容

### 已完成的列表项动画修复

此前已移除 Feed 列表项逐项进入动画 `_FeedReveal`，包括每项独立的动画控制器、延迟回调、淡入和位移动画。该改动减少了横向拖动 `TabBarView` 时两个列表同时维护的动画状态。

### 本轮图片解码优化

本轮只调整 Feed 中固定显示边界媒体的图片解码尺寸。

`MyCachedImage` 新增可选的 `resizeToDisplayBounds` 参数。启用后，组件通过 `LayoutBuilder` 获取显示宽度，再乘以设备像素比计算 `memCacheWidth`，让 `CachedNetworkImage` 以接近显示尺寸的宽度解码。

Feed 将该参数传给以下媒体：

- 表情图片；
- GIF；
- 多图网格；
- 视频封面。

需要读取原图尺寸来计算宽高比的自适应单图继续使用原有流程。该参数默认关闭，因此 `ColibriPostCard` 在个人主页、详情、收藏和搜索等其他页面中的复用行为保持原有设置。

相关文件：

- `lib/common/widgets/my_cached_image.dart`
- `lib/screens/colibri_feed/colibri_feed_screen.dart`
- `lib/screens/colibri_feed/colibri_post_card.dart`
- `lib/screens/colibri_feed/colibri_post_media.dart`

## Profile 对照结果

设备刷新率约为 120 Hz，显示帧预算约为 8.33 ms。每组运行三轮，表中为三轮中位数：

| 场景 | 优化前 total P95 | 优化后 total P95 | 变化 | 优化前 Raster P95 | 优化后 Raster P95 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Feed 纵向滚动 | 18.336 ms | 16.214 ms | 下降 11.6% | 12.618 ms | 11.589 ms |
| 关注/推荐横向切换 | 21.979 ms | 18.821 ms | 下降 14.4% | 11.314 ms | 10.538 ms |

超过显示帧预算的中位数帧数：

- 纵向滚动：66 帧降至 62 帧；
- 横向切换：64 帧降至 61 帧。

结果说明图片解码和光栅压力有所下降。横向切换仍未达到 120 Hz 的单帧预算，剩余压力需要通过时间线继续区分列表布局、Markdown 构建和图层合成。

## 验证

定向分析无错误：

```text
flutter analyze --no-pub \
  lib/common/widgets/my_cached_image.dart \
  lib/screens/colibri_feed/colibri_post_card.dart \
  lib/screens/colibri_feed/colibri_feed_screen.dart
```

6 个修改和测量文件通过格式检查，相关业务测试 15 项通过。三轮真实设备 Profile 测试全部通过，测试流程覆盖启动、Feed 加载、四次纵向拖动和四次关注/推荐横向切换。

测试命令：

```bash
cd /home/zyb/code/chatter_flutter/chatter && \
GRADLE_USER_HOME=/tmp/chatter-gradle-home \
flutter drive --profile --no-pub \
  --device-id wkdekzukhutwuwyp \
  --target=integration_test/profile_flow_test.dart \
  --driver=test_driver/integration_test.dart \
  --dart-define=FEED_PERFORMANCE=true \
  --keep-app-running \
  --timeout=240
```

## 后续限制

- 真机的 Profile 测量存在调度和网络缓存波动，因此结论使用三轮中位数。
- 设备为 120 Hz，16.67 ms 传统指标不能代表完整的显示预算；测试仍保留该指标用于参考。
- 当前优化仅改变 Feed 固定边界媒体的内存解码宽度，没有改变服务端图片尺寸或其他页面行为。
- 默认 Flutter 计数器 widget 测试仍然不适用于当前应用启动页，属于既有测试问题。
