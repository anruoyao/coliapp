import 'package:flutter/material.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:untitled/common/widgets/colibri_ui.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_messenger_service.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/models/colibri_chat_models.dart';
import 'package:untitled/utilities/const.dart';

/// 群成员管理：成员列表 / 邀请 / 移除 / 退出群。
class GroupMembersScreen extends StatefulWidget {
  final String chatId;

  const GroupMembersScreen({super.key, required this.chatId});

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  List<ColibriGroupParticipant> _members = [];
  bool _loading = true;
  int _myId = 0;
  bool _iAmAdmin = false;

  @override
  void initState() {
    super.initState();
    _myId = SessionManager.shared.getColibriUser()?['id'] is int
        ? (SessionManager.shared.getColibriUser()!['id'] as int)
        : int.tryParse('${SessionManager.shared.getColibriUser()?['id']}') ?? 0;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ColibriMessengerService.shared
          .fetchGroupParticipants(widget.chatId);
      setState(() {
        _members = list;
        _iAmAdmin = list.any((m) => m.userId == _myId && m.isAdmin);
      });
    } catch (e) {
      showColibriToast('加载失败',
          message: e.toString(),
          backgroundColor: cRed,
          colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openInvite() async {
    // 用 bottomSheet 弹出邀请面板（全屏 Get.to 会导致黑底显示异常）
    await showColibriBottomSheet(
      _InviteMembersSheet(chatId: widget.chatId),
      isScrollControlled: true,
      backgroundColor: cWhite,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
    _load();
  }

  Future<void> _removeMember(ColibriGroupParticipant m) async {
    final confirm = await showColibriConfirmDialog(
      context,
      title: '移除成员',
      message: '确定将 ${m.name} 移出群聊？',
      icon: Icons.person_remove_outlined,
      confirmText: '移除',
    );
    if (!confirm) return;
    try {
      await ColibriMessengerService.shared.deleteGroupParticipants(
          chatId: widget.chatId, ids: [m.participantId]);
      _load();
    } catch (e) {
      showColibriToast('操作失败',
          message: e.toString(),
          backgroundColor: cRed,
          colorText: Colors.white);
    }
  }

  Future<void> _leaveGroup() async {
    final confirm = await showColibriConfirmDialog(
      context,
      title: '退出群聊',
      message: '退出后将无法收到该群消息，确定退出？',
      icon: Icons.logout,
      confirmText: '退出',
    );
    if (!confirm) return;
    try {
      await ColibriMessengerService.shared.leaveGroup(widget.chatId);
      Get.until((route) => route.isFirst); // 回到主界面（会话列表会刷新）
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
        title: const Text('群成员',
            style: TextStyle(fontWeight: FontWeight.bold, color: cMainText)),
        leading: BackButton(color: cBlack, onPressed: () => Get.back()),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_rounded, color: cPrimary),
            onPressed: _openInvite,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: cPrimary))
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: _members.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: cLightBg),
                    itemBuilder: (context, index) {
                      final m = _members[index];
                      final isSelf = m.userId == _myId;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cLightBg,
                          backgroundImage: m.avatarUrl != null
                              ? NetworkImage(m.avatarUrl!)
                              : null,
                          child: m.avatarUrl == null
                              ? const Icon(Icons.person_rounded,
                                  color: cLightIcon)
                              : null,
                        ),
                        title: Row(
                          children: [
                            Flexible(
                                child: Text(m.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 15, color: cMainText))),
                            if (m.isAdmin) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded,
                                  color: cBlueTick, size: 16),
                            ],
                            if (m.online) ...[
                              const SizedBox(width: 4),
                              Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                      color: cGreen, shape: BoxShape.circle)),
                            ],
                          ],
                        ),
                        subtitle: Text('@${m.username}',
                            style: const TextStyle(
                                fontSize: 12, color: cLightText)),
                        trailing: (isSelf || !_iAmAdmin)
                            ? null
                            : IconButton(
                                icon: const Icon(
                                    Icons.remove_circle_outline_rounded,
                                    color: cRed),
                                onPressed: () => _removeMember(m),
                              ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _leaveGroup,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('退出群聊'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: cRed,
                          side: const BorderSide(color: cRed),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// 邀请成员弹窗：搜索用户 + 多选 + 发送邀请。
class _InviteMembersSheet extends StatefulWidget {
  final String chatId;

  const _InviteMembersSheet({required this.chatId});

  @override
  State<_InviteMembersSheet> createState() => _InviteMembersSheetState();
}

class _InviteMembersSheetState extends State<_InviteMembersSheet> {
  final TextEditingController _query = TextEditingController();
  List<ColibriInviteCandidate> _candidates = [];
  final Set<int> _selected = {};
  bool _searching = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  Future<void> _search(String q) async {
    setState(() => _searching = true);
    try {
      final list = await ColibriMessengerService.shared
          .searchInvitees(chatId: widget.chatId, query: q);
      setState(() => _candidates = list);
    } catch (_) {
      setState(() => _candidates = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _sendInvites() async {
    if (_selected.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ColibriMessengerService.shared.inviteParticipants(
          chatId: widget.chatId, userIds: _selected.toList());
      Get.back();
      showColibriToast('已发送',
          message: '邀请已发送', backgroundColor: cGreen, colorText: Colors.white);
    } catch (e) {
      showColibriToast('发送失败',
          message: e.toString(),
          backgroundColor: cRed,
          colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cWhite,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('邀请成员',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: cMainText)),
                  const Spacer(),
                  IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close_rounded)),
                ],
              ),
              TextField(
                controller: _query,
                onChanged: (q) => _search(q.trim()),
                decoration: InputDecoration(
                  hintText: '搜索用户名',
                  hintStyle: const TextStyle(color: cLightText, fontSize: 14),
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: cLightText),
                  filled: true,
                  fillColor: cLightBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                            child: CircularProgressIndicator(color: cPrimary)),
                      )
                    : _candidates.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                                child: Text('没有可邀请的用户',
                                    style: TextStyle(color: cLightText))),
                          )
                        : ListView(
                            shrinkWrap: true,
                            children: _candidates.map((c) {
                              final checked = _selected.contains(c.id);
                              // 对方限制了群组邀请时不可选中
                              return CheckboxListTile(
                                value: checked,
                                onChanged: c.canInvite
                                    ? (v) => setState(() {
                                          if (v == true) {
                                            _selected.add(c.id);
                                          } else {
                                            _selected.remove(c.id);
                                          }
                                        })
                                    : null,
                                title: Text(c.name,
                                    style: TextStyle(
                                        fontSize: 15,
                                        color: c.canInvite
                                            ? cMainText
                                            : cLightText)),
                                subtitle: Text(
                                  c.canInvite
                                      ? '@${c.username}'
                                      : '@${c.username}（对方限制了群组邀请）',
                                  style: const TextStyle(
                                      fontSize: 12, color: cLightText),
                                ),
                              );
                            }).toList(),
                          ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (_selected.isEmpty || _sending) ? null : _sendInvites,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(_sending ? '发送中...' : '发送邀请（${_selected.length}）',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
