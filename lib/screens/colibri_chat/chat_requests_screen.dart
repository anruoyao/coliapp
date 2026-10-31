import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_messenger_service.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/models/colibri_chat_models.dart';
import 'package:untitled/screens/colibri_chat/chat_detail_screen.dart';
import 'package:untitled/utilities/const.dart';

/// 陌生人请求 / 群邀请列表：接受或拒绝。
class ChatRequestsScreen extends StatefulWidget {
  const ChatRequestsScreen({super.key});

  @override
  State<ChatRequestsScreen> createState() => _ChatRequestsScreenState();
}

class _ChatRequestsScreenState extends State<ChatRequestsScreen> {
  List<ColibriChatRequest> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ColibriMessengerService.shared.fetchChatRequests();
      setState(() => _requests = list);
    } catch (e) {
      showColibriToast('加载失败',
          message: e.toString(),
          backgroundColor: cRed,
          colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept(ColibriChatRequest r) async {
    try {
      await ColibriMessengerService.shared.acceptInvite(r.chatId);
      setState(() => _requests.removeWhere((x) => x.id == r.id));
      // 接受后进入群聊
      Get.to(
          () => ChatDetailScreen(
              chatId: r.chatId, title: r.groupName, isGroup: true),
          opaque: false);
    } catch (e) {
      showColibriToast('操作失败',
          message: e.toString(),
          backgroundColor: cRed,
          colorText: Colors.white);
    }
  }

  Future<void> _decline(ColibriChatRequest r) async {
    try {
      await ColibriMessengerService.shared.declineInvite(r.chatId);
      setState(() => _requests.removeWhere((x) => x.id == r.id));
    } catch (e) {
      showColibriToast('操作失败',
          message: e.toString(),
          backgroundColor: cRed,
          colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cWhite,
      appBar: AppBar(
        backgroundColor: cWhite,
        elevation: 0,
        title: const Text('请求',
            style: TextStyle(fontWeight: FontWeight.bold, color: cMainText)),
        leading: BackButton(color: cBlack, onPressed: () => Get.back()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: cPrimary))
          : RefreshIndicator(
              color: cPrimary,
              onRefresh: _load,
              child: _requests.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 200),
                      Center(
                          child: Text('暂无请求',
                              style:
                                  TextStyle(color: cLightText, fontSize: 15))),
                    ])
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _requests.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: cLightBg),
                      itemBuilder: (context, index) {
                        final r = _requests[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: cLightBg,
                            backgroundImage: r.senderAvatarUrl != null
                                ? NetworkImage(r.senderAvatarUrl!)
                                : null,
                            child: r.senderAvatarUrl == null
                                ? const Icon(Icons.person_rounded,
                                    color: cLightIcon)
                                : null,
                          ),
                          title: Text('${r.senderName} 邀请你加入群聊',
                              style: const TextStyle(
                                  fontSize: 15, color: cMainText)),
                          subtitle: Text('${r.groupName} · ${r.timeAgo}',
                              style: const TextStyle(
                                  fontSize: 12, color: cLightText)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check_circle_rounded,
                                    color: cGreen, size: 28),
                                onPressed: () => _accept(r),
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel_rounded,
                                    color: cRed, size: 28),
                                onPressed: () => _decline(r),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
