import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/setting_model.dart';
import 'package:untitled/screens/interests_screen/interests_controller.dart';
import 'package:untitled/screens/interests_screen/interests_screen.dart';
import 'package:untitled/utilities/const.dart';

import '../extensions/font_extension.dart';

class InterestSelectorSection extends StatelessWidget {
  final RxList<Interest> selectedInterests;
  final String title;

  InterestSelectorSection(
      {required this.selectedInterests, required this.title});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 5, top: 15),
            child: Row(
              children: [
                Text(
                  "${title.tr} ${"(${selectedInterests.length}/${Limits.interestCount})"}",
                  style: MyTextStyle.gilroySemiBold(),
                ),
              ],
            ),
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            children: InterestsController.interests.map((e) {
              return InterestTag(
                  interest: e.title ?? '',
                  isContain: selectedInterests.contains(e),
                  onTap: () {
                    toggleInterest(e);
                  });
            }).toList(),
          ),
        ],
      ),
    );
  }

  void toggleInterest(Interest interest) {
    if (selectedInterests.contains(interest)) {
      removeInterest(interest);
    } else {
      if (selectedInterests.length < Limits.interestCount) {
        addInterest(interest);
      } else {
        BaseController.share.showSnackBar(
            "${LKeys.youCanNotSelectMoreThan.tr} ${Limits.interestCount}",
            type: SnackBarType.error);
      }
    }
  }

  void addInterest(Interest interest) {
    selectedInterests.add(interest);
  }

  void removeInterest(Interest interest) {
    selectedInterests.remove(interest);
  }
}
