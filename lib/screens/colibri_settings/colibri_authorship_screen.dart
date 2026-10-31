import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_settings_service.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/screens/colibri_settings/colibri_settings_screen.dart';
import 'package:untitled/utilities/const.dart';

/// 作者身份：查看状态 + 申请成为作者（发布内容）。
class ColibriAuthorshipScreen extends StatefulWidget {
  const ColibriAuthorshipScreen({super.key});

  @override
  State<ColibriAuthorshipScreen> createState() =>
      _ColibriAuthorshipScreenState();
}

class _ColibriAuthorshipScreenState extends State<ColibriAuthorshipScreen> {
  late Future<String> _statusFuture;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _statusFuture = ColibriSettingsService.shared.fetchAuthorshipStatus();
  }

  String _label(String status) {
    switch (status) {
      case 'authorized':
        return '你已成为作者';
      case 'pending':
        return '申请审核中';
      default:
        return '尚未申请';
    }
  }

  Future<void> _request() async {
    setState(() => _requesting = true);
    try {
      await ColibriSettingsService.shared.requestAuthorship();
      if (!mounted) return;
      setState(() {
        _statusFuture = Future.value('pending');
        _requesting = false;
      });
      showColibriToast('已提交',
          message: '你的作者申请已提交，等待审核',
          backgroundColor: cGreen,
          colorText: Colors.white);
    } catch (e) {
      setState(() => _requesting = false);
      showColibriToast('提交失败',
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
        title: const Text('作者身份',
            style: TextStyle(fontWeight: FontWeight.bold, color: cMainText)),
        leading: BackButton(color: cBlack, onPressed: () => Get.back()),
      ),
      body: FutureBuilder<String>(
        future: _statusFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: cPrimary));
          }
          final status = snap.data ?? 'not_requested';
          final isAuthor = status == 'authorized';
          final isPending = status == 'pending';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Icon(isAuthor ? Icons.verified_rounded : Icons.badge_outlined,
                  size: 56, color: isAuthor ? cBlueTick : cLightIcon),
              const SizedBox(height: 12),
              Center(
                child: Text(_label(status),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cMainText)),
              ),
              const SizedBox(height: 8),
              const Text(
                '成为作者后可发布帖子、上传故事等内容，与粉丝互动。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cLightText),
              ),
              const SizedBox(height: 24),
              if (!isAuthor)
                ColibriSettingsSaveButton(
                  text: isPending ? '申请审核中...' : '申请成为作者',
                  loading: _requesting || isPending,
                  onTap: isPending ? () {} : _request,
                ),
            ],
          );
        },
      ),
    );
  }
}
