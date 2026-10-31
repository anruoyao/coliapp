import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:untitled/common/managers/guest_session.dart';
import 'package:untitled/common/widgets/colibri_skeleton.dart';
import 'package:untitled/main.dart' as app;
import 'package:untitled/screens/colibri_home/colibri_home_screen.dart';
import 'package:untitled/screens/colibri_feed/colibri_feed_screen.dart';
import 'package:untitled/models/colibri_social_models.dart';
import 'package:untitled/screens/colibri_social/colibri_profile_screen.dart';
import 'package:untitled/screens/login_screen/login_screen.dart';

const _profileFixture = bool.fromEnvironment('PROFILE_FIXTURE');
const _profileUsername = String.fromEnvironment('PROFILE_USERNAME');
const _feedPerformance = bool.fromEnvironment('FEED_PERFORMANCE');
const _profileTimeout = Duration(seconds: 30);
const _feedTimeout = Duration(seconds: 45);
const _legacyFrameBudgetMs = 16.67;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final frameTimings = <FrameTiming>[];

  setUpAll(() {
    SchedulerBinding.instance.addTimingsCallback(frameTimings.addAll);
  });

  tearDownAll(() {
    SchedulerBinding.instance.removeTimingsCallback(frameTimings.addAll);
    if (frameTimings.isNotEmpty) {
      final buildMs = frameTimings
          .map((timing) => timing.buildDuration.inMicroseconds / 1000)
          .toList()
        ..sort();
      final rasterMs = frameTimings
          .map((timing) => timing.rasterDuration.inMicroseconds / 1000)
          .toList()
        ..sort();
      final refreshRateHz = _displayRefreshRateHz;
      final frameBudgetUs = 1000000 / refreshRateHz;
      final report = {
        'frames': frameTimings.length,
        'refreshRateHz': refreshRateHz,
        'frameBudgetMs': frameBudgetUs / 1000,
        'buildP95Ms': buildMs[((buildMs.length - 1) * 0.95).round()],
        'buildMaxMs': buildMs.last,
        'rasterP95Ms': rasterMs[((rasterMs.length - 1) * 0.95).round()],
        'rasterMaxMs': rasterMs.last,
        'framesOverDisplayBudget': frameTimings
            .where((timing) => timing.totalSpan.inMicroseconds > frameBudgetUs)
            .length,
      };
      // ignore: avoid_print
      print('PROFILE_FRAME_TIMINGS $report');
      _addReport(binding, 'profileFrameTimings', report);
    }
  });

  testWidgets('opens the profile and reports its load state', (tester) async {
    final stopwatch = Stopwatch()..start();
    if (_feedPerformance) {
      await _runFeedPerformance(tester, binding, stopwatch);
      return;
    }
    if (_profileFixture) {
      await _runProfileFixture(tester, binding, stopwatch);
      return;
    }
    await app.main();
    await tester.pump();

    final startupStateVisible = await _waitFor(
      tester,
      () =>
          find.byType(LoginScreen).evaluate().isNotEmpty ||
          find.byType(ColibriHomeScreen).evaluate().isNotEmpty,
      timeout: _profileTimeout,
    );
    expect(startupStateVisible, isTrue,
        reason: 'The app did not reach login or home within $_profileTimeout.');

    if (find.byType(LoginScreen).evaluate().isNotEmpty) {
      final result = {
        'username': _profileUsername.isEmpty ? 'me' : _profileUsername,
        'ready': false,
        'state': 'authentication-required',
        'elapsedMs': stopwatch.elapsedMilliseconds,
      };
      // ignore: avoid_print
      print('PROFILE_FLOW_RESULT $result');
      _addReport(binding, 'profileFlow', result);
      fail(
          'The device has no authenticated session; sign in and rerun this test.');
    }

    final profileTab = find.text('我的').last;
    expect(profileTab, findsOneWidget);
    await tester.tap(profileTab);
    await tester.pump(const Duration(milliseconds: 400));

    if (_profileUsername.isNotEmpty) {
      Get.to(() => ColibriProfileScreen(username: _profileUsername));
      await tester.pump(const Duration(milliseconds: 400));
    }

    final profileReady = await _waitFor(
      tester,
      () => _profileStateVisible(tester),
      timeout: _profileTimeout,
    );

    final hasContent =
        find.byKey(const ValueKey('profile-content')).evaluate().isNotEmpty;
    final hasError =
        find.byKey(const ValueKey('profile-error')).evaluate().isNotEmpty;
    final elapsedMs = stopwatch.elapsedMilliseconds;
    final result = {
      'username': _profileUsername.isEmpty ? 'me' : _profileUsername,
      'ready': profileReady,
      'state': hasContent ? 'content' : (hasError ? 'error' : 'timeout'),
      'elapsedMs': elapsedMs,
    };
    // ignore: avoid_print
    print('PROFILE_FLOW_RESULT $result');
    _addReport(binding, 'profileFlow', result);

    expect(profileReady, isTrue,
        reason: 'Profile stayed blank or loading beyond $_profileTimeout.');
    expect(hasError, isFalse,
        reason:
            'Profile rendered its error state; inspect profile.load.error logs.');
    expect(tester.takeException(), isNull);
  });
}

Future<void> _runFeedPerformance(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  Stopwatch stopwatch,
) async {
  final frameTimings = <FrameTiming>[];
  void collectTimings(List<FrameTiming> timings) =>
      frameTimings.addAll(timings);
  SchedulerBinding.instance.addTimingsCallback(collectTimings);

  try {
    await app.main();
    await tester.pump();
    final appReady = await _waitFor(
      tester,
      () =>
          find.byType(LoginScreen).evaluate().isNotEmpty ||
          find.byType(ColibriHomeScreen).evaluate().isNotEmpty,
      timeout: _feedTimeout,
    );
    if (!appReady || find.byType(ColibriHomeScreen).evaluate().isEmpty) {
      final report = {
        'state': appReady ? 'authentication-required' : 'startup-timeout',
        'startupToReadyMs': stopwatch.elapsedMilliseconds,
      };
      // ignore: avoid_print
      print('FEED_PERFORMANCE_RESULT $report');
      _addReport(binding, 'feedPerformance', report);
      fail('Feed performance sampling requires an authenticated home screen.');
    }

    final startupToReadyMs = stopwatch.elapsedMilliseconds;
    final startupFrames = _summarizeFrames(frameTimings);
    final feedLoaded = await _waitFor(
      tester,
      () => find.byType(ColibriSkeletonPosts).evaluate().isEmpty,
      timeout: _feedTimeout,
    );
    expect(feedLoaded, isTrue,
        reason: 'Feed content did not finish loading within $_feedTimeout.');
    await tester.pump(const Duration(milliseconds: 500));

    final feed = find.byType(ColibriFeedScreen);
    expect(feed, findsOneWidget);
    final feedList = find.descendant(of: feed, matching: find.byType(ListView));
    expect(feedList, findsWidgets);
    final scrollable = feedList.first;

    var phaseStart = frameTimings.length;
    for (var i = 0; i < 4; i++) {
      await tester.timedDrag(
          scrollable, const Offset(0, -520), const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 120));
    }
    await tester.pump(const Duration(milliseconds: 300));
    final scrollFrames = _summarizeFrames(frameTimings.skip(phaseStart));

    phaseStart = frameTimings.length;
    final tabBarView =
        find.descendant(of: feed, matching: find.byType(TabBarView));
    expect(tabBarView, findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await tester.timedDrag(tabBarView, Offset(i.isEven ? -500 : 500, 0),
          const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 450));
    }
    final tabSwitchFrames = _summarizeFrames(frameTimings.skip(phaseStart));

    final report = {
      'state': 'measured',
      'startupToHomeMs': startupToReadyMs,
      'startupFrames': startupFrames,
      'feedScrollFrames': scrollFrames,
      'tabSwitchFrames': tabSwitchFrames,
    };
    // ignore: avoid_print
    print('FEED_PERFORMANCE_RESULT $report');
    _addReport(binding, 'feedPerformance', report);
    expect(tester.takeException(), isNull);
  } finally {
    SchedulerBinding.instance.removeTimingsCallback(collectTimings);
  }
}

Map<String, Object> _summarizeFrames(Iterable<FrameTiming> timings) {
  final frames = timings.toList();
  final refreshRateHz = _displayRefreshRateHz;
  final frameBudgetUs = 1000000 / refreshRateHz;
  final buildMs = frames
      .map((timing) => timing.buildDuration.inMicroseconds / 1000)
      .toList()
    ..sort();
  final rasterMs = frames
      .map((timing) => timing.rasterDuration.inMicroseconds / 1000)
      .toList()
    ..sort();
  if (buildMs.isEmpty) return {'frames': 0};
  final totalMs = frames
      .map((timing) => timing.totalSpan.inMicroseconds / 1000)
      .toList()
    ..sort();
  return {
    'frames': buildMs.length,
    'refreshRateHz': refreshRateHz,
    'frameBudgetMs': frameBudgetUs / 1000,
    'buildP95Ms': buildMs[((buildMs.length - 1) * 0.95).round()],
    'buildMaxMs': buildMs.last,
    'rasterP95Ms': rasterMs[((rasterMs.length - 1) * 0.95).round()],
    'rasterMaxMs': rasterMs.last,
    'totalP95Ms': totalMs[((totalMs.length - 1) * 0.95).round()],
    'totalMaxMs': totalMs.last,
    'framesOverDisplayBudget': frames
        .where((timing) => timing.totalSpan.inMicroseconds > frameBudgetUs)
        .length,
    'framesOver16_67ms': frames
        .where((timing) =>
            timing.totalSpan.inMicroseconds > _legacyFrameBudgetMs * 1000)
        .length,
  };
}

double get _displayRefreshRateHz {
  final views = WidgetsBinding.instance.platformDispatcher.views;
  final refreshRateHz = views.isEmpty ? 0.0 : views.first.display.refreshRate;
  return refreshRateHz.isFinite && refreshRateHz > 0 ? refreshRateHz : 60.0;
}

Future<void> _runProfileFixture(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  Stopwatch stopwatch,
) async {
  Get.put(GuestSession());
  await tester.pumpWidget(
    GetMaterialApp(
      home: ColibriProfileScreen.withTestProfile(profile: _fixtureProfile),
    ),
  );
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
  expect(find.byKey(const ValueKey('profile-content')), findsOneWidget);
  expect(tester.takeException(), isNull);

  final scrollable = find
      .descendant(
        of: find.byType(NestedScrollView),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.drag(scrollable, const Offset(0, -420));
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
  expect(tester.takeException(), isNull);

  await tester.tap(find.text('媒体').first, warnIfMissed: false);
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
  expect(tester.takeException(), isNull);

  final result = {
    'username': 'fixture',
    'ready': true,
    'state': 'content',
    'elapsedMs': stopwatch.elapsedMilliseconds,
  };
  // ignore: avoid_print
  print('PROFILE_FLOW_RESULT $result');
  _addReport(binding, 'profileFlow', result);
}

final _fixtureProfile = ColibriProfile(
  id: 1,
  name: 'Profile Test',
  username: 'profile_test',
  caption: '',
  bio: 'Local profile layout fixture',
  verified: false,
  publicationsCount: 0,
  followersCount: 0,
  followingCount: 0,
  isOwner: true,
  isFollowing: false,
  isFollowRequested: false,
  isBlocked: false,
  isBlockedBy: false,
  isMuted: false,
  canFollow: false,
  canMessage: false,
  canStoryReply: false,
  canBlock: false,
  canMute: false,
  canReport: false,
);

void _addReport(
  IntegrationTestWidgetsFlutterBinding binding,
  String key,
  Object value,
) {
  binding.reportData ??= <String, dynamic>{};
  binding.reportData![key] = value;
}

bool _profileStateVisible(WidgetTester tester) {
  return find.byKey(const ValueKey('profile-content')).evaluate().isNotEmpty ||
      find.byKey(const ValueKey('profile-error')).evaluate().isNotEmpty;
}

Future<bool> _waitFor(
  WidgetTester tester,
  bool Function() condition, {
  required Duration timeout,
}) async {
  var elapsed = Duration.zero;
  const step = Duration(milliseconds: 250);
  while (elapsed < timeout) {
    if (condition()) return true;
    await tester.pump(step);
    elapsed += step;
  }
  return condition();
}
