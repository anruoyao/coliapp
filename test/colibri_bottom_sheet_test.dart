import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:untitled/common/widgets/colibri_ui.dart';
import 'package:untitled/common/widgets/menu.dart';

void main() {
  testWidgets(
      'bottom sheet slides in linearly, resists upward drag, and springs back',
      (tester) async {
    addTearDown(() async {
      if (find.text('Sheet content').evaluate().isNotEmpty) {
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
      }
    });

    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showColibriBottomSheet<void>(
                const SizedBox(
                  height: 300,
                  child: Center(child: Text('Sheet content')),
                ),
                context: context,
                backgroundColor: Colors.white,
              ),
              child: const Text('Open sheet'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open sheet'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));
    final halfwayTop = tester.getTopLeft(find.text('Sheet content')).dy;
    await tester.pump(const Duration(milliseconds: 55));
    final threeQuarterTop = tester.getTopLeft(find.text('Sheet content')).dy;
    expect(threeQuarterTop, lessThan(halfwayTop));
    expect(threeQuarterTop, closeTo(halfwayTop - 75, 8));

    await tester.pumpAndSettle();
    await tester.drag(find.text('Sheet content'), const Offset(0, -120));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Sheet content'), findsOneWidget);
  });

  testWidgets('safe-area bottom sheets stay flush with the screen bottom',
      (tester) async {
    final sheetKey = GlobalKey();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 800),
          padding: EdgeInsets.only(bottom: 24),
          viewPadding: EdgeInsets.only(bottom: 24),
        ),
        child: GetMaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => showColibriBottomSheet<void>(
                    Container(
                      key: sheetKey,
                      height: 120,
                      color: Colors.white,
                    ),
                    context: context,
                    backgroundColor: Colors.transparent,
                    useSafeArea: true,
                  ),
                  child: const Text('Open edge sheet'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open edge sheet'));
    await tester.pumpAndSettle();

    final screenBottom =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(
      tester.getBottomRight(find.byKey(sheetKey)).dy,
      closeTo(screenBottom, 1),
    );
  });

  testWidgets('downward drag past one third dismisses the sheet',
      (tester) async {
    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showColibriBottomSheet<void>(
                const SizedBox(
                  height: 300,
                  child: Center(child: Text('Dismissible sheet')),
                ),
                context: context,
                backgroundColor: Colors.white,
              ),
              child: const Text('Open dismissible sheet'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open dismissible sheet'));
    await tester.pumpAndSettle();
    await tester.timedDrag(
      find.text('Dismissible sheet'),
      const Offset(0, 120),
      const Duration(milliseconds: 800),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dismissible sheet'), findsNothing);
  });

  testWidgets('fast downward fling dismisses before the distance threshold',
      (tester) async {
    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showColibriBottomSheet<void>(
                const SizedBox(
                  height: 300,
                  child: Center(child: Text('Fling sheet')),
                ),
                context: context,
                backgroundColor: Colors.white,
              ),
              child: const Text('Open fling sheet'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open fling sheet'));
    await tester.pumpAndSettle();
    await tester.fling(
      find.text('Fling sheet'),
      const Offset(0, 120),
      1600,
    );
    await tester.pumpAndSettle();

    expect(find.text('Fling sheet'), findsNothing);
  });

  testWidgets('post menu opens a bottom sheet and invokes the selected action',
      (tester) async {
    var selected = false;
    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: Center(
          child: Menu(
            isFromPost: true,
            items: [
              PopupMenuItem<void>(
                child: const Text('Report post'),
                onTap: () => selected = true,
              ),
            ],
          ),
        ),
      ),
    ));

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    expect(find.text('Report post'), findsOneWidget);
    await tester.tap(find.text('Report post'));
    await tester.pumpAndSettle();

    expect(selected, isTrue);
    expect(find.text('Report post'), findsNothing);
  });

  testWidgets('action sheet keeps menu behavior without a backdrop filter',
      (tester) async {
    var selected = false;
    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showColibriSheet(
                context,
                title: 'Post actions',
                items: [
                  ColibriSheetItem(
                    icon: Icons.link,
                    label: 'Copy link',
                    onTap: () => selected = true,
                  ),
                ],
              ),
              child: const Text('Open actions'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open actions'));
    await tester.pumpAndSettle();

    expect(find.text('Copy link'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
    await tester.tap(find.text('Copy link'));
    await tester.pumpAndSettle();

    expect(selected, isTrue);
    expect(find.text('Copy link'), findsNothing);
  });
}
