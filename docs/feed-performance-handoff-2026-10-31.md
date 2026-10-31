# Chatter Flutter Feed 性能测量与优化记录

更新时间：2026-10-31

## 1. 任务结论

本轮针对 Android 真机 Profile 数据完成了一项范围明确的优化：Feed 中具有固定显示边界的媒体按显示尺寸限制内存解码宽度。优化覆盖表情、GIF、多图网格和视频封面；需要读取原图尺寸计算宽高比的自适应单图保持原逻辑。

在同一台 120 Hz 真机、同一条自动化操作路径下各运行三轮，优化后中位数如下：

| 场景 | 指标 | 优化前 | 优化后 | 变化 |
| --- | --- | ---: | ---: | ---: |
| Feed 纵向滚动 | total P95 | 18.336 ms | 16.214 ms | 下降 11.6% |
| Feed 纵向滚动 | raster P95 | 12.618 ms | 11.589 ms | 下降 8.2% |
| Feed 纵向滚动 | 超过 120 Hz 帧预算 | 66 | 62 | 减少 4 帧 |
| 关注/推荐横向切换 | total P95 | 21.979 ms | 18.821 ms | 下降 14.4% |
| 关注/推荐横向切换 | raster P95 | 11.314 ms | 10.538 ms | 下降 6.9% |
| 关注/推荐横向切换 | 超过 120 Hz 帧预算 | 64 | 61 | 减少 3 帧 |

设备的显示刷新率约为 120 Hz，单帧预算约为 8.33 ms。优化后两个场景仍有较多帧超过预算，因此图片解码压力得到缓解，但横向切换的全部卡顿来源还包括列表布局、Markdown 构建和图层合成等路径。

## 2. 环境与测量方法

- Flutter：3.47.5
- Dart：3.13.4
- 构建模式：Android Profile
- 设备序列号：`wkdekzukhutwuwyp`
- 设备型号：`2510DRK44C`
- 分辨率：1080 x 2400
- 刷新率：120 Hz
- 应用包名：`com.mishe.chatter`
- 测试文件：`integration_test/profile_flow_test.dart`
- Driver：`test_driver/integration_test.dart`

每轮测试执行以下流程：

1. 启动应用并等待已登录首页；
2. 等待 Feed 骨架加载结束；
3. Feed 纵向拖动 4 次；
4. 在 `TabBarView` 中往返切换关注和推荐 4 次；
5. 分别输出启动、纵向滚动和横向切换的 `FrameTiming`。

帧统计从同一个 `FrameTiming` 对象计算 `buildDuration`、`rasterDuration` 和 `totalSpan`，避免把不同帧的 Build 与 Raster 数值错误配对。测试同时记录设备实际刷新率对应的帧预算，以及传统的 16.67 ms 参考值。

本次优化前的 Profile 数据是在图片优化前采集的三轮对照；代码中此前已经移除了 Feed 列表项的逐项进入动画。优化后使用完全相同的设备和操作路径。

## 3. 三轮 Profile 原始数据

`framesOverDisplayBudget` 使用设备实际的约 8.33 ms 帧预算。

### 优化前

| 轮次 | 启动到首页 | 纵向帧数 | 纵向 Build P95 | 纵向 Raster P95 | 纵向 total P95 | 纵向超预算 | 横向帧数 | 横向 Build P95 | 横向 Raster P95 | 横向 total P95 | 横向超预算 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 565 ms | 92 | 7.073 ms | 12.120 ms | 18.336 ms | 63 | 88 | 8.575 ms | 15.490 ms | 25.251 ms | 66 |
| 2 | 561 ms | 94 | 4.674 ms | 12.731 ms | 19.454 ms | 68 | 84 | 9.969 ms | 11.314 ms | 21.449 ms | 58 |
| 3 | 570 ms | 95 | 5.027 ms | 12.618 ms | 18.161 ms | 66 | 84 | 9.663 ms | 11.078 ms | 21.979 ms | 64 |

### 优化后

| 轮次 | 启动到首页 | 纵向帧数 | 纵向 Build P95 | 纵向 Raster P95 | 纵向 total P95 | 纵向超预算 | 横向帧数 | 横向 Build P95 | 横向 Raster P95 | 横向 total P95 | 横向超预算 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 564 ms | 92 | 4.955 ms | 11.589 ms | 16.214 ms | 62 | 83 | 9.009 ms | 10.538 ms | 18.821 ms | 62 |
| 2 | 568 ms | 95 | 4.695 ms | 12.046 ms | 17.838 ms | 68 | 80 | 8.925 ms | 13.670 ms | 24.249 ms | 59 |
| 3 | 570 ms | 94 | 4.235 ms | 11.484 ms | 14.651 ms | 61 | 84 | 9.388 ms | 10.074 ms | 18.518 ms | 61 |

### 三轮中位数

| 场景 | 启动到首页 | 帧数 | Build P95 | Raster P95 | total P95 | 超过显示帧预算 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 优化前，纵向滚动 | 565 ms | 94 | 5.027 ms | 12.618 ms | 18.336 ms | 66 |
| 优化后，纵向滚动 | 568 ms | 94 | 4.695 ms | 11.589 ms | 16.214 ms | 62 |
| 优化前，横向切换 | 565 ms | 84 | 9.663 ms | 11.314 ms | 21.979 ms | 64 |
| 优化后，横向切换 | 568 ms | 83 | 9.009 ms | 10.538 ms | 18.821 ms | 61 |

启动到首页的 3 ms 中位数变化处于真机运行波动范围内，优化目标集中在 Feed 交互阶段。

## 4. 代码变更

### Feed 固定边界媒体按显示尺寸解码

涉及文件：

- `lib/common/widgets/my_cached_image.dart`
- `lib/screens/colibri_feed/colibri_feed_screen.dart`
- `lib/screens/colibri_feed/colibri_post_card.dart`
- `lib/screens/colibri_feed/colibri_post_media.dart`

`MyCachedImage` 新增 `resizeToDisplayBounds` 参数。启用后使用布局宽度和设备像素比计算 `memCacheWidth`，让缓存图片以接近实际显示尺寸解码，降低大图进入 Feed 时的内存和光栅压力。

Feed 通过 `ColibriPostCard` 传入该参数，覆盖：

- 表情图片；
- GIF；
- 多图网格；
- 视频封面。

自适应单图仍保留原有尺寸读取流程，因为它需要原图尺寸计算显示比例。`resizeToDisplayBounds` 默认关闭，其他复用 `ColibriPostCard` 的页面保持原有行为。

## 5. 验证结果

### 通过

```text
flutter analyze --no-pub \
  lib/common/widgets/my_cached_image.dart \
  lib/screens/colibri_feed/colibri_post_card.dart \
  lib/screens/colibri_feed/colibri_feed_screen.dart

No issues found!
```

```text
dart format --set-exit-if-changed \
  lib/common/widgets/my_cached_image.dart \
  lib/screens/colibri_feed/colibri_post_card.dart \
  lib/screens/colibri_feed/colibri_post_media.dart \
  lib/screens/colibri_feed/colibri_feed_screen.dart \
  integration_test/profile_flow_test.dart \
  test_driver/integration_test.dart

6 files formatted; no changes needed.
```

定向业务测试共 15 项通过：

```text
flutter test --no-pub \
  test/colibri_translation_session_test.dart \
  test/colibri_bottom_sheet_test.dart \
  test/colibri_toast_test.dart
```

三轮优化后的真实设备 Profile 测试均通过，并输出 `FEED_PERFORMANCE_RESULT {state: measured, ...}`。第三轮输出的关键数据为：纵向 `totalP95Ms: 14.651`，横向 `totalP95Ms: 18.518`，测试结果为 `All tests passed!`。

### 已知限制

- 120 Hz 帧预算比传统 60 Hz 的 16.67 ms 更严格；当前 P95 仍高于 8.33 ms。
- 横向切换三轮优化后的 `total P95` 为 18.821、24.249、18.518 ms，设备运行波动仍然明显。
- 本次只验证了已登录 Feed 的自动化路径，没有将图片优化扩展到其他页面。
- 仓库中的默认 `test/widget_test.dart` 仍是 Flutter 计数器样例，期望启动页出现 `0`，属于既有失败，与本次 Feed 变更无关。

## 6. 后续判断

当前数据支持保留这项图片解码优化。它对纵向滚动和横向切换都带来中位数改善，启动耗时没有实质变化，也没有观察到 Feed 功能测试回归。

## 7. RepaintBoundary 实验结论

在已保留的媒体解码优化版本上，对 Feed 置顶帖和普通帖卡片增加 `RepaintBoundary`，仅作用于 Feed 列表。目标是让横向移动和纵向滚动时复用卡片的独立光栅结果。

同一台设备、同一套操作流程连续测量三轮：

| 轮次 | 纵向 total P95 | 纵向 Raster P95 | 横向 total P95 | 横向 Raster P95 |
| --- | ---: | ---: | ---: | ---: |
| 1 | 15.283 ms | 9.989 ms | 23.193 ms | 14.995 ms |
| 2 | 19.614 ms | 12.670 ms | 22.600 ms | 14.773 ms |
| 3 | 16.522 ms | 10.790 ms | 23.580 ms | 13.252 ms |

三轮中位数为纵向 `16.522 ms`、横向 `23.193 ms`。此前已验证版本的中位数为纵向 `16.214 ms`、横向 `18.821 ms`，横向切换没有稳定改善，因此撤回该实验。当前代码不包含 Feed 列表项 `RepaintBoundary`。

若继续处理横向切换卡顿，下一步应使用 DevTools 时间线分别确认 Markdown 富文本构建、多图网格布局、`TabBarView` 两侧列表同时布局和 `LiquidGlassLens`/`BackdropFilter` 合成的占比，每次只改变一个热点并沿用本测试路径复测。
