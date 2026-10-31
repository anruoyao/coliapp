import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:untitled/common/api_service/colibri_timeline_service.dart';
import 'package:untitled/common/managers/bookmark_store.dart';
import 'package:untitled/common/managers/guest_session.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/widgets/colibri_markdown_text.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/colibri_post_models.dart';
import 'package:untitled/screens/colibri_feed/colibri_post_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storageDir;
  setUpAll(() async {
    storageDir = await Directory.systemTemp.createTemp('colibri_session_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => storageDir.path,
    );
    await GetStorage.init();
  });
  tearDownAll(() async => storageDir.delete(recursive: true));
  setUp(() async {
    await GetStorage().erase();
    SessionManager.shared = SessionManager();
    Get.testMode = true;
    Get.put(GuestSession());
    Get.put(BookmarkStore());
  });
  tearDown(() async => Get.reset());

  test('target normalizes app variants and safely falls back', () {
    for (final code in ['zh-Hans', 'zh_Hant', 'ZH-cn']) {
      expect(ColibriTimelineService.translationTarget(code), 'zh');
    }
    expect(ColibriTimelineService.translationTarget('pt-BR'), 'pt');
    expect(ColibriTimelineService.translationTarget('uk'), 'uk');
    expect(ColibriTimelineService.translationTarget('hi'), 'en');
    expect(ColibriTimelineService.translationTarget(''), 'en');
    expect(
        ColibriTimelineService.translationLanguageName('zh-Hans'), 'Chinese');
    expect(ColibriTimelineService.translationLanguageName('xx'), 'xx');
  });

  testWidgets(
      'user updates reach observers and stale refresh cannot restore logout',
      (tester) async {
    final session = SessionManager.shared;
    session.setToken('test-session');
    session.setColibriUser({'avatar_url': 'old'});
    await tester.pumpWidget(MaterialApp(
        home: Obx(() =>
            Text(session.colibriUserRx['avatar_url']?.toString() ?? 'empty'))));
    session.setColibriUser({'avatar_url': 'new'});
    await tester.pump();
    expect(find.text('new'), findsOneWidget);
    final pending = Completer<Map<String, dynamic>?>();
    final refresh = session.refreshColibriUser(() => pending.future);
    session.setToken('');
    pending.complete({'avatar_url': 'stale'});
    await refresh;
    await tester.pump();
    expect(find.text('empty'), findsOneWidget);
    expect(session.getColibriUser(), isNull);
  });

  test('newest refresh wins and account switch ignores old response', () async {
    final session = SessionManager.shared;
    session.setToken('first');
    final old = Completer<Map<String, dynamic>?>();
    final fresh = Completer<Map<String, dynamic>?>();
    final a = session.refreshColibriUser(() => old.future);
    final b = session.refreshColibriUser(() => fresh.future);
    fresh.complete({'avatar_url': 'new'});
    await b;
    old.complete({'avatar_url': 'old'});
    await a;
    expect(session.getColibriUser()?['avatar_url'], 'new');
    final switched = Completer<Map<String, dynamic>?>();
    final c = session.refreshColibriUser(() => switched.future);
    session.setToken('second');
    session.setColibriUser({'avatar_url': 'second'});
    switched.complete({'avatar_url': 'first'});
    await c;
    expect(session.getColibriUser()?['avatar_url'], 'second');
  });

  Future<void> card(WidgetTester tester,
      {int id = 1,
      String content = 'original',
      String locale = 'en',
      required Future<TranslationResult> Function(int, String)
          translate}) async {
    Get.locale = Locale(locale);
    await tester.pumpWidget(GetMaterialApp(
      translations: Languages(),
      locale: Locale(locale),
      home: Scaffold(
          body: ColibriPostCard(
              post: ColibriPost.fromJson({'id': id, 'content': content}),
              translatePost: translate)),
    ));
    await tester.pump();
  }

  String body(WidgetTester tester) =>
      tester.widget<ColibriMarkdownText>(find.byType(ColibriMarkdownText)).text;

  testWidgets(
      'translation disables duplicate clicks and retains text across toggles',
      (tester) async {
    final pending = Completer<TranslationResult>();
    var calls = 0;
    await card(tester, translate: (id, target) {
      expect(id, 1);
      expect(target, 'en');
      calls++;
      return pending.future;
    });
    await tester.tap(find.text('Translate'));
    await tester.pump();
    await tester.tap(find.text('Translate'));
    await tester.pump();
    expect(calls, 1);
    pending.complete((translatedText: 'translated', sourceLanguage: 'zh'));
    await tester.pump();
    expect(body(tester), 'translated');
    expect(find.text('Translated from Chinese'), findsOneWidget);
    await tester.tap(find.text('Translated from Chinese'));
    await tester.pump();
    expect(body(tester), 'original');
    await tester.tap(find.text('Translate'));
    await tester.pump();
    expect(body(tester), 'translated');
    expect(calls, 1);
  });

  testWidgets('missing source language falls back to show original',
      (tester) async {
    await card(
      tester,
      translate: (_, __) async =>
          (translatedText: 'translated', sourceLanguage: ''),
    );
    await tester.tap(find.text('Translate'));
    await tester.pump();
    expect(body(tester), 'translated');
    expect(find.text('Show original'), findsOneWidget);
    await tester.tap(find.text('Show original'));
    await tester.pump();
    expect(body(tester), 'original');
    expect(find.text('Translate'), findsOneWidget);
  });

  testWidgets('content, post and target changes discard pending translations',
      (tester) async {
    for (final change in ['content', 'id', 'locale']) {
      final pending = Completer<TranslationResult>();
      await card(tester, translate: (_, __) => pending.future);
      await tester.tap(find.text('Translate'));
      await tester.pump();
      await card(tester,
          id: change == 'id' ? 2 : 1,
          content: change == 'content' ? 'edited' : 'original',
          locale: change == 'locale' ? 'fr' : 'en',
          translate: (_, __) async =>
              (translatedText: 'fresh', sourceLanguage: 'en'));
      pending.complete((translatedText: 'stale', sourceLanguage: 'zh'));
      await tester.pump();
      expect(body(tester), change == 'content' ? 'edited' : 'original');
      final button = tester.widget<TextButton>(find.byType(TextButton));
      expect(button.onPressed, isNotNull);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('failure can retry and disposed requests are ignored',
      (tester) async {
    var calls = 0;
    await card(tester, translate: (_, __) async {
      if (++calls == 1) throw Exception('test failure');
      return (translatedText: 'retry result', sourceLanguage: 'en');
    });
    await tester.tap(find.text('Translate'));
    await tester.pump();
    expect(body(tester), 'original');
    await tester.pump(const Duration(seconds: 4));
    await tester.tap(find.text('Translate'));
    await tester.pump();
    expect(body(tester), 'retry result');
    await tester.pumpWidget(const SizedBox());
    final pending = Completer<TranslationResult>();
    await card(tester, translate: (_, __) => pending.future);
    await tester.tap(find.text('Translate'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    pending.complete((translatedText: 'late', sourceLanguage: 'en'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
