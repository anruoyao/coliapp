import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_social_service.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/models/colibri_social_models.dart';
import 'package:untitled/screens/colibri_social/colibri_profile_screen.dart';
import 'package:untitled/utilities/const.dart';

/// 屏蔽 / 静音列表：查看 + 解除。通过 [isMutedList] 区分。
class ColibriBlockListScreen extends StatefulWidget {
  final bool isMutedList;

  const ColibriBlockListScreen({super.key, this.isMutedList = false});

  @override
  State<ColibriBlockListScreen> createState() => _ColibriBlockListScreenState();
}

class _ColibriBlockListScreenState extends State<ColibriBlockListScreen> {
  final List<ColibriBlockedUser> _blocked = [];
  bool _loading = true;

  bool get _isMuted => widget.isMutedList;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = _isMuted
          ? await ColibriSocialService.shared.fetchMutedUsers()
          : await ColibriSocialService.shared.fetchBlockedUsers();
      setState(() => _blocked
        ..clear()
        ..addAll(list));
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(ColibriBlockedUser u) async {
    try {
      if (_isMuted) {
        await ColibriSocialService.shared.toggleMute(u.id);
        showColibriToast('已取消静音',
            message: '', backgroundColor: cGreen, colorText: Colors.white);
      } else {
        await ColibriSocialService.shared.toggleBlock(u.id);
        showColibriToast('已解除拉黑',
            message: '', backgroundColor: cGreen, colorText: Colors.white);
      }
      setState(() => _blocked.removeWhere((x) => x.id == u.id));
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
        title: Text(_isMuted ? '静音列表' : '黑名单',
            style:
                const TextStyle(fontWeight: FontWeight.bold, color: cMainText)),
        leading: BackButton(color: cBlack, onPressed: () => Get.back()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: cPrimary))
          : _blocked.isEmpty
              ? Center(
                  child: Text(_isMuted ? '暂无静音用户' : '暂无拉黑用户',
                      style: const TextStyle(color: cLightText)))
              : ListView.separated(
                  itemCount: _blocked.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: cLightBg),
                  itemBuilder: (context, index) {
                    final u = _blocked[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cLightBg,
                        backgroundImage: u.avatarUrl != null
                            ? NetworkImage(u.avatarUrl!)
                            : null,
                        child: u.avatarUrl == null
                            ? const Icon(Icons.person_rounded,
                                color: cLightIcon)
                            : null,
                      ),
                      title: Row(
                        children: [
                          Flexible(
                              child: Text(u.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 15, color: cMainText))),
                          if (u.verified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded,
                                color: cBlueTick, size: 16),
                          ],
                        ],
                      ),
                      subtitle: Text('@${u.username}',
                          style:
                              const TextStyle(fontSize: 12, color: cLightText)),
                      trailing: TextButton(
                        onPressed: () => _remove(u),
                        child:
                            const Text('解除', style: TextStyle(color: cPrimary)),
                      ),
                      onTap: () => Get.to(
                          () => ColibriProfileScreen(username: u.username),
                          opaque: false),
                    );
                  },
                ),
    );
  }
}
