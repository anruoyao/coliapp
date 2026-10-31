import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_story_service.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/utilities/const.dart';

/// 故事编辑页：沉浸式深色预览 + 文字描述 + 发布（对齐网页端 story_editor 的 content 字段）。
/// 返回值 true 表示发布成功（调用方据此刷新故事条）。
class ColibriStoryComposerScreen extends StatefulWidget {
  final String imagePath;

  const ColibriStoryComposerScreen({super.key, required this.imagePath});

  @override
  State<ColibriStoryComposerScreen> createState() =>
      _ColibriStoryComposerScreenState();
}

class _ColibriStoryComposerScreenState
    extends State<ColibriStoryComposerScreen> {
  final TextEditingController _text = TextEditingController();
  bool _publishing = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_publishing) return;
    setState(() => _publishing = true);
    try {
      await ColibriStoryService.shared.createStory(
        imagePath: widget.imagePath,
        content: _text.text.trim(),
      );
      Get.back(result: true);
    } catch (e) {
      showColibriToast('发布失败',
          message: e.toString(),
          backgroundColor: cRed,
          colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBlack,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: cBlack,
        elevation: 0,
        title: const Text('新故事',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 16, color: cWhite)),
        leading: BackButton(color: cWhite, onPressed: () => Get.back()),
      ),
      body: Column(
        children: [
          // 图片预览
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 10))
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.file(File(widget.imagePath),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity),
            ),
          ),
          // 文字输入 + 发布
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _text,
                    maxLength: 200,
                    maxLines: 3,
                    minLines: 1,
                    style: const TextStyle(
                        color: cWhite, fontSize: 15, height: 1.4),
                    cursorColor: cPrimary,
                    decoration: InputDecoration(
                      hintText: '为故事添加文字描述…',
                      hintStyle: TextStyle(
                          color: cWhite.withValues(alpha: 0.4), fontSize: 14.5),
                      counterStyle: TextStyle(
                          color: cWhite.withValues(alpha: 0.35), fontSize: 11),
                      filled: true,
                      fillColor: cWhite.withValues(alpha: 0.08),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: cWhite.withValues(alpha: 0.15)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: cPrimary, width: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PublishButton(onTap: _publish, loading: _publishing),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PublishButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool loading;

  const _PublishButton({required this.onTap, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cPrimary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: loading ? null : onTap,
        child: SizedBox(
          height: 52,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: cBlack))
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.rocket_launch_rounded,
                          size: 19, color: cBlack),
                      SizedBox(width: 8),
                      Text('发布故事',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: cBlack)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
