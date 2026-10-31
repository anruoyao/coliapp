import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// 全局触觉反馈（振动）管理器。
///
/// - 统一收口所有振动调用，受「其他设置 → 振动反馈」开关控制（默认开启，GetStorage 持久化）；
/// - 提供分级触感：选择轻触 [selection]、轻 [light]、中 [medium]、重 [heavy]、
///   成功确认 [success]，调用方按场景语义选择。
class HapticManager {
  static final shared = HapticManager();

  static const _storageKey = 'haptic_feedback_enabled';

  /// 振动反馈总开关（设置页可切换）。
  final RxBool enabled = true.obs;

  /// 启动时读取持久化开关（main.dart 调用一次）。
  void init() {
    final v = GetStorage().read(_storageKey);
    enabled.value = v is bool ? v : true;
  }

  /// 切换并持久化开关，返回最新状态。
  bool setEnabled(bool value) {
    enabled.value = value;
    GetStorage().write(_storageKey, value);
    // 打开时给一次即时反馈，让用户立刻感知效果
    if (value) selection();
    return value;
  }

  /// 选择/轻触：Tab 切换、按钮点选、收藏切换。
  void selection() {
    if (enabled.value) HapticFeedback.selectionClick();
  }

  /// 轻冲击：点赞/表情、关注、发送评论等轻量操作成功。
  void light() {
    if (enabled.value) HapticFeedback.lightImpact();
  }

  /// 中冲击：Tab 切换、发布动态、发送消息、长按唤出菜单。
  void medium() {
    if (enabled.value) HapticFeedback.mediumImpact();
  }

  /// 重冲击：强确认场景（如双击点赞放大动画、重要操作完成）。
  void heavy() {
    if (enabled.value) HapticFeedback.heavyImpact();
  }

  /// 成功确认（语义别名，等同中等冲击）。
  void success() => medium();
}
