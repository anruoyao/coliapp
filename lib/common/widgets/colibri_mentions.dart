import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_social_service.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/models/colibri_social_models.dart';
import 'package:untitled/screens/colibri_social/colibri_profile_screen.dart';
import 'package:untitled/utilities/const.dart';

/// @提及相关组件（对齐网页 colibri 的 MentionsPicker + markdown mention 插件）。
///
/// 网页机制：
/// - 输入：光标前文本匹配 `\B@[a-zA-Z0-9_.]+$` → POST autocompletes/mentions 联想 →
///   选中后把半截 token 替换为完整 `@username`。
/// - 展示：正文里的 `@username` 渲染为可点击链接（跳 `/@username` 主页）。
/// - 通知：后端 getMentions() 用同一正则解析 content 并发提及通知（App 无需处理）。

/// 提及 token 匹配（与网页 matchMention 同款正则）。
/// 返回 (username 去掉@, token 起始下标, token 结束下标)；无匹配返回 null。
({String username, int start, int end})? matchMentionToken(
    TextEditingValue value) {
  final cursor = value.selection.baseOffset;
  if (cursor < 0 || cursor > value.text.length) return null;
  final before = value.text.substring(0, cursor);
  final m = RegExp(r'\B@[a-zA-Z0-9_.]+$').firstMatch(before);
  if (m == null) return null;
  return (username: m.group(0)!.substring(1), start: m.start, end: m.end);
}

/// 带联想面板的输入框：输入 @xx 后弹出用户候选，点选补全为 `@username `。
class MentionField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final InputDecoration? decoration;
  final bool suggestionsAbove; // 评论框在底部时置 true，面板显示在输入框上方
  final double suggestionsMaxHeight;

  const MentionField({
    super.key,
    required this.controller,
    required this.hintText,
    this.focusNode,
    this.style,
    this.hintStyle,
    this.minLines,
    this.maxLines,
    this.maxLength,
    this.textInputAction,
    this.onSubmitted,
    this.decoration,
    this.suggestionsAbove = false,
    this.suggestionsMaxHeight = 250,
  });

  @override
  State<MentionField> createState() => _MentionFieldState();
}

class _MentionFieldState extends State<MentionField> {
  final List<ColibriMentionUser> _suggestions = [];
  Timer? _debounce;
  int _requestSeq = 0; // 丢弃过期响应
  bool _loading = false;
  FocusNode? _ownFocusNode;

  FocusNode get _focus => widget.focusNode ?? _ownFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) _ownFocusNode = FocusNode();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onTextChanged);
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    final token = matchMentionToken(widget.controller.value);

    // query 少于 2 字符不请求（后端校验 min:2）
    if (token == null || token.username.length < 2) {
      if (_suggestions.isNotEmpty || _loading) {
        setState(() {
          _suggestions.clear();
          _loading = false;
        });
      }
      return;
    }

    _debounce =
        Timer(const Duration(milliseconds: 250), () => _fetch(token.username));
  }

  Future<void> _fetch(String query) async {
    setState(() => _loading = true);
    final seq = ++_requestSeq;
    try {
      final users = await ColibriSocialService.shared.searchMentions(query);
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _suggestions
          ..clear()
          ..addAll(users);
      });
    } catch (_) {
      if (!mounted || seq != _requestSeq) return;
      setState(() => _suggestions.clear());
    } finally {
      if (mounted && seq == _requestSeq) setState(() => _loading = false);
    }
  }

  /// 选中候选：把光标前的半截 `@xx` 替换为 `@username `（尾随空格，方便继续输入）。
  void _select(ColibriMentionUser user) {
    final value = widget.controller.value;
    final token = matchMentionToken(value);
    final text = value.text;
    if (token == null) {
      // 光标已移动的兜底：直接在末尾追加
      final appended = '$text@${user.username} ';
      widget.controller.value = TextEditingValue(
        text: appended,
        selection: TextSelection.collapsed(offset: appended.length),
      );
    } else {
      final replaced =
          '${text.substring(0, token.start)}@${user.username} ${text.substring(token.end)}';
      final cursor = token.start + user.username.length + 2;
      widget.controller.value = TextEditingValue(
        text: replaced,
        selection: TextSelection.collapsed(offset: cursor),
      );
    }
    setState(() => _suggestions.clear());
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: widget.controller,
      focusNode: _focus,
      style: widget.style,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      cursorColor: cPrimary,
      decoration: widget.decoration ??
          InputDecoration(
            hintText: widget.hintText,
            hintStyle: widget.hintStyle,
            border: InputBorder.none,
            counterText: '',
          ),
    );

    final panel = _buildPanel();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.suggestionsAbove) ...[
          if (panel != null) panel,
          field
        ] else ...[
          field,
          if (panel != null) panel
        ],
      ],
    );
  }

  Widget? _buildPanel() {
    if (_suggestions.isEmpty && !_loading) return null;

    final body = _loading && _suggestions.isEmpty
        ? const Padding(
            padding: EdgeInsets.all(14),
            child: SizedBox(
              height: 20,
              width: 20,
              child:
                  CircularProgressIndicator(strokeWidth: 2.2, color: cPrimary),
            ),
          )
        : ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final user = _suggestions[index];
              return _MentionRow(user: user, onTap: () => _select(user));
            },
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: cWhite,
        elevation: 4,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: widget.suggestionsMaxHeight),
          child:
              ClipRRect(borderRadius: BorderRadius.circular(14), child: body),
        ),
      ),
    );
  }
}

/// 候选行：头像 + 名字 + @username（对齐网页 MentionItem）。
class _MentionRow extends StatelessWidget {
  final ColibriMentionUser user;
  final VoidCallback onTap;

  const _MentionRow({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            MyCachedProfileImage(
              imageUrl: user.avatarUrl,
              width: 34,
              height: 34,
              fullName: user.name,
              cornerRadius: 17,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: user.name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cMainText),
                    ),
                    TextSpan(
                      text: '  @${user.username}',
                      style: const TextStyle(fontSize: 12.5, color: cLightText),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 正文富文本：`@username` 高亮为绿色，点击跳转该用户主页（对齐网页 mention 链接 `/@username`）。
class MentionText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const MentionText(this.text,
      {super.key, this.style, this.maxLines, this.overflow});

  @override
  State<MentionText> createState() => _MentionTextState();
}

class _MentionTextState extends State<MentionText> {
  static final _mentionRegex = RegExp(r'@[a-zA-Z0-9_.]+');
  final List<TapGestureRecognizer> _recognizers = [];
  List<InlineSpan> _spans = const [];

  @override
  void initState() {
    super.initState();
    _spans = _buildSpans(widget.text);
  }

  @override
  void didUpdateWidget(MentionText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _disposeRecognizers();
      _spans = _buildSpans(widget.text);
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  List<InlineSpan> _buildSpans(String content) {
    final baseStyle = widget.style ??
        const TextStyle(fontSize: 15, color: cMainText, height: 1.4);
    final mentionStyle =
        baseStyle.copyWith(color: cPrimary, fontWeight: FontWeight.w600);

    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _mentionRegex.allMatches(content)) {
      if (m.start > last) {
        spans.add(
            TextSpan(text: content.substring(last, m.start), style: baseStyle));
      }
      final username = m.group(0)!.substring(1);
      final recognizer = TapGestureRecognizer()
        ..onTap = () {
          if (username.isNotEmpty) {
            Get.to(() => ColibriProfileScreen(username: username),
                opaque: false);
          }
        };
      _recognizers.add(recognizer);
      spans.add(TextSpan(
          text: m.group(0), style: mentionStyle, recognizer: recognizer));
      last = m.end;
    }
    if (last < content.length) {
      spans.add(TextSpan(text: content.substring(last), style: baseStyle));
    }
    return spans.isEmpty ? [TextSpan(text: '', style: baseStyle)] : spans;
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: _spans),
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}
