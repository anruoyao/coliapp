import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:untitled/screens/colibri_social/colibri_profile_screen.dart';
import 'package:untitled/utilities/const.dart';

/// 轻量 Markdown 行内渲染（对齐网页端 markdown-it renderInline 行为）。
///
/// 支持语法（与网页速查表一致）：
/// - 粗体 `**x**`、斜体 `*x*`、粗斜体 `***x***` / `___x___`、删除线 `~~x~~`
/// - 下划线 `++x++`、高亮 `::x::`（网页端 underline/highlight 插件）
/// - 行内代码 `` `x` ``、链接 `[文字](网址)`、图片 `![描述](图片网址)`
/// - @提及（品牌绿高亮，点击跳主页）、裸链接自动识别可点击
///
/// 后端 content 输出前经过 e() HTML 转义（& < > " ' 变为实体），
/// 这里渲染前先解码实体（等价于网页端 markdown-it 的 entity 规则），
/// 同时修复了此前 App 直接显示实体字面量的问题。
class ColibriMarkdownText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const ColibriMarkdownText(this.text,
      {super.key, this.style, this.maxLines, this.overflow});

  @override
  State<ColibriMarkdownText> createState() => _ColibriMarkdownTextState();
}

class _ColibriMarkdownTextState extends State<ColibriMarkdownText> {
  final List<TapGestureRecognizer> _recognizers = [];
  List<InlineSpan> _spans = const [];

  @override
  void initState() {
    super.initState();
    _spans = _buildSpans(widget.text);
  }

  @override
  void didUpdateWidget(ColibriMarkdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
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

  /// PHP htmlspecialchars（e()）+ 常见命名/数字实体解码。
  static String _htmlUnescape(String input) {
    if (!input.contains('&')) return input;

    return input.replaceAllMapped(
        RegExp(r'&(#[0-9]+|#[xX][0-9a-fA-F]+|[a-zA-Z]+);'), (m) {
      switch (m.group(0)) {
        case '&amp;':
          return '&';
        case '&lt;':
          return '<';
        case '&gt;':
          return '>';
        case '&quot;':
          return '"';
        case '&apos;':
          return "'";
        case '&#039;': // PHP htmlspecialchars 的单引号转义
          return "'";
        case '&nbsp;':
          return ' ';
      }

      final body = m.group(1)!;
      if (body.startsWith('#')) {
        final isHex = body.length > 1 && (body[1] == 'x' || body[1] == 'X');
        final code =
            int.tryParse(body.substring(isHex ? 2 : 1), radix: isHex ? 16 : 10);
        if (code != null &&
            (code == 0x9 ||
                code == 0xA ||
                code == 0xD ||
                (code >= 0x20 && code <= 0xD7FF) ||
                (code >= 0xE000 && code <= 0xFFFD) ||
                (code >= 0x10000 && code <= 0x10FFFF))) {
          return String.fromCharCode(code);
        }
      }

      // 未知命名实体原样保留（保守处理）
      return m.group(0)!;
    });
  }

  /// 行内语法 master 正则（交替顺序即优先级，粗斜体先于粗体/斜体）。
  /// `\S(?:.*?\S)?` 约束首尾非空白（模拟 CommonMark 的 flanking 规则，
  /// 避免把 `* 列表项 *` 之类误渲染为斜体）。
  static final RegExp _masterRegex = RegExp(
    '`(?<code>[^`\\n]+)`'
    r'|!\[(?<imgAlt>[^\]]*)\]\((?<imgUrl>[^)\s]+)\)'
    r'|\[(?<linkText>[^\]]+)\]\((?<linkUrl>[^)\s]+)\)'
    r'|(?:\*\*\*(?<bi1>\S(?:.*?\S)?)\*\*\*|___(?<bi2>\S(?:.*?\S)?)___)'
    r'|\*\*(?<bold>\S(?:.*?\S)?)\*\*'
    r'|\*(?<italic>\S(?:.*?\S)?)\*'
    r'|~~(?<strike>\S(?:.*?\S)?)~~'
    r'|\+\+(?<underline>\S(?:.*?\S)?)\+\+'
    r'|::(?<highlight>\S(?:.*?\S)?)::'
    r'|(?<mention>@[a-zA-Z0-9_.]+)'
    r'|(?<url>https?://[^\s<>"\]]+)',
  );

  List<InlineSpan> _buildSpans(String rawContent) {
    final baseStyle = widget.style ??
        const TextStyle(fontSize: 15, color: cMainText, height: 1.4);
    final content = _htmlUnescape(rawContent);
    return _parseInline(content, baseStyle);
  }

  List<InlineSpan> _parseInline(String content, TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    var last = 0;

    for (final m in _masterRegex.allMatches(content)) {
      if (m.start > last) {
        spans.add(
            TextSpan(text: content.substring(last, m.start), style: baseStyle));
      }

      final named = (String name) => m.namedGroup(name);

      final code = named('code');
      final imgAlt = named('imgAlt');
      final imgUrl = named('imgUrl');
      final linkText = named('linkText');
      final linkUrl = named('linkUrl');
      final boldItalic = named('bi1') ?? named('bi2');
      final bold = named('bold');
      final italic = named('italic');
      final strike = named('strike');
      final underline = named('underline');
      final highlight = named('highlight');
      final mention = named('mention');
      final url = named('url');

      if (code != null) {
        // 行内代码：等宽字体 + 浅灰底（对齐网页 .markdown-text code）
        spans.add(TextSpan(
          text: code,
          style: baseStyle.copyWith(
            fontFamily: 'monospace',
            backgroundColor: cLightBg,
            fontSize: (baseStyle.fontSize ?? 15) - 1,
          ),
        ));
      } else if (imgUrl != null) {
        // 图片语法：以链接形式展示（描述或网址），点击外部打开
        spans.add(_buildLinkSpan(
            (imgAlt == null || imgAlt.isEmpty) ? imgUrl : imgAlt,
            imgUrl,
            baseStyle,
            prefix: '🖼 '));
      } else if (linkUrl != null && linkText != null) {
        spans.add(_buildLinkSpan(linkText, linkUrl, baseStyle));
      } else if (boldItalic != null) {
        spans.addAll(_parseInline(
          boldItalic,
          baseStyle.copyWith(
              fontWeight: FontWeight.w700, fontStyle: FontStyle.italic),
        ));
      } else if (bold != null) {
        spans.addAll(_parseInline(
            bold, baseStyle.copyWith(fontWeight: FontWeight.w700)));
      } else if (italic != null) {
        spans.addAll(_parseInline(
            italic, baseStyle.copyWith(fontStyle: FontStyle.italic)));
      } else if (strike != null) {
        spans.addAll(_parseInline(
          strike,
          baseStyle.copyWith(
              decoration: TextDecoration.combine([
            if (baseStyle.decoration != null) baseStyle.decoration!,
            TextDecoration.lineThrough,
          ])),
        ));
      } else if (underline != null) {
        spans.addAll(_parseInline(
          underline,
          baseStyle.copyWith(
              decoration: TextDecoration.combine([
            if (baseStyle.decoration != null) baseStyle.decoration!,
            TextDecoration.underline,
          ])),
        ));
      } else if (highlight != null) {
        spans.addAll(_parseInline(
          highlight,
          baseStyle.copyWith(backgroundColor: const Color(0xFFFFF3C4)),
        ));
      } else if (mention != null) {
        final username = mention.substring(1);
        final recognizer = TapGestureRecognizer()
          ..onTap = () {
            if (username.isNotEmpty) {
              Get.to(() => ColibriProfileScreen(username: username),
                  opaque: false);
            }
          };
        _recognizers.add(recognizer);
        spans.add(TextSpan(
          text: mention,
          style:
              baseStyle.copyWith(color: cPrimary, fontWeight: FontWeight.w600),
          recognizer: recognizer,
        ));
      } else if (url != null) {
        spans.add(_buildLinkSpan(url, url, baseStyle));
      }

      last = m.end;
    }

    if (last < content.length) {
      spans.add(TextSpan(text: content.substring(last), style: baseStyle));
    }
    return spans.isEmpty ? [TextSpan(text: '', style: baseStyle)] : spans;
  }

  /// 可点击链接 span（品牌绿，对齐网页 .markdown-text a）。
  InlineSpan _buildLinkSpan(String text, String url, TextStyle baseStyle,
      {String prefix = ''}) {
    final recognizer = TapGestureRecognizer()
      ..onTap = () async {
        final uri = Uri.tryParse(url);
        if (uri == null) return;
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {}
      };
    _recognizers.add(recognizer);
    return TextSpan(
      text: '$prefix$text',
      style: baseStyle.copyWith(color: cPrimary, fontWeight: FontWeight.w600),
      recognizer: recognizer,
    );
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

/// 文本格式速查面板（对齐网页端 MarkdownCheatSheet：格式名 + 语法示例）。
void showMarkdownCheatSheet(BuildContext context) {
  const groups = <({
    String title,
    List<({IconData icon, String name, String syntax})> items
  })>[
    (
      title: '文本格式',
      items: [
        (icon: Icons.format_bold_rounded, name: '粗体', syntax: '**文本**'),
        (icon: Icons.format_italic_rounded, name: '斜体', syntax: '*文本*'),
        (icon: Icons.strikethrough_s_rounded, name: '删除线', syntax: '~~文本~~'),
        (icon: Icons.format_italic_rounded, name: '粗体加斜体', syntax: '***文本***'),
        (icon: Icons.format_underline_rounded, name: '下划线', syntax: '++文本++'),
        (icon: Icons.brush_rounded, name: '高亮', syntax: '::文本::'),
      ],
    ),
    (
      title: '块级格式',
      items: [
        (icon: Icons.code_rounded, name: '行内代码', syntax: '`代码`'),
        (icon: Icons.link_rounded, name: '链接', syntax: '[文字](网址)'),
        (icon: Icons.image_rounded, name: '图片链接', syntax: '![描述](图片网址)'),
      ],
    ),
  ];

  showColibriBottomSheet<void>(
    SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: cLightBg, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          const Text('文本格式',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: cMainText)),
          const SizedBox(height: 4),
          const Text('发帖时使用以下语法为文本添加格式',
              style: TextStyle(fontSize: 12, color: cLightText)),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (:title, :items) in groups) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Text(title,
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: cGreen)),
                    ),
                    for (final (:icon, :name, :syntax) in items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          children: [
                            Icon(icon, size: 20, color: cMainText),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(name,
                                    style: const TextStyle(
                                        fontSize: 14.5, color: cMainText))),
                            Text(syntax,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: cLightText,
                                    fontFamily: 'monospace')),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    context: context,
    backgroundColor: cWhite,
    useSafeArea: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
  );
}
