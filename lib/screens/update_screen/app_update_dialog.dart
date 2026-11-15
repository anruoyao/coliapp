import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/colibri_version_service.dart';
import 'package:untitled/localization/languages.dart';

/// Non-forced version update prompt.
class AppUpdateDialog extends StatelessWidget {
  final ColibriVersionInfo version;
  final VoidCallback onUpdate;
  final VoidCallback onLater;
  final VoidCallback onIgnore;

  const AppUpdateDialog({
    super.key,
    required this.version,
    required this.onUpdate,
    required this.onLater,
    required this.onIgnore,
  });

  List<String> get _noteLines => (version.notes ?? '')
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    final lines = _noteLines;
    return CupertinoAlertDialog(
      title: Text(LKeys.updateNewVersionFound.tr),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.4,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(LKeys.updateVersionAvailable.trParams({'p1': version.code})),
              if (lines.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(LKeys.updateWhatsNew.tr),
                const SizedBox(height: 6),
                ...lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(line),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: onUpdate,
          child: Text(LKeys.updateNow.tr),
        ),
        CupertinoDialogAction(
          onPressed: onLater,
          child: Text(LKeys.updateLater.tr),
        ),
        CupertinoDialogAction(
          onPressed: onIgnore,
          child: Text(LKeys.updateIgnoreVersion.tr),
        ),
      ],
    );
  }
}
