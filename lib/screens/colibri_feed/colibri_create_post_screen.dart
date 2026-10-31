import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled/common/api_service/colibri_timeline_service.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/common/api_service/colibri_api.dart';
import 'package:untitled/common/managers/haptic_manager.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/managers/upload_limits_service.dart';
import 'package:untitled/common/widgets/colibri_markdown_text.dart';
import 'package:untitled/common/widgets/colibri_mentions.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/utilities/const.dart';

/// 单个待上传媒体的状态。
enum _UploadStatus { pending, uploading, uploaded, failed }

/// 图片条目：本地路径 + 上传状态 + 进度 + 服务器 media id（已上传时）。
class _ImageItem {
  _ImageItem(this.path)
      : fileSize = File(path).existsSync() ? File(path).lengthSync() : 0;

  final String path;
  final int fileSize; // 字节
  _UploadStatus status = _UploadStatus.pending;
  double progress = 0; // 0~1
  int? serverMediaId; // upload 响应的 media id（用于发布前撤回）

  bool get uploaded => status == _UploadStatus.uploaded;
}

/// 发布帖子：文本 / 多图 / 视频 / 音频 / 文件 / 投票。
/// 布局：头像身份行 + 无边框大输入区，底部固定工具栏（附件 + 发布按钮）。
/// 上传：每张图片独立进度条；视频/音频/文件内嵌进度条；失败可单独重试（已上传的跳过重传）。
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _content = TextEditingController();

  /// 多图（后端草稿制逐张上传，上限见 config/post.php max_images_count = 10）
  static const int _maxImages = 10;
  final List<_ImageItem> _images = [];

  // 非图片媒体（单一，互斥）：video / audio / document
  String? _mediaPath;
  String? _mediaName;
  String? _mediaType; // video / audio / document
  int _mediaFileSize = 0;
  _UploadStatus _mediaStatus = _UploadStatus.pending;
  double _mediaProgress = 0; // 0~1
  int? _mediaServerId; // upload 响应的 media id（用于发布前撤回）

  // 投票编辑
  bool _pollMode = false;
  final List<TextEditingController> _pollOptions = [
    TextEditingController(),
    TextEditingController(),
  ];

  // 帖子标记（对齐网页端 marks：敏感内容 / AI 生成）
  bool _isSensitive = false;
  bool _isAiGenerated = false;

  bool _publishing = false;
  bool _hasContent = false;
  String? _uploadLabel; // 发布按钮 loading 文案（「图片 2/5」/「上传 46%」）

  @override
  void initState() {
    super.initState();
    SessionManager.shared
        .refreshColibriUser(ColibriApi.shared.fetchBootstrapUser)
        .catchError((_) {});
    _content.addListener(() {
      final has = _content.text.trim().isNotEmpty ||
          _mediaPath != null ||
          _images.isNotEmpty ||
          _pollMode;
      if (has != _hasContent) setState(() => _hasContent = has);
    });
  }

  @override
  void dispose() {
    _content.dispose();
    for (final c in _pollOptions) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncHasContent() {
    final has = _content.text.trim().isNotEmpty ||
        _mediaPath != null ||
        _images.isNotEmpty ||
        _pollMode;
    if (has != _hasContent) setState(() => _hasContent = has);
  }

  String _fmtBytes(int b) {
    const mb = 1024 * 1024;
    const gb = mb * 1024;
    if (b >= gb) return '${(b / gb).toStringAsFixed(1)}GB';
    if (b >= mb) return '${(b / mb).toStringAsFixed(1)}MB';
    if (b >= 1024) return '${(b / 1024).toStringAsFixed(0)}KB';
    return '${b}B';
  }

  // ===================== 选择媒体 =====================

  /// 选图（可多选，追加到现有图片，与视频/音频/文件互斥）。
  Future<void> _pickImage() async {
    final remaining = _maxImages - _images.length;
    if (remaining <= 0) {
      showColibriToast('图片已达上限',
          message: '一条帖子最多 $_maxImages 张图片',
          backgroundColor: cRed,
          colorText: Colors.white);
      return;
    }
    final files = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (files.isEmpty) return;
    final picked =
        files.take(remaining).map((f) => _ImageItem(f.path)).toList();

    // 本地预检测：过滤超出后台配置限制的图片并提示（避免无谓上传）
    final valid = <_ImageItem>[];
    String? oversizedMessage;
    for (final item in picked) {
      final msg =
          await UploadLimitsService.shared.check(item.fileSize, 'image');
      if (msg != null) {
        oversizedMessage ??= msg;
      } else {
        valid.add(item);
      }
    }

    setState(() {
      _images.addAll(valid);
      // 图片与其它媒体类型互斥
      _clearMediaState();
    });
    if (oversizedMessage != null) {
      showColibriToast('图片过大',
          message: oversizedMessage,
          backgroundColor: cRed,
          colorText: Colors.white);
    }
    if (files.length > picked.length) {
      showColibriToast('图片已达上限',
          message: '一条帖子最多 $_maxImages 张图片，已选取前 $_maxImages 张',
          backgroundColor: cRed,
          colorText: Colors.white);
    }
    _syncHasContent();
  }

  /// 移除第 index 张已选图片。已上传的先从服务器草稿撤回（media/delete）再移除本地。
  Future<void> _removeImage(int index) async {
    final item = _images[index];
    if (item.status == _UploadStatus.uploading) return;
    if (item.uploaded) {
      // 先删服务器草稿记录，失败则保留（发布会包含它）
      if (item.serverMediaId != null) {
        try {
          await ColibriTimelineService.shared.deleteMedia(item.serverMediaId!);
        } catch (e) {
          showColibriToast('移除失败',
              message: '未能从草稿撤回该图片：$e',
              backgroundColor: cRed,
              colorText: Colors.white);
          return;
        }
      }
      setState(() => _images.removeAt(index));
      _syncHasContent();
      return;
    }
    setState(() => _images.removeAt(index));
    _syncHasContent();
  }

  /// 切换到非图片媒体时：先把已上传图片从服务器草稿撤回（避免重复上传残留）。
  Future<void> _revokeUploadedImages() async {
    final uploaded = _images.where((e) => e.uploaded).toList();
    for (final e in uploaded) {
      if (e.serverMediaId != null) {
        try {
          await ColibriTimelineService.shared.deleteMedia(e.serverMediaId!);
        } catch (_) {}
      }
    }
  }

  void _clearMediaState() {
    _mediaPath = null;
    _mediaName = null;
    _mediaType = null;
    _mediaFileSize = 0;
    _mediaStatus = _UploadStatus.pending;
    _mediaProgress = 0;
    _mediaServerId = null;
  }

  Future<void> _pickVideo() async {
    final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (file == null) return;

    // 本地预检测：超出后台配置的视频大小限制时立即提示
    final size = File(file.path).lengthSync();
    final msg = await UploadLimitsService.shared.check(size, 'video');
    if (msg != null) {
      showColibriToast('视频过大',
          message: msg, backgroundColor: cRed, colorText: Colors.white);
      return;
    }

    await _revokeUploadedImages();
    setState(() {
      _images.clear();
      _clearMediaState();
      _mediaPath = file.path;
      _mediaName = file.name;
      _mediaType = 'video';
      _mediaFileSize = size;
    });
    _syncHasContent();
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'mp3',
        'wav',
        'm4a',
        'ogg',
        'aac',
        'opus',
        'webm',
        'amr'
      ],
    );
    if (result == null || result.files.single.path == null) return;

    // 本地预检测：超出后台配置的音频大小限制时立即提示
    final msg = await UploadLimitsService.shared
        .check(result.files.single.size, 'audio');
    if (msg != null) {
      showColibriToast('音频过大',
          message: msg, backgroundColor: cRed, colorText: Colors.white);
      return;
    }

    await _revokeUploadedImages();
    setState(() {
      _images.clear();
      _clearMediaState();
      _mediaPath = result.files.single.path!;
      _mediaName = result.files.single.name;
      _mediaType = 'audio';
      _mediaFileSize = result.files.single.size;
    });
    _syncHasContent();
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) return;

    // 本地预检测：超出后台配置的文档大小限制时立即提示
    final msg = await UploadLimitsService.shared
        .check(result.files.single.size, 'document');
    if (msg != null) {
      showColibriToast('文件过大',
          message: msg, backgroundColor: cRed, colorText: Colors.white);
      return;
    }

    await _revokeUploadedImages();
    setState(() {
      _images.clear();
      _clearMediaState();
      _mediaPath = result.files.single.path!;
      _mediaName = result.files.single.name;
      _mediaType = 'document';
      _mediaFileSize = result.files.single.size;
    });
    _syncHasContent();
  }

  /// 移除单媒体。已上传的先从服务器草稿撤回（video/audio 的草稿会被整帖删除）。
  Future<void> _clearMedia() async {
    if (_mediaStatus == _UploadStatus.uploading) return;
    if (_mediaStatus == _UploadStatus.uploaded) {
      if (_mediaServerId != null) {
        try {
          await ColibriTimelineService.shared.deleteMedia(_mediaServerId!);
        } catch (e) {
          showColibriToast('移除失败',
              message: '未能从草稿撤回该文件：$e',
              backgroundColor: cRed,
              colorText: Colors.white);
          return;
        }
      }
    }
    setState(() => _clearMediaState());
    _syncHasContent();
  }

  // ===================== 投票编辑 =====================

  void _addPollOption() {
    if (_pollOptions.length >= 10) return;
    setState(() => _pollOptions.add(TextEditingController()));
  }

  void _removePollOption(int index) {
    if (_pollOptions.length <= 2) return;
    setState(() {
      _pollOptions[index].dispose();
      _pollOptions.removeAt(index);
    });
  }

  // ===================== 发布 =====================

  /// 上传单媒体（视频/音频/文件），带进度。失败时置 failed 并 rethrow。
  Future<void> _uploadMedia() async {
    setState(() {
      _mediaStatus = _UploadStatus.uploading;
      _mediaProgress = 0;
      _uploadLabel = '上传 0%';
    });
    void onProgress(double p) {
      if (!mounted) return;
      setState(() {
        _mediaProgress = p;
        _uploadLabel = '上传 ${(p * 100).round()}%';
      });
    }

    final svc = ColibriTimelineService.shared;
    try {
      int? mediaId;
      switch (_mediaType) {
        case 'video':
          mediaId = await svc.uploadVideo(_mediaPath!, onProgress: onProgress);
          break;
        case 'audio':
          mediaId = await svc.uploadAudio(_mediaPath!, onProgress: onProgress);
          break;
        case 'document':
          mediaId =
              await svc.uploadDocument(_mediaPath!, onProgress: onProgress);
          break;
      }
      if (mounted) {
        setState(() {
          _mediaStatus = _UploadStatus.uploaded;
          _mediaProgress = 1;
          _mediaServerId = mediaId;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _mediaStatus = _UploadStatus.failed);
      rethrow;
    }
  }

  Future<void> _publish() async {
    if (_publishing || !_hasContent) return;
    final content = _content.text.trim();

    if (_pollMode) {
      final options = _pollOptions
          .map((c) => c.text.trim())
          .where((o) => o.isNotEmpty)
          .toList();
      if (options.length < 2) {
        showColibriToast('完善投票',
            message: '至少需要填写 2 个选项',
            backgroundColor: cRed,
            colorText: Colors.white);
        return;
      }
      setState(() => _publishing = true);
      try {
        await ColibriTimelineService.shared.createPost(
          content: content,
          pollOptions: options,
          isSensitive: _isSensitive,
          isAiGenerated: _isAiGenerated,
        );
      } catch (e) {
        showColibriToast('发布失败',
            message: e.toString(),
            backgroundColor: cRed,
            colorText: Colors.white);
        if (mounted) setState(() => _publishing = false);
        return;
      }
    } else {
      setState(() {
        _publishing = true;
        _uploadLabel = null;
      });
      try {
        // 1) 逐张上传图片（已上传的跳过，失败即停并标红，用户可单张重试）
        if (_images.isNotEmpty) {
          final total = _images.length;
          var done = _images.where((e) => e.uploaded).length;
          for (var i = 0; i < _images.length; i++) {
            final item = _images[i];
            if (item.uploaded) continue;
            setState(() {
              item.status = _UploadStatus.uploading;
              item.progress = 0;
              _uploadLabel = '图片 ${done + 1}/$total';
            });
            try {
              final mediaId = await ColibriTimelineService.shared.uploadImage(
                item.path,
                onProgress: (p) {
                  if (mounted) setState(() => item.progress = p);
                },
              );
              if (!mounted) return;
              setState(() {
                item.status = _UploadStatus.uploaded;
                item.progress = 1;
                item.serverMediaId = mediaId;
              });
              done++;
            } catch (e) {
              if (!mounted) return;
              setState(() => item.status = _UploadStatus.failed);
              showColibriToast('图片上传失败',
                  message: '$e\n点击红色图片可单独重试',
                  backgroundColor: cRed,
                  colorText: Colors.white);
              setState(() => _publishing = false);
              return;
            }
          }
        } else if (_mediaPath != null &&
            _mediaStatus != _UploadStatus.uploaded) {
          // 2) 单媒体上传（带进度）
          await _uploadMedia();
        }
        // 3) 全部媒体就绪，草稿转正式帖
        if (mounted) setState(() => _uploadLabel = null);
        await ColibriTimelineService.shared.createPost(
          content: content,
          isSensitive: _isSensitive,
          isAiGenerated: _isAiGenerated,
        );
      } catch (e) {
        showColibriToast('发布失败',
            message: e.toString(),
            backgroundColor: cRed,
            colorText: Colors.white);
        if (mounted) setState(() => _publishing = false);
        return;
      }
    }
    Get.back();
    HapticManager.shared.success();
    showColibriToast('已发布',
        message: '帖子发布成功', backgroundColor: cGreen, colorText: Colors.white);
  }

  /// 单张图片重试（仅 failed 状态）。成功后不自动发布，用户点「发布」继续（自动跳过已上传）。
  Future<void> _retryImage(int index) async {
    if (_publishing) return;
    final item = _images[index];
    if (item.status != _UploadStatus.failed) return;
    setState(() {
      item.status = _UploadStatus.uploading;
      item.progress = 0;
    });
    try {
      final mediaId = await ColibriTimelineService.shared.uploadImage(
        item.path,
        onProgress: (p) {
          if (mounted) setState(() => item.progress = p);
        },
      );
      if (!mounted) return;
      setState(() {
        item.status = _UploadStatus.uploaded;
        item.progress = 1;
        item.serverMediaId = mediaId;
      });
      showColibriToast('上传成功',
          message: '点击「发布」完成发帖',
          backgroundColor: cGreen,
          colorText: Colors.white);
    } catch (e) {
      if (!mounted) return;
      setState(() => item.status = _UploadStatus.failed);
      showColibriToast('上传失败',
          message: e.toString(),
          backgroundColor: cRed,
          colorText: Colors.white);
    }
  }

  /// 单媒体重试：重传 + 直接发布。
  Future<void> _retryMedia() async {
    if (_publishing ||
        _mediaPath == null ||
        _mediaStatus != _UploadStatus.failed) return;
    setState(() => _publishing = true);
    try {
      await _uploadMedia();
      await ColibriTimelineService.shared.createPost(
        content: _content.text.trim(),
        isSensitive: _isSensitive,
        isAiGenerated: _isAiGenerated,
      );
    } catch (e) {
      showColibriToast('发布失败',
          message: e.toString(),
          backgroundColor: cRed,
          colorText: Colors.white);
      if (mounted) setState(() => _publishing = false);
      return;
    }
    Get.back();
    HapticManager.shared.success();
    showColibriToast('已发布',
        message: '帖子发布成功', backgroundColor: cGreen, colorText: Colors.white);
  }

  // ===================== 媒体预览 =====================

  /// 多图预览：3 列正方形网格。
  /// 每张独立显示上传态：上传中（黑遮罩+环形进度+底部进度条）/ 已上传（绿勾徽章）/
  /// 失败（红遮罩+点击重试）/ 待上传（可删除）。
  Widget _imageGridPreview() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _images.length,
            itemBuilder: (context, index) {
              final item = _images[index];
              return _ImageTile(
                item: item,
                onRemove: () => _removeImage(index),
                onRetry: () => _retryImage(index),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            '已选 ${_images.length}/$_maxImages 张图片',
            style: const TextStyle(fontSize: 12, color: cLightText),
          ),
        ],
      ),
    );
  }

  Widget _mediaPreview() {
    if (_images.isNotEmpty) return _imageGridPreview();
    if (_mediaPath == null) return const SizedBox.shrink();
    final icon = _mediaType == 'video'
        ? Icons.play_circle_outline_rounded
        : _mediaType == 'audio'
            ? Icons.graphic_eq_rounded
            : Icons.insert_drive_file_rounded;
    final typeLabel = _mediaType == 'video'
        ? '视频'
        : _mediaType == 'audio'
            ? '音频'
            : '文件';

    final card = Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
          color: cPrimarySoft, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration:
                    const BoxDecoration(color: cWhite, shape: BoxShape.circle),
                child: Icon(icon, color: cGreen, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_mediaName ?? '附件',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: cMainText)),
                    const SizedBox(height: 2),
                    Text('$typeLabel · ${_fmtBytes(_mediaFileSize)}',
                        style:
                            const TextStyle(fontSize: 12, color: cLightText)),
                  ],
                ),
              ),
            ],
          ),
          // 上传进度区（上传中 / 已上传 / 失败 三态）
          if (_mediaStatus == _UploadStatus.uploading)
            _MediaProgressSection(
                progress: _mediaProgress, fileSize: _mediaFileSize)
          else if (_mediaStatus == _UploadStatus.uploaded)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: cGreen, size: 16),
                  SizedBox(width: 5),
                  Text('已上传',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: cGreen,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            )
          else if (_mediaStatus == _UploadStatus.failed)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: cRed, size: 16),
                  SizedBox(width: 5),
                  Text('上传失败 · 点击卡片重试',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: cRed,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 失败态：整卡可点重试
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _mediaStatus == _UploadStatus.failed ? _retryMedia : null,
            child: card,
          ),
          if (_mediaStatus != _UploadStatus.uploading)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: _clearMedia,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 17),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===================== 投票编辑 UI =====================

  Widget _pollEditor() {
    final canAdd = _pollOptions.length < 10;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        ..._pollOptions.asMap().entries.map((e) {
          final index = e.key;
          final c = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: const BoxDecoration(
                      color: cPrimarySoft, shape: BoxShape.circle),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: cGreen),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: c,
                    maxLength: 100,
                    decoration: InputDecoration(
                      hintText: '选项 ${index + 1}',
                      hintStyle:
                          const TextStyle(color: cLightText, fontSize: 15),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: cLightBg,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      counterText: '',
                    ),
                  ),
                ),
                if (_pollOptions.length > 2)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _removePollOption(index),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.close_rounded,
                          color: cLightText, size: 19),
                    ),
                  ),
              ],
            ),
          );
        }),
        if (canAdd)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _addPollOption,
            child: Container(
              height: 46,
              margin: const EdgeInsets.only(bottom: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cPrimarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline_rounded,
                      color: cGreen, size: 19),
                  SizedBox(width: 6),
                  Text('添加选项',
                      style: TextStyle(
                          color: cGreen,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 6),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() => _pollMode = false);
            _syncHasContent();
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('取消使用投票',
                style: TextStyle(
                    fontSize: 13,
                    color: cLightText,
                    decoration: TextDecoration.underline)),
          ),
        ),
      ],
    );
  }

  // ===================== 页面 =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cWhite,
      appBar: AppBar(
        backgroundColor: cWhite,
        surfaceTintColor: cWhite,
        elevation: 0,
        title: const Text('发帖',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 17, color: cMainText)),
        leading: BackButton(color: cBlack, onPressed: () => Get.back()),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 身份行：头像 + 名字
                  Obx(_authorRow),
                  const SizedBox(height: 6),
                  // 正文输入（无边框大输入区，支持 @提及联想）
                  MentionField(
                    controller: _content,
                    hintText: _pollMode ? '投票问题…' : '分享你的想法…',
                    maxLines: null,
                    minLines: 3,
                    maxLength: 1000,
                    style: const TextStyle(
                        fontSize: 19, height: 1.5, color: cMainText),
                    hintStyle: const TextStyle(
                        color: cLightText, fontSize: 18, height: 1.5),
                    decoration: InputDecoration(
                      hintText: _pollMode ? '投票问题…' : '分享你的想法…',
                      hintStyle: const TextStyle(
                          color: cLightText, fontSize: 18, height: 1.5),
                      border: InputBorder.none,
                      counterText: '',
                    ),
                  ),
                  // 字数（软提示，1000 上限，实时跟随输入更新）
                  Align(
                    alignment: Alignment.centerRight,
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _content,
                      builder: (context, value, _) => Text(
                        '${value.text.length}/1000',
                        style: const TextStyle(fontSize: 11, color: cLightText),
                      ),
                    ),
                  ),
                  // 标记提示（对齐网页端：敏感时显示警示条，AI 时显示生成提示）
                  if (_isSensitive) _sensitiveNotice(),
                  if (_isAiGenerated)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 14, color: Color(0xFFF59E0B)),
                          SizedBox(width: 4),
                          Text('AI 生成',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFF59E0B))),
                        ],
                      ),
                    ),
                  // 媒体预览 / 投票编辑
                  if (_pollMode) _pollEditor() else _mediaPreview(),
                ],
              ),
            ),
          ),
          // 底部固定工具栏
          _buildToolbar(),
        ],
      ),
    );
  }

  /// 身份行：头像 + 名字 + @handle（发帖人）。
  Widget _authorRow() {
    final user = SessionManager.shared.colibriUserRx;
    final name = user['name']?.toString() ?? '';
    final username = user['username']?.toString() ?? '';
    final avatar = user['avatar_url']?.toString();
    return Row(
      children: [
        MyCachedProfileImage(
          imageUrl: avatar,
          width: 44,
          height: 44,
          fullName: name,
          cornerRadius: 22,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: cMainText)),
            if (username.isNotEmpty)
              Text('@$username',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: cLightText)),
          ],
        ),
      ],
    );
  }

  /// 敏感内容警示条（对齐网页端 SensitivePostTape 的橙色警示语义，移动端信息条样式）。
  Widget _sensitiveNotice() {
    const amber = Color(0xFFD97706);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6E5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: amber.withValues(alpha: 0.35)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, size: 18, color: amber),
            SizedBox(width: 8),
            Expanded(
              child: Text('此帖子将标记为敏感内容',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: cDarkText)),
            ),
          ],
        ),
      ),
    );
  }

  /// 标记功能行：文本格式速查 + 敏感内容开关 + AI 生成开关（对齐网页端发布器 moreMenu）。
  Widget _buildMarksRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          _MarkChip(
            icon: Icons.text_fields_rounded,
            label: '格式',
            active: false,
            onTap: () => showMarkdownCheatSheet(context),
          ),
          const SizedBox(width: 8),
          _MarkChip(
            icon: Icons.warning_amber_rounded,
            label: '敏感内容',
            active: _isSensitive,
            onTap: () {
              setState(() => _isSensitive = !_isSensitive);
              HapticManager.shared.selection();
            },
          ),
          const SizedBox(width: 8),
          _MarkChip(
            icon: Icons.auto_awesome_rounded,
            label: 'AI 生成',
            active: _isAiGenerated,
            onTap: () {
              setState(() => _isAiGenerated = !_isAiGenerated);
              HapticManager.shared.selection();
            },
          ),
        ],
      ),
    );
  }

  /// 底部工具栏：标记功能行 + 附件图标组 + 发布胶囊按钮。
  Widget _buildToolbar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 14, 10),
        decoration: const BoxDecoration(
          color: cWhite,
          border: Border(top: BorderSide(color: cLightBg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMarksRow(),
            Row(
              children: [
                if (!_pollMode) ...[
                  _ToolIcon(icon: Icons.image_rounded, onTap: _pickImage),
                  _ToolIcon(icon: Icons.videocam_rounded, onTap: _pickVideo),
                  _ToolIcon(icon: Icons.graphic_eq_rounded, onTap: _pickAudio),
                  _ToolIcon(
                      icon: Icons.insert_drive_file_rounded,
                      onTap: _pickDocument),
                ],
                _ToolIcon(
                  icon: Icons.poll_rounded,
                  active: _pollMode,
                  onTap: () {
                    setState(() => _pollMode = !_pollMode);
                    _syncHasContent();
                  },
                ),
                const Spacer(),
                _PublishButton(
                  enabled: _hasContent && !_publishing,
                  loading: _publishing,
                  progressText: _uploadLabel,
                  onTap: _publish,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 图片网格单元：按状态渲染（待上传可删 / 上传中进度 / 已上传绿勾 / 失败点击重试）。
class _ImageTile extends StatelessWidget {
  final _ImageItem item;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  const _ImageTile(
      {required this.item, required this.onRemove, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final status = item.status;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: status == _UploadStatus.failed ? onRetry : null,
      child: Stack(
        children: [
          // 图片
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(item.path), fit: BoxFit.cover),
            ),
          ),
          // 上传中：黑遮罩 + 环形进度 + 百分比 + 底部进度条
          if (status == _UploadStatus.uploading) ...[
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            value: item.progress,
                            strokeWidth: 3,
                            strokeCap: StrokeCap.round,
                            color: cPrimary,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${(item.progress * 100).round()}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12)),
                child: SizedBox(
                  height: 4,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      return Stack(
                        children: [
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: (w * item.progress).clamp(0.0, w),
                            child: const ColoredBox(
                                color: cPrimary, child: SizedBox.expand()),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
          // 已上传：左上角绿勾徽章（不可移除）
          if (status == _UploadStatus.uploaded)
            Positioned(
              top: 7,
              left: 7,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: cPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Icon(Icons.check_rounded, color: cBlack, size: 15),
              ),
            ),
          // 失败：红遮罩 + 重试提示
          if (status == _UploadStatus.failed)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ColoredBox(
                  color: cRed.withValues(alpha: 0.42),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.refresh_rounded,
                              color: cRed, size: 17),
                        ),
                        const SizedBox(height: 5),
                        const Text('点击重试',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // 删除按钮（非上传中均可删；已上传的会同步撤回服务器草稿）
          if (status != _UploadStatus.uploading)
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 15),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 单媒体（视频/音频/文件）上传进度区：白色 4px 轨道 + 绿色填充 + 字节/百分比双行。
class _MediaProgressSection extends StatelessWidget {
  final double progress; // 0~1
  final int fileSize;

  const _MediaProgressSection({required this.progress, required this.fileSize});

  String _fmtBytes(int b) {
    const mb = 1024 * 1024;
    const gb = mb * 1024;
    if (b >= gb) return '${(b / gb).toStringAsFixed(1)}GB';
    if (b >= mb) return '${(b / mb).toStringAsFixed(1)}MB';
    if (b >= 1024) return '${(b / 1024).toStringAsFixed(0)}KB';
    return '${b}B';
  }

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    final sent = (fileSize * p).round();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 进度轨道：白底 + 绿色填充。
          // 注意：不能直接用 FractionallySizedBox(widthFactor, child: ColoredBox())——
          // 无 child 的 ColoredBox 在 loose 高度约束下高为 0（FSB 的 child 约束透传高度），
          // 填充会整体不可见（只显示白色轨道）。用 LayoutBuilder+Positioned 显式宽高。
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 5,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  return Stack(
                    children: [
                      const ColoredBox(
                          color: Colors.white, child: SizedBox.expand()),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: (w * p).clamp(0.0, w),
                        child: const ColoredBox(
                            color: cPrimary, child: SizedBox.expand()),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                '${_fmtBytes(sent)} / ${_fmtBytes(fileSize)}',
                style: const TextStyle(fontSize: 11.5, color: cLightText),
              ),
              const Spacer(),
              Text(
                '${(p * 100).round()}%',
                style: const TextStyle(
                    fontSize: 12, color: cGreen, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 标记功能胶囊（格式/敏感/AI）：软绿圆角底，激活时绿底黑字。
class _MarkChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _MarkChip(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? cPrimary : cPrimarySoft,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: active ? cBlack : cGreen),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? cBlack : cGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 工具栏附件图标（软绿圆底）。
class _ToolIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  const _ToolIcon(
      {required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: active ? cPrimary : cPrimarySoft,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: active ? cBlack : cGreen, size: 21),
      ),
    );
  }
}

/// 发布按钮：有内容时绿底黑字，无内容置灰；上传时显示进度文案。
class _PublishButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final String? progressText; // 「图片 2/5」/「上传 46%」
  final VoidCallback onTap;

  const _PublishButton({
    required this.enabled,
    required this.loading,
    required this.onTap,
    this.progressText,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? cPrimary : cLightBg,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: enabled ? onTap : null,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: loading
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.2, color: Colors.white)),
                      const SizedBox(width: 8),
                      Text(
                        progressText ?? '发布中',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ],
                  )
                : Text(
                    '发布',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: enabled ? Colors.white : cLightIcon,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
