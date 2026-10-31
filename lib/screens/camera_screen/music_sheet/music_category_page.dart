import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/list_extension.dart';
import 'package:untitled/common/widgets/no_data_view.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/music_categories_model.dart';
import 'package:untitled/screens/camera_screen/music_sheet/music_category_sheet.dart';
import 'package:untitled/screens/camera_screen/music_sheet/music_sheet_controller.dart';
import 'package:untitled/utilities/const.dart';

class MusicCategoryPage extends StatelessWidget {
  final MusicSheetController controller;

  const MusicCategoryPage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      var categories = controller.allCategories.search(
        controller.searchQuery.value,
        (p0) => p0.title ?? '',
      );
      return NoDataView(
        showShow: categories.isEmpty,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            var category = categories[index];
            return _MusicCategoryCard(
              category: category,
              controller: controller,
            );
          },
        ),
      );
    });
  }
}

class _MusicCategoryCard extends StatelessWidget {
  final MusicSheetController controller;

  const _MusicCategoryCard({
    required this.category,
    required this.controller,
  });

  final MusicCategory category;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showColibriBottomSheet(
            MusicCategorySheet(
              controller: controller,
              category: category,
            ),
            ignoreSafeArea: false,
            isScrollControlled: true);
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: ClipSmoothRect(
          radius: SmoothBorderRadius(cornerRadius: 7),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: cWhite.withValues(alpha: 0.08),
            child: Row(
              children: [
                Text(
                  category.title ?? '',
                  style: MyTextStyle.gilroySemiBold(size: 18, color: cPrimary),
                ),
                Spacer(),
                Text(
                  '${category.musicsCount ?? 0} ${LKeys.musics.tr}',
                  style: MyTextStyle.gilroyRegular(size: 12, color: cLightText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
