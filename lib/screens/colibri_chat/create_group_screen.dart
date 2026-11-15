import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_messenger_service.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/colibri_chat/chat_detail_screen.dart';
import 'package:untitled/utilities/const.dart';

/// 创建群聊：建草稿 → 填名称/描述 → 保存 → 进入群聊。
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _desc = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty || _creating) return;
    setState(() => _creating = true);
    try {
      final chatId = await ColibriMessengerService.shared.createGroupDraft();
      if (chatId.isEmpty) {
        showColibriToast(LKeys.chatCreateFailed.tr,
            message: LKeys.chatGroupDraftCreateFailed.tr,
            backgroundColor: cRed,
            colorText: Colors.white);
        return;
      }
      await ColibriMessengerService.shared.updateGroup(
        chatId: chatId,
        name: name,
        description: _desc.text.trim(),
      );
      // 进入群聊并关闭创建页
      Get.off(() => ChatDetailScreen(
            chatId: chatId,
            title: name,
            isGroup: true,
          ));
    } catch (e) {
      showColibriToast(LKeys.chatCreateFailed.tr,
          message: e.toString(),
          backgroundColor: cRed,
          colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cWhite,
      appBar: AppBar(
        backgroundColor: cWhite,
        elevation: 0,
        title: Text(LKeys.chatCreateGroup.tr,
            style:
                const TextStyle(fontWeight: FontWeight.bold, color: cMainText)),
        leading: BackButton(color: cBlack, onPressed: () => Get.back()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LKeys.chatGroupName.tr,
                style: const TextStyle(
                    fontSize: 15,
                    color: cMainText,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              maxLength: 100,
              decoration: _fieldDecoration(LKeys.chatGroupNameHint.tr),
            ),
            const SizedBox(height: 16),
            Text(LKeys.chatGroupDescription.tr,
                style: const TextStyle(
                    fontSize: 15,
                    color: cMainText,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _desc,
              maxLines: 3,
              maxLength: 240,
              decoration: _fieldDecoration(LKeys.chatGroupDescriptionHint.tr),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _creating ? null : _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _creating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(LKeys.chatCreate.tr,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: cLightText, fontSize: 15),
      filled: true,
      fillColor: cLightBg,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
