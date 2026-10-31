import 'package:flutter/foundation.dart' show listEquals, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:untitled/common/api_service/colibri_messenger_service.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';
import 'package:untitled/common/api_service/colibri_guest_service.dart';
import 'package:untitled/common/api_service/colibri_api.dart';
import 'package:untitled/common/api_service/colibri_social_service.dart';
import 'package:untitled/common/api_service/colibri_timeline_service.dart';
import 'package:untitled/common/managers/guest_session.dart';
import 'package:untitled/common/managers/haptic_manager.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/widgets/colibri_ui.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:untitled/common/widgets/colibri_skeleton.dart';
import 'package:untitled/common/widgets/guest_auth_sheet.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/localization/allLanguages.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/colibri_post_models.dart';
import 'package:untitled/models/colibri_social_models.dart';
import 'package:untitled/screens/colibri_chat/chat_detail_screen.dart';
import 'package:untitled/screens/colibri_feed/colibri_post_card.dart';
import 'package:untitled/screens/colibri_feed/colibri_post_detail_screen.dart';
import 'package:untitled/screens/colibri_settings/colibri_settings_screen.dart';
import 'package:untitled/screens/colibri_social/colibri_bookmarks_view.dart';
import 'package:untitled/screens/colibri_social/colibri_connections_screen.dart';
import 'package:untitled/screens/colibri_social/colibri_edit_profile_screen.dart';
import 'package:untitled/screens/colibri_social/colibri_notifications_screen.dart';
import 'package:untitled/screens/profile_screen/full_image_screen.dart';
import 'package:untitled/utilities/const.dart';
import 'package:url_launcher/url_launcher.dart';

/// 个人主页（我的/他人通用）。
/// 设计：沉浸式封面 + 悬浮头像 + 帖子/收藏/媒体/信息标签页（对齐网页端 ProfileIndex；
/// 收藏为本人书签数据，仅 isOwner 显示）。
class ColibriProfileScreen extends StatefulWidget {
  final String? username; // 传 username 查看他人；null 查看当前登录用户

  const ColibriProfileScreen({super.key, this.username}) : _testProfile = null;

  @visibleForTesting
  const ColibriProfileScreen.withTestProfile({
    super.key,
    required ColibriProfile profile,
  })  : username = null,
        _testProfile = profile;

  final ColibriProfile? _testProfile;

  @override
  State<ColibriProfileScreen> createState() => _ColibriProfileScreenState();
}

class _ColibriProfileScreenState extends State<ColibriProfileScreen>
    with SingleTickerProviderStateMixin {
  // ===== 布局常量 =====
  static const double _appBarH = 56; // AppBar 工具区高度
  static const double _coverH = 240; // 封面高度（屏幕顶 → 头像中线）
  static const double _avatarD = 94;
  static const double _overlap = 47; // 头像下半段高度（中线 → AppBar 底边）
  static const double _padH = 18;

  double _statusBarH(BuildContext context) =>
      MediaQuery.of(context).padding.top;

  TabController? _tabController;

  // ===== 标签结构：帖子 / [收藏] / 媒体 / [信息]（收藏仅本人；访客仅有 帖子/媒体）=====
  bool get _isGuestView => GuestSession.i.isGuest && widget.username != null;
  bool get _hasBookmarksTab => _profile?.isOwner ?? false;
  int get _tabCount => _isGuestView ? 2 : (_hasBookmarksTab ? 4 : 3);
  int get _mediaIndex => _isGuestView ? 1 : (_hasBookmarksTab ? 2 : 1);
  int get _infoIndex => _hasBookmarksTab ? 3 : 2;
  List<String> get _tabLabels => [
        '帖子',
        if (_hasBookmarksTab) '收藏',
        '媒体',
        if (!_isGuestView) '信息',
      ];

  ColibriProfile? _profile;
  bool _loading = true;
  String? _loadError;
  int _loadRevision = 0;
  bool _translatingBio = false;
  bool _showBioTranslation = false;
  String? _translatedBio;
  String? _bioSourceLanguage;
  String? _bioTranslationTarget;
  int _bioTranslationRequest = 0;

  String get _currentBioTranslationTarget =>
      ColibriTimelineService.translationTarget(
        Get.locale?.languageCode ??
            SessionManager.shared.getLang().language.languageCode,
      );

  void _resetBioTranslation() {
    _bioTranslationRequest++;
    _translatingBio = false;
    _showBioTranslation = false;
    _translatedBio = null;
    _bioSourceLanguage = null;
    _bioTranslationTarget = _currentBioTranslationTarget;
  }

  // 帖子 tab
  final List<ColibriPost> _posts = [];
  bool _loadingPosts = false;
  bool _hasMorePosts = true;
  int? _postsCursor;

  // 媒体 tab（filter type=media，非纯文本帖）
  final List<ColibriPost> _media = [];
  bool _loadingMedia = false;
  bool _hasMoreMedia = true;
  int? _mediaCursor;
  bool _mediaLoaded = false; // 首次进入该 tab 才加载

  // 信息 tab（profile/details）
  ColibriProfileDetails? _details;
  bool _loadingDetails = false;
  bool _detailsLoaded = false;
  bool _detailsFailed = false;

  @override
  void initState() {
    super.initState();
    _bioTranslationTarget = _currentBioTranslationTarget;
    final testProfile = widget._testProfile;
    if (testProfile != null) {
      _profile = testProfile;
      _loading = false;
      _ensureTabController();
      _detailsLoaded = true;
      return;
    }
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bioTranslationTarget != _currentBioTranslationTarget) {
      _resetBioTranslation();
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  /// 按资料身份（是否本人）确保 TabController 长度正确（资料加载后可能从 3 → 4）。
  void _ensureTabController() {
    final count = _tabCount;
    if (_tabController?.length == count) return;
    final old = _tabController;
    final controller = TabController(length: count, vsync: this);
    controller.addListener(() {
      if (!mounted || controller.indexIsChanging) return;
      if (identical(_tabController, controller)) {
        _onTabVisited(controller.index);
      }
    });
    _tabController = controller;
    old?.dispose();
  }

  /// 懒加载：收藏 / 媒体 / 信息 tab 首次进入时拉取（收藏页自行注册控制器并缓存秒开）。
  void _onTabVisited(int index) {
    if (_profile == null) return;
    if (index == _mediaIndex && !_mediaLoaded) {
      _loadMedia(reset: true);
    } else if (index == _infoIndex && !_detailsLoaded && !_loadingDetails) {
      _loadDetails();
    }
  }

  Future<void> _load({bool silent = false}) async {
    final revision = ++_loadRevision;
    final stopwatch = Stopwatch()..start();
    Loggers.info(
        'profile.load.start revision=$revision username=${widget.username ?? "me"} guest=${GuestSession.i.isGuest} silent=$silent');
    if (mounted) {
      setState(() {
        if (!silent) _loading = true;
        _loadError = null;
        _loadingPosts = false;
        _loadingMedia = false;
        _loadingDetails = false;
      });
    }
    try {
      // 访客查看他人主页：走 guest/v1 脱敏端点（无「我的」访客主页，那由独立引导页承载）
      if (GuestSession.i.isGuest) {
        final username = _normaliseUsername(widget.username);
        if (username == null) {
          throw Exception(LKeys.missingUserInfo.tr);
        }
        final profile = await ColibriGuestService.shared.fetchProfile(username);
        if (!_isCurrent(revision)) return;
        setState(() => _replaceProfile(profile));
        _ensureTabController();
        Loggers.info(
            'profile.load.success revision=$revision id=${profile.id} username=${profile.username} owner=${profile.isOwner} tabs=$_tabCount elapsedMs=${stopwatch.elapsedMilliseconds}');
        _hasMorePosts = true;
        _loadPosts(reset: true);
        _mediaLoaded = false;
        _detailsLoaded = true; // 访客无「信息」tab，禁止拉取详情
        _onTabVisited(_tabController?.index ?? 0);
        return;
      }

      var cachedUser = _cachedUser();
      if (widget.username == null && _needsUserRefresh(cachedUser)) {
        final user = await ColibriApi.shared.fetchBootstrapUser();
        if (!_isCurrent(revision)) return;
        if (user != null) {
          SessionManager.shared.setColibriUser(user);
          cachedUser = user;
        }
      }

      final requestedUsername = _normaliseUsername(widget.username);
      final cachedUsername = _normaliseUsername(_usernameFromUser(cachedUser));
      final canUseCachedUser = widget.username == null &&
          cachedUser != null &&
          cachedUsername != null;
      if (canUseCachedUser) {
        setState(() {
          _replaceProfile(_profileFromUser(cachedUser!));
          _loading = false;
        });
        _ensureTabController();
        _hasMorePosts = true;
        _loadPosts(reset: true);
      }

      final username =
          requestedUsername ?? (canUseCachedUser ? cachedUsername : null);
      if (username != null) {
        final profile =
            await ColibriSocialService.shared.fetchProfile(username);
        if (!_isCurrent(revision)) return;
        setState(() => _replaceProfile(profile));
      }
      if (_profile == null && (username == null || username.isEmpty)) {
        throw Exception(LKeys.accountInfoUnavailable.tr);
      }
      if (_profile != null) {
        // 身份确定后（isOwner 可能变化）创建稳定的标签结构
        _ensureTabController();
        // 各 tab 数据复位，按需重新拉取
        _hasMorePosts = true;
        _loadPosts(reset: true);
        _mediaLoaded = false;
        _detailsLoaded = false;
        _details = null;
        _onTabVisited(_tabController?.index ?? 0);
      }
    } catch (e) {
      Loggers.error(
          'profile.load.error revision=$revision username=${widget.username ?? "me"} elapsedMs=${stopwatch.elapsedMilliseconds} error=$e');
      if (_isCurrent(revision) && _profile == null) {
        final message = e.toString().replaceFirst('Exception: ', '').trim();
        setState(() {
          _loadError = message.isEmpty ? LKeys.profileLoadFailed.tr : message;
        });
      }
    } finally {
      if (_isCurrent(revision) && !silent) setState(() => _loading = false);
      Loggers.info(
          'profile.load.finish revision=$revision current=${_isCurrent(revision)} elapsedMs=${stopwatch.elapsedMilliseconds} loading=$_loading hasProfile=${_profile != null} hasError=${_loadError != null}');
    }
  }

  bool _isCurrent(int revision) => mounted && revision == _loadRevision;

  void _replaceProfile(ColibriProfile profile) {
    if (_profile?.id != profile.id || _profile?.bio != profile.bio) {
      _resetBioTranslation();
    }
    _profile = profile;
  }

  Future<void> _toggleBioTranslation() async {
    final profile = _profile;
    if (profile == null || profile.bio.trim().isEmpty) return;

    final targetNow = _currentBioTranslationTarget;
    if (_bioTranslationTarget != targetNow) _resetBioTranslation();
    if (_translatingBio) return;
    if (GuestSession.i.isGuest) {
      AuthGate.requireLogin(() {}, feature: LKeys.translate.tr);
      return;
    }
    if (_translatedBio != null) {
      setState(() => _showBioTranslation = !_showBioTranslation);
      return;
    }

    final request = ++_bioTranslationRequest;
    final profileId = profile.id;
    final bio = profile.bio;
    final target = targetNow;
    bool isCurrent() =>
        mounted &&
        request == _bioTranslationRequest &&
        _profile?.id == profileId &&
        _profile?.bio == bio &&
        target == _currentBioTranslationTarget;

    setState(() => _translatingBio = true);
    try {
      final result = await ColibriTimelineService.shared.translateBio(
        profileId: profileId,
        text: bio,
        target: target,
      );
      if (!isCurrent()) return;
      setState(() {
        _translatedBio = result.translatedText;
        _bioSourceLanguage = result.sourceLanguage;
        _showBioTranslation = true;
      });
    } catch (e) {
      if (isCurrent()) {
        showColibriToast(LKeys.translationFailed.tr,
            message: e.toString(),
            backgroundColor: cRed,
            colorText: Colors.white);
      }
    } finally {
      if (isCurrent()) setState(() => _translatingBio = false);
    }
  }

  String? _normaliseUsername(String? username) {
    if (username == null) return null;
    final value = username.trim().replaceFirst(RegExp(r'^@'), '');
    return value.isEmpty ? null : value;
  }

  Map<String, dynamic>? _cachedUser() => SessionManager.shared.getColibriUser();

  String? _usernameFromUser(Map<String, dynamic>? user) =>
      user?['username']?.toString();

  bool _needsUserRefresh(Map<String, dynamic>? user) =>
      user == null || _normaliseUsername(_usernameFromUser(user)) == null;

  ColibriProfile _profileFromUser(Map<String, dynamic> user) {
    final meta = user['meta'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(user['meta'] as Map<String, dynamic>)
        : <String, dynamic>{};
    meta['is_owner'] = true;
    return ColibriProfile.fromJson({...user, 'meta': meta});
  }

  // ===================== 列表加载 =====================

  Future<void> _loadPosts({bool reset = false}) async {
    if (_profile == null || _loadingPosts || (!_hasMorePosts && !reset)) return;
    final revision = _loadRevision;
    final profileId = _profile!.id;
    if (!mounted) return;
    setState(() => _loadingPosts = true);
    try {
      final list = _isGuestView
          ? await ColibriGuestService.shared.fetchProfilePosts(
              _profile!.username,
              cursor: reset ? null : _postsCursor,
              type: 'posts',
            )
          : await ColibriSocialService.shared.fetchProfilePosts(
              _profile!.id,
              cursor: reset ? null : _postsCursor,
              type: 'posts',
            );
      if (!_isCurrent(revision) || _profile?.id != profileId) return;
      setState(() {
        if (reset) {
          _posts
            ..clear()
            ..addAll(list);
          _postsCursor = null;
          _hasMorePosts = true;
        } else {
          _posts.addAll(list);
        }
        if (list.isNotEmpty) {
          _postsCursor = list.last.id;
        } else {
          _hasMorePosts = false;
        }
      });
    } catch (_) {
      if (_isCurrent(revision) && _profile?.id == profileId) {
        _hasMorePosts = false;
      }
    } finally {
      if (_isCurrent(revision) && _profile?.id == profileId) {
        setState(() => _loadingPosts = false);
      }
    }
  }

  Future<void> _loadMedia({bool reset = false}) async {
    if (_profile == null || _loadingMedia || (!_hasMoreMedia && !reset)) return;
    final revision = _loadRevision;
    final profileId = _profile!.id;
    if (!mounted) return;
    setState(() => _loadingMedia = true);
    try {
      final list = _isGuestView
          ? await ColibriGuestService.shared.fetchProfilePosts(
              _profile!.username,
              cursor: reset ? null : _mediaCursor,
              type: 'media',
            )
          : await ColibriSocialService.shared.fetchProfilePosts(
              _profile!.id,
              cursor: reset ? null : _mediaCursor,
              type: 'media',
            );
      if (!_isCurrent(revision) || _profile?.id != profileId) return;
      setState(() {
        if (reset) {
          _media
            ..clear()
            ..addAll(list);
          _mediaCursor = null;
          _hasMoreMedia = true;
        } else {
          _media.addAll(list);
        }
        if (list.isNotEmpty) {
          _mediaCursor = list.last.id;
        } else {
          _hasMoreMedia = false;
        }
      });
    } catch (_) {
      if (_isCurrent(revision) && _profile?.id == profileId) {
        _hasMoreMedia = false;
      }
    } finally {
      if (_isCurrent(revision) && _profile?.id == profileId) {
        _mediaLoaded = true;
        setState(() => _loadingMedia = false);
      }
    }
  }

  Future<void> _loadDetails() async {
    if (_profile == null || _loadingDetails) return;
    final revision = _loadRevision;
    final profileId = _profile!.id;
    if (!mounted) return;
    setState(() {
      _loadingDetails = true;
      _detailsFailed = false;
    });
    try {
      final details =
          await ColibriSocialService.shared.fetchProfileDetails(profileId);
      if (!_isCurrent(revision) || _profile?.id != profileId) return;
      setState(() => _details = details);
    } catch (_) {
      if (_isCurrent(revision) && _profile?.id == profileId) {
        _detailsFailed = true;
      }
    } finally {
      if (_isCurrent(revision) && _profile?.id == profileId) {
        _detailsLoaded = true;
        setState(() => _loadingDetails = false);
      }
    }
  }

  // ===================== 关系操作 =====================

  Future<void> _toggleFollow() async {
    final profile = _profile;
    if (profile == null) return;
    try {
      final result = await ColibriSocialService.shared.toggleFollow(profile.id);
      setState(() {
        _profile = profile.copyWith(
          isFollowing: result.following,
          isFollowRequested: result.requested,
          followersCount: profile.followersCount +
              (result.following ? 1 : (profile.followersCount > 0 ? -1 : 0)),
        );
      });
      if (result.requested) {
        showColibriToast('已发送关注请求',
            message: '对方批准后即可成为粉丝',
            backgroundColor: cPrimary,
            colorText: Colors.white);
      } else if (!result.following && profile.isFollowRequested) {
        showColibriToast('已取消关注请求',
            message: '', backgroundColor: cLightBg, colorText: cMainText);
      }
      HapticManager.shared.light();
    } catch (e) {
      showColibriToast('操作失败',
          message: e.toString(),
          backgroundColor: cRed,
          colorText: Colors.white);
    }
  }

  Future<void> _openChat() async {
    final profile = _profile;
    if (profile == null) return;
    // 对方「谁能私信我」设置不允许时直接提示，无需请求服务器
    if (!profile.canMessage) {
      showColibriToast('无法发起私信',
          message: '对方已限制谁能私信', backgroundColor: cRed, colorText: Colors.white);
      return;
    }
    try {
      final chatId =
          await ColibriMessengerService.shared.createChat(profile.id);
      if (chatId.isNotEmpty) {
        Get.to(
            () => ChatDetailScreen(
                  chatId: chatId,
                  title: profile.name,
                  avatarUrl: profile.avatarUrl,
                  peerUsername: profile.username,
                  peerId: profile.id,
                ),
            opaque: false);
      }
    } catch (e) {
      showColibriToast('无法发起聊天',
          message: e.toString(),
          backgroundColor: cRed,
          colorText: Colors.white);
    }
  }

  Future<void> _toggleBlock() async {
    final profile = _profile;
    if (profile == null) return;
    final wasBlocked = profile.isBlocked;
    final confirm = await showColibriConfirmDialog(
      context,
      icon:
          wasBlocked ? Icons.person_remove_alt_1_rounded : Icons.block_rounded,
      title: wasBlocked ? '解除拉黑' : '拉黑用户',
      message:
          wasBlocked ? '确定解除对 ${profile.name} 的拉黑？' : '确定拉黑 ${profile.name}？',
      confirmText: wasBlocked ? '解除拉黑' : '拉黑',
      danger: !wasBlocked,
      onConfirm: () async {
        try {
          final blocked =
              await ColibriSocialService.shared.toggleBlock(profile.id);
          if (!mounted) return false;
          setState(() => _profile = profile.copyWith(isBlocked: blocked));
          showColibriToast(blocked ? '已拉黑' : '已解除拉黑',
              message: '', backgroundColor: cGreen, colorText: Colors.white);
          return true;
        } catch (e) {
          if (mounted) {
            showColibriToast('操作失败',
                message: e.toString(),
                backgroundColor: cRed,
                colorText: Colors.white);
          }
          return false;
        }
      },
    );
    if (!confirm) return;
  }

  Future<void> _toggleMute() async {
    final profile = _profile;
    if (profile == null) return;
    try {
      final muted = await ColibriSocialService.shared.toggleMute(profile.id);
      setState(() => _profile = profile.copyWith(isMuted: muted));
      showColibriToast(muted ? '已静音' : '已取消静音',
          message: muted ? '将不再收到该用户的通知' : '',
          backgroundColor: cGreen,
          colorText: Colors.white);
    } catch (e) {
      showColibriToast('操作失败',
          message: e.toString(),
          backgroundColor: cRed,
          colorText: Colors.white);
    }
  }

  Future<void> _reportProfile() async {
    final profile = _profile;
    if (profile == null || !profile.canReport) return;

    try {
      final info =
          await ColibriTimelineService.shared.fetchReportReasons(type: 'user');
      if (!mounted || info.reasons.isEmpty) return;

      await showColibriBottomSheet<void>(
        Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: ColibriReportSheet(
            reportType: 'user',
            reportableId: profile.id,
            info: info,
          ),
        ),
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        constraints: const BoxConstraints(maxHeight: 520),
      );
    } catch (e) {
      if (!mounted) return;
      showColibriToast('举报失败',
          message: e.toString(),
          backgroundColor: cRed,
          colorText: Colors.white);
    }
  }

  /// 主页链接（对齐网页端 /@username 路由）。
  String get _profileLink {
    final base = colibriApiBase.endsWith('/api/')
        ? colibriApiBase.substring(0, colibriApiBase.length - 5)
        : colibriApiBase;
    return '$base/@${_profile?.username ?? ''}';
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: _profileLink));
    showColibriToast('已复制',
        message: _profileLink,
        backgroundColor: cGreen,
        colorText: Colors.white,
        duration: const Duration(seconds: 1));
  }

  Future<void> _openUrl(String url) async {
    var target = url;
    if (!target.startsWith('http://') && !target.startsWith('https://')) {
      target = 'https://$target';
    }
    final uri = Uri.tryParse(target);
    if (uri == null) {
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      showColibriToast('无法打开链接',
          message: url, backgroundColor: cRed, colorText: Colors.white);
    }
  }

  /// 他人主页更多菜单：复制链接 / 举报 / 静音 / 屏蔽。访客仅可复制链接（关系操作需登录）。
  void _showMoreMenu() {
    final profile = _profile;
    if (profile == null) return;
    if (_isGuestView) {
      showColibriSheet(
        context,
        title: '主页操作',
        items: [
          ColibriSheetItem(
            icon: Icons.link_rounded,
            label: '复制主页链接',
            onTap: _copyLink,
          ),
        ],
      );
      return;
    }
    showColibriSheet(
      context,
      title: '主页操作',
      items: [
        ColibriSheetItem(
          icon: Icons.link_rounded,
          label: '复制主页链接',
          onTap: _copyLink,
        ),
        if (profile.canReport)
          ColibriSheetItem(
            icon: Icons.report_gmailerrorred_rounded,
            label: '举报用户',
            onTap: _reportProfile,
            danger: true,
          ),
        ColibriSheetItem(
          icon: profile.isMuted
              ? Icons.volume_off_rounded
              : Icons.notifications_off_rounded,
          label: profile.isMuted ? '取消静音' : '静音',
          subtitle: profile.isMuted ? null : '不再收到该用户的通知',
          onTap: _toggleMute,
        ),
        ColibriSheetItem(
          icon: profile.isBlocked
              ? Icons.person_off_rounded
              : Icons.block_rounded,
          label: profile.isBlocked ? '解除屏蔽' : '屏蔽',
          subtitle: '屏蔽后双方将无法看到对方、无法私信',
          onTap: _toggleBlock,
          danger: !profile.isBlocked,
        ),
      ],
    );
  }

  // ===================== 页面结构 =====================

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: cWhite,
      body: _loading
          ? const Center(
              key: ValueKey('profile-loading'),
              child: CircularProgressIndicator(color: cPrimary),
            )
          : profile == null
              ? KeyedSubtree(
                  key: const ValueKey('profile-error'),
                  child: _buildLoadError(),
                )
              : KeyedSubtree(
                  key: const ValueKey('profile-content'),
                  child: NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) => [
                      // 封面即 AppBar：封面延展到状态栏下，头像也放在 flexibleSpace 内。
                      // 关键：pinned AppBar 绘制在后续 sliver 之上，头像若从头部块向上探出，
                      // 上半段会被 AppBar 的白色背景/封面层盖住（只显示半个的根因）。
                      SliverAppBar(
                        pinned: true,
                        backgroundColor: cWhite,
                        surfaceTintColor: Colors.transparent,
                        elevation: 0,
                        expandedHeight: _coverH + _overlap, // 封面 + 头像下半段
                        collapsedHeight: _statusBarH(context) + _appBarH,
                        toolbarHeight: _appBarH,
                        centerTitle: false,
                        titleSpacing: 0,
                        leading: const SizedBox.shrink(),
                        automaticallyImplyLeading: false,
                        flexibleSpace: _ProfileCoverAppBar(
                          statusBarHeight: _statusBarH(context),
                          toolbarHeight: _appBarH,
                          coverHeight: _coverH,
                          avatarOverlap: _overlap,
                          padH: _padH,
                          username: profile.username.isEmpty
                              ? '主页'
                              : profile.username,
                          isOwner: profile.isOwner,
                          onNotifications: () => Get.to(
                              () => const ColibriNotificationsScreen(),
                              opaque: false),
                          onSettings: () => Get.to(
                              () => const ColibriSettingsScreen(),
                              opaque: false),
                          onMore: _showMoreMenu,
                          showBack: canPop,
                          cover: profile.coverUrl != null &&
                                  profile.coverUrl!.isNotEmpty
                              ? MyCachedImage(
                                  imageUrl: profile.coverUrl,
                                  width: double.infinity,
                                  height: _coverH)
                              : null,
                          avatar: _buildAvatar(profile),
                        ),
                      ),
                      // 身份信息（头像在上方 AppBar 内，底边与本块顶线相接）
                      SliverToBoxAdapter(child: _buildHeader(profile)),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _ProfileTabBarDelegate(_tabController!,
                            labels: _tabLabels),
                      ),
                    ],
                    body: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPostsTab(),
                        if (_hasBookmarksTab) const ColibriBookmarksView(),
                        _buildMediaTab(),
                        // 访客无「信息」tab（信息/联系方式为登录后可见）
                        if (!_isGuestView) _buildInfoTab(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 44, color: cLightIcon),
            const SizedBox(height: 12),
            Text(
              _loadError ?? LKeys.profileLoadFailed.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(color: cLightText, fontSize: 14),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => _load(),
              child: Text(
                LKeys.retry.tr,
                style: const TextStyle(
                  color: cHashtagColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== 头部 =====================

  Widget _buildHeader(ColibriProfile profile) {
    // 头像在 AppBar 的 flexibleSpace 内（底边贴本块顶线），这里只渲染身份信息
    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 14, _padH, 0),
      child: _buildIdentity(profile),
    );
  }

  /// 悬浮头像（传入 AppBar flexibleSpace，绘制在封面之上，随收缩淡出）。
  Widget _buildAvatar(ColibriProfile profile) {
    final avatarUrl = profile.avatarUrl;
    return GestureDetector(
      onTap: () {
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          Get.to(
              () => FullImageScreen(
                  image: avatarUrl, tag: 'profile_avatar_${profile.id}'),
              opaque: false);
        }
      },
      child: Container(
        width: _avatarD,
        height: _avatarD,
        padding: const EdgeInsets.all(3.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cWhite,
          boxShadow: [
            BoxShadow(
                color: cBlack.withValues(alpha: 0.14),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        child: MyCachedProfileImage(
          imageUrl: avatarUrl,
          width: _avatarD - 7,
          height: _avatarD - 7,
          fullName: profile.name,
          cornerRadius: (_avatarD - 7) / 2,
        ),
      ),
    );
  }

  Widget _buildIdentity(ColibriProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(profile.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: cMainText,
                      height: 1.2)),
            ),
            if (profile.verified) ...[
              const SizedBox(width: 5),
              const Icon(Icons.verified_rounded, color: cBlueTick, size: 20),
            ],
          ],
        ),
        if (profile.caption.isNotEmpty &&
            profile.caption != '@${profile.username}') ...[
          const SizedBox(height: 3),
          Text(profile.caption,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500, color: cDarkText)),
        ],
        const SizedBox(height: 2),
        Text('@${profile.username}',
            style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: cLightText,
                letterSpacing: 0.2)),
        if (profile.bio.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
              _showBioTranslation && _translatedBio != null
                  ? _translatedBio!
                  : profile.bio,
              style: const TextStyle(
                  fontSize: 13, color: cDarkText, height: 1.35)),
          const SizedBox(height: 3),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _translatingBio ? null : _toggleBioTranslation,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                foregroundColor: cHashtagColor,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              icon: _translatingBio
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.8, color: cHashtagColor),
                    )
                  : const Icon(Icons.translate_rounded, size: 16),
              label: Text(
                _translatingBio
                    ? ''
                    : (_showBioTranslation &&
                            (_bioSourceLanguage?.isNotEmpty ?? false)
                        ? LKeys.translatedFrom.trParams({
                            'language':
                                ColibriTimelineService.translationLanguageName(
                                    _bioSourceLanguage!),
                          })
                        : (_showBioTranslation
                            ? LKeys.showOriginal.tr
                            : LKeys.translate.tr)),
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
          ),
        ],
        if ((profile.website ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openUrl(profile.website!),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.link_rounded, size: 15, color: cHashtagColor),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    profile.website!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: cHashtagColor,
                        decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ],
        // 位置 + 加入时间（对齐网页 ProfileOverview）
        if (profile.location.isNotEmpty ||
            profile.joinDateFormatted.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (profile.location.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 15, color: cLightIcon),
                    const SizedBox(width: 4),
                    Text(profile.location,
                        style:
                            const TextStyle(fontSize: 13, color: cLightText)),
                  ],
                ),
              if (profile.joinDateFormatted.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month_outlined,
                        size: 15, color: cLightIcon),
                    const SizedBox(width: 4),
                    Text('加入于 ${profile.joinDateFormatted}',
                        style:
                            const TextStyle(fontSize: 13, color: cLightText)),
                  ],
                ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        // 统计（对齐网页 ProfileMetrics：粉丝 / 关注 / 帖子）
        Row(
          children: [
            _StatBlock(
              count: ColibriProfile.abbreviate(profile.followersCount),
              label: '粉丝',
              onTap: () => _isGuestView
                  ? AuthGate.requireLogin(() {}, feature: '查看粉丝列表')
                  : Get.to(
                      () => ColibriConnectionsScreen(
                          userId: profile.id, title: '粉丝', following: false),
                      opaque: false),
            ),
            const SizedBox(width: 26),
            _StatBlock(
              count: ColibriProfile.abbreviate(profile.followingCount),
              label: '关注',
              onTap: () => _isGuestView
                  ? AuthGate.requireLogin(() {}, feature: '查看关注列表')
                  : Get.to(
                      () => ColibriConnectionsScreen(
                          userId: profile.id, title: '关注', following: true),
                      opaque: false),
            ),
            const SizedBox(width: 26),
            _StatBlock(
                count: ColibriProfile.abbreviate(profile.publicationsCount),
                label: '帖子'),
          ],
        ),
        const SizedBox(height: 16),
        _buildActions(profile),
        const SizedBox(height: 18),
      ],
    );
  }

  /// 操作按钮（对齐网页 ProfileActions：关注 + 私信 双列；我的：编辑资料 + 分享）。
  Widget _buildActions(ColibriProfile profile) {
    // 访客：关注/私信均为登录后能力，点击统一弹登录引导（不发任何关系请求）
    if (_isGuestView) {
      return Row(
        children: [
          Expanded(
            child: _PillButton(
              text: '关注',
              filled: true,
              onTap: () => AuthGate.requireLogin(() {}, feature: '关注作者'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PillButton(
              text: '私信',
              icon: Icons.chat_bubble_outline_rounded,
              onTap: () => AuthGate.requireLogin(() {}, feature: '发送私信'),
            ),
          ),
        ],
      );
    }
    if (profile.isOwner) {
      return Row(
        children: [
          Expanded(
            child: _PillButton(
              text: '编辑资料',
              icon: Icons.edit_outlined,
              onTap: () async {
                await Get.to(() => const ColibriEditProfileScreen(),
                    opaque: false);
                _load();
              },
            ),
          ),
          const SizedBox(width: 10),
          _SquareIconButton(
            icon: Icons.ios_share_rounded,
            onTap: () =>
                SharePlus.instance.share(ShareParams(text: _profileLink)),
          ),
        ],
      );
    }
    final hasFollow = profile.canFollow;
    final hasMessage = profile.canMessage;
    if (!hasFollow && !hasMessage) return const SizedBox.shrink();
    return Row(
      children: [
        if (hasFollow)
          Expanded(
            child: _PillButton(
              text: profile.isFollowing
                  ? '已关注'
                  : (profile.isFollowRequested ? '待确认' : '关注'),
              filled: !profile.isFollowing,
              onTap: _toggleFollow,
            ),
          ),
        if (hasFollow && hasMessage) const SizedBox(width: 10),
        if (hasMessage)
          Expanded(
            child: _PillButton(
              text: '私信',
              icon: Icons.chat_bubble_outline_rounded,
              onTap: _openChat,
            ),
          ),
      ],
    );
  }

  // ===================== 帖子 / 媒体 tab =====================

  Widget _buildPostsTab() {
    if (_posts.isEmpty && _loadingPosts) {
      return ColibriSkeletonPosts(
        onRefresh: () => _load(silent: true),
      );
    }
    return _postList(
      posts: _posts,
      loading: _loadingPosts,
      emptyText: '还没有帖子',
      onRefresh: () => _load(silent: true),
      onLoadMore: _loadPosts,
    );
  }

  Widget _buildMediaTab() {
    if (!_mediaLoaded && _loadingMedia) {
      return ColibriSkeletonPosts(
        onRefresh: () => _load(silent: true),
      );
    }
    return _postList(
      posts: _media,
      loading: _loadingMedia,
      emptyText: '还没有媒体内容',
      onRefresh: () => _load(silent: true),
      onLoadMore: _loadMedia,
    );
  }

  Widget _postList({
    required List<ColibriPost> posts,
    required bool loading,
    required String emptyText,
    required Future<void> Function() onRefresh,
    required Future<void> Function({bool reset}) onLoadMore,
  }) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) onLoadMore();
        return false;
      },
      child: RefreshIndicator(
        color: cPrimary,
        onRefresh: onRefresh,
        child: posts.isEmpty && !loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 90),
                  Center(
                      child: Text(emptyText,
                          style: const TextStyle(
                              color: cLightText, fontSize: 14))),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 6, bottom: 24),
                itemCount: posts.length + (loading ? 1 : 0),
                separatorBuilder: (context, index) {
                  if (index < posts.length - 1) {
                    return const Divider(
                      height: 1,
                      thickness: 1,
                      color: cLightBg,
                    );
                  }
                  return const SizedBox.shrink();
                },
                itemBuilder: (context, index) {
                  if (index >= posts.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                          child: CircularProgressIndicator(color: cPrimary)),
                    );
                  }
                  final p = posts[index];
                  return ColibriPostCard(
                    key: ValueKey('profile_${p.id}'),
                    post: p,
                    onChanged: () => onLoadMore(reset: true),
                    onTap: () async {
                      await Get.to(() => ColibriPostDetailScreen(post: p),
                          opaque: false);
                      onLoadMore(reset: true);
                    },
                  );
                },
              ),
      ),
    );
  }

  // ===================== 信息 tab（对齐网页 ProfileInfo） =====================

  Widget _buildInfoTab() {
    if (_loadingDetails) {
      return const Center(child: CircularProgressIndicator(color: cPrimary));
    }
    if (_detailsFailed || _details == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline_rounded, size: 40, color: cLightIcon),
            const SizedBox(height: 10),
            const Text('信息不可用',
                style: TextStyle(color: cLightText, fontSize: 14)),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () {
                _detailsLoaded = false;
                _loadDetails();
              },
              child: const Text('重试',
                  style: TextStyle(
                      color: cHashtagColor, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }
    final d = _details!;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        const SizedBox(height: 6),
        _sectionTitle('信息'),
        _InfoRow(
            icon: Icons.calendar_month_rounded,
            label: '加入时间',
            value: d.joinDate),
        if (d.location.isNotEmpty)
          _InfoRow(
              icon: Icons.location_on_rounded, label: '位置', value: d.location),
        if (d.birthdate.isNotEmpty)
          _InfoRow(icon: Icons.cake_rounded, label: '生日', value: d.birthdate),
        if (d.age != null)
          _InfoRow(
              icon: Icons.person_rounded, label: '年龄', value: '${d.age} 岁'),
        if (d.gender.isNotEmpty)
          _InfoRow(
              icon: Icons.face_retouching_natural_rounded,
              label: '性别',
              value: d.gender),
        if (d.email != null || d.phone != null) ...[
          _sectionTitle('联系方式'),
          if (d.email != null)
            _InfoRow(
                icon: Icons.mail_rounded,
                label: 'E-Mail',
                value: d.email!,
                copyable: true),
          if (d.phone != null)
            _InfoRow(
                icon: Icons.phone_rounded,
                label: '电话',
                value: d.phone!,
                copyable: true),
        ],
        if (d.socialLinks.isNotEmpty) ...[
          _sectionTitle('社交链接'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _padH, vertical: 6),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: d.socialLinks.map((link) {
                return GestureDetector(
                  onTap: () => _openUrl(link.url),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: cLightBg),
                    clipBehavior: Clip.antiAlias,
                    child: link.iconUrl != null && link.iconUrl!.isNotEmpty
                        ? MyCachedImage(
                            imageUrl: link.iconUrl,
                            width: 46,
                            height: 46,
                            cornerRadius: 23)
                        : const Icon(Icons.link_rounded,
                            size: 20, color: cLightIcon),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _padH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('部分信息已根据用户隐私设置隐藏',
                  style: TextStyle(fontSize: 12, color: cLightText)),
              if (d.lastActive.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('最后活跃于 ${d.lastActive}',
                    style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: cHashtagColor)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_padH, 14, _padH, 4),
      child: Text(title,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: cLightText,
              letterSpacing: 0.3)),
    );
  }
}

// ===================== 私有组件 =====================

/// 封面式 AppBar：封面延展到状态栏下；随滚动收缩， AppBar 区渐显白底 + 用户名，
/// 图标在封面态为白色（半透明黑底圆钮），白底态转为深色。
/// 头像放在 flexibleSpace 内（绘制在封面之上，底边贴 AppBar 底线 = 身份块顶线）。
class _ProfileCoverAppBar extends StatelessWidget {
  final double statusBarHeight;
  final double toolbarHeight;
  final double coverHeight; // 封面高度（屏幕顶 → 头像中线）
  final double avatarOverlap; // 头像下半段（中线 → AppBar 底边）
  final double padH;
  final String username;
  final bool isOwner;
  final VoidCallback onNotifications;
  final VoidCallback onSettings;
  final VoidCallback onMore;
  final bool showBack;
  final Widget? cover;
  final Widget? avatar;

  const _ProfileCoverAppBar({
    required this.statusBarHeight,
    required this.toolbarHeight,
    required this.coverHeight,
    required this.avatarOverlap,
    required this.padH,
    required this.username,
    required this.isOwner,
    required this.onNotifications,
    required this.onSettings,
    required this.onMore,
    required this.showBack,
    this.cover,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final expandedH = coverHeight + avatarOverlap;
        final collapsedH = statusBarHeight + toolbarHeight;
        // 收缩进度：0 = 展开（封面态），1 = 完全收起（白底态）
        final t =
            ((expandedH - constraints.maxHeight) / (expandedH - collapsedH))
                .clamp(0.0, 1.0);

        final iconColor = Color.lerp(Colors.white, cMainText, t)!;

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            // 封面层（底边锚定头像中线，随收起上移并淡出）
            if (cover != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: avatarOverlap,
                height: coverHeight,
                child: Opacity(
                  opacity: 1 - t,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      cover!,
                      // 顶部轻压暗衬托白色图标
                      IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.4],
                              colors: [
                                Colors.black.withValues(alpha: 0.25),
                                Colors.black.withValues(alpha: 0)
                              ],
                            ),
                          ),
                        ),
                      ),
                      // 底部渐隐融入页面
                      IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.55, 1.0],
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                cWhite
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              // 无封面：品牌绿渐变
              Positioned(
                left: 0,
                right: 0,
                bottom: avatarOverlap,
                height: coverHeight,
                child: Opacity(
                  opacity: 1 - t,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF3BE876), Color(0xFF16A44F)],
                      ),
                    ),
                  ),
                ),
              ),
            // AppBar 白底渐显层（状态栏 + 工具区）
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: collapsedH,
              child: IgnorePointer(
                child: Opacity(
                  opacity: t,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: cWhite,
                      border: Border(
                          bottom: BorderSide(
                              color: cLightBg, width: t > 0.98 ? 1 : 0)),
                    ),
                  ),
                ),
              ),
            ),
            // 悬浮头像：底边贴 AppBar 底线（= 身份块顶线），绘制在封面之上，随收缩淡出
            if (avatar != null)
              Positioned(
                left: padH,
                bottom: 0,
                child: Opacity(opacity: 1 - t, child: avatar),
              ),
            // 工具行（始终可见）
            Positioned(
              left: 0,
              right: 0,
              top: statusBarHeight,
              height: toolbarHeight,
              child: Row(
                children: [
                  if (showBack)
                    _AppBarIcon(
                      icon: Icons.arrow_back_rounded,
                      color: iconColor,
                      scrimOpacity: 1 - t,
                      onTap: () => Get.back(),
                    ),
                  // 标题随滚动渐显
                  Expanded(
                    child: Opacity(
                      opacity: t,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: cMainText),
                        ),
                      ),
                    ),
                  ),
                  if (isOwner) ...[
                    _AppBarIcon(
                      icon: Icons.notifications_none_rounded,
                      color: iconColor,
                      scrimOpacity: 1 - t,
                      onTap: onNotifications,
                    ),
                    _AppBarIcon(
                      icon: Icons.settings_outlined,
                      color: iconColor,
                      scrimOpacity: 1 - t,
                      onTap: onSettings,
                    ),
                  ] else
                    _AppBarIcon(
                      icon: Icons.more_horiz_rounded,
                      color: iconColor,
                      scrimOpacity: 1 - t,
                      onTap: onMore,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// AppBar 圆钮图标：封面态带半透明黑色底，白底态为纯图标。
class _AppBarIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double scrimOpacity;
  final VoidCallback onTap;

  const _AppBarIcon(
      {required this.icon,
      required this.color,
      required this.scrimOpacity,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final useScrim = scrimOpacity > 0.15;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: useScrim
            ? BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28 * scrimOpacity),
                shape: BoxShape.circle,
              )
            : null,
        child: Icon(icon, size: 23, color: color),
      ),
    );
  }
}

/// 吸顶标签栏（帖子 / 收藏 / 媒体 / 信息；收藏仅本人主页显示）。
class _ProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController controller;
  final List<String> labels;
  _ProfileTabBarDelegate(this.controller, {required this.labels});

  static const double _h = 52;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: _h,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: cWhite,
          border: Border(bottom: BorderSide(color: cLightBg, width: 1)),
        ),
        child: TabBar(
          controller: controller,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 9),
          indicator: BoxDecoration(
            color: cPrimary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(11),
          ),
          labelColor: cGreen,
          unselectedLabelColor: cLightText,
          labelStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          splashFactory: NoSplash.splashFactory,
          tabs: [for (final label in labels) Tab(text: label)],
        ),
      ),
    );
  }

  @override
  double get maxExtent => _h;

  @override
  double get minExtent => _h;

  @override
  bool shouldRebuild(covariant _ProfileTabBarDelegate oldDelegate) =>
      oldDelegate.controller != controller ||
      !listEquals(oldDelegate.labels, labels);
}

/// 统计块（数字加粗 + 灰色标签）。
class _StatBlock extends StatelessWidget {
  final String count;
  final String label;
  final VoidCallback? onTap;

  const _StatBlock({required this.count, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(count,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: cMainText)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 13, color: cLightText)),
      ],
    );
    if (onTap == null) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }
}

/// 胶囊按钮（关注 / 私信 / 编辑资料）。
class _PillButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool filled;
  final IconData? icon;

  const _PillButton(
      {required this.text,
      required this.onTap,
      this.filled = false,
      this.icon});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Material(
      color: filled ? cPrimary : cWhite,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: filled
              ? null
              : BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: cLightBg, width: 1.2)),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 17, color: filled ? cWhite : cMainText),
                  const SizedBox(width: 6),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: filled ? cWhite : cMainText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 方形图标按钮（分享）。
class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SquareIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Material(
      color: cWhite,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          height: 44,
          width: 48,
          decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: cLightBg, width: 1.2)),
          child: Icon(icon, size: 19, color: cMainText),
        ),
      ),
    );
  }
}

/// 信息行（图标芯片 + 标签 + 内容）。
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;

  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.copyable = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: copyable
          ? () {
              Clipboard.setData(ClipboardData(text: value));
              showColibriToast('已复制',
                  message: value,
                  backgroundColor: cGreen,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 1));
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: _ColibriProfileScreenState._padH, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: cPrimary.withValues(alpha: 0.10),
              ),
              child: Icon(icon, size: 20, color: cGreen),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 12, color: cLightText)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cMainText)),
                ],
              ),
            ),
            if (copyable)
              const Icon(Icons.copy_rounded, size: 16, color: cLightIcon),
          ],
        ),
      ),
    );
  }
}
