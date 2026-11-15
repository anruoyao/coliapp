import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/utilities/const.dart';

class ConfirmationSheet extends StatelessWidget {
  final String desc;
  final String buttonTitle;
  final Function() onTap;

  const ConfirmationSheet({
    super.key,
    required this.desc,
    required this.buttonTitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ColibriSheetSurface(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColibriSheetHeader(
            title: LKeys.areYouSure.tr,
            trailing: const ColibriSheetCloseButton(),
          ),
          const SizedBox(height: 16),
          Text(
            desc.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF636366),
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                onTap();
              },
              style: FilledButton.styleFrom(
                backgroundColor: cPrimary,
                foregroundColor: cWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(buttonTitle.tr),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF007AFF),
              minimumSize: const Size.fromHeight(44),
            ),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
        ],
      ),
    );
  }
}
