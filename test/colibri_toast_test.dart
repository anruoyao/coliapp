import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:untitled/common/widgets/colibri_bookmark_toast.dart';

void main() {
  testWidgets(
      'global toast replaces its predecessor and dismisses automatically',
      (tester) async {
    await tester.pumpWidget(GetMaterialApp(home: const Scaffold()));
    showColibriToast('操作失败',
        message: '请稍后重试', status: ColibriToastStatus.error);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('操作失败'), findsOneWidget);
    expect(find.text('请稍后重试'), findsOneWidget);
    showColibriToast('已删除', status: ColibriToastStatus.success);
    await tester.pump();
    expect(find.text('操作失败'), findsNothing);
    expect(find.text('已删除'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('已删除'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bookmark feedback keeps its icon and wraps long messages',
      (tester) async {
    late BuildContext host;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      host = context;
      return const Scaffold();
    })));
    showColibriBookmarkToast(host, bookmarked: true);
    await tester.pump();
    expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    showColibriToast('提示', context: host, message: '很长的提示文字' * 20);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
