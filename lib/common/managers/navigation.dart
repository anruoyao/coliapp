import 'package:get/get.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:untitled/common/widgets/functions.dart';
import 'package:untitled/screens/sheets/web_sheet_view/web_sheet_view.dart';

class Navigate {
  static void openURLSheet({required String title, required String url}) {
    showColibriBottomSheet(
      WebSheetScreen(title: title, url: url),
      isScrollControlled: true,
      ignoreSafeArea: false,
    ).then((value) {
      Functions.changStatusBar(StatusBarStyle.black);
    });
  }
}
