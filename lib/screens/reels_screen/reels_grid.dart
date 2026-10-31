import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/int_extension.dart';
import 'package:untitled/common/managers/context_menu_widget.dart';
import 'package:untitled/common/managers/load_more_widget.dart';
import 'package:untitled/common/widgets/loader_widget.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/common/widgets/no_data_view.dart';
import 'package:untitled/enums/reel_page_type.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/musics_model.dart';
import 'package:untitled/models/reel_model.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/screens/reels_screen/reels_screen.dart';
import 'package:untitled/utilities/const.dart';

class ReelsGrid extends StatelessWidget {
  final RxList<Reel> reels;
  final ScrollController? controller;
  final String? hashtag;
  final User? user;
  final ReelPageType reelType;
  final RxBool isLoading;
  final VoidCallback? onLoadMore;
  final bool isPinShow;
  final List<ContextMenuElement>? menus;
  final Music? music;
  final Future<void> Function() onFetchMoreData;
  final bool shrinkWrap;

  const ReelsGrid({
    super.key,
    required this.reels,
    this.controller,
    this.hashtag,
    required this.reelType,
    this.user,
    required this.isLoading,
    this.onLoadMore,
    this.isPinShow = false,
    this.menus,
    this.music,
    required this.onFetchMoreData,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        return LoadMoreWidget(
          loadMore: () async => onLoadMore?.call(),
          child: isLoading.value && reels.isEmpty
              ? LoaderWidget()
              : NoDataView(
                  showShow: reels.isEmpty,
                  child: GridView.builder(
                      primary: !shrinkWrap,
                      shrinkWrap: shrinkWrap,
                      itemCount: reels.length,
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 1,
                        crossAxisSpacing: 1,
                        mainAxisExtent: 180,
                      ),
                      itemBuilder: (context, index) {
                        Reel reel = reels[index];
                        return ReelGridCard(
                          onTap: () {
                            Get.to(
                                () => ReelsScreen(
                                      isLoading: false.obs,
                                      reels: reels,
                                      position: index.obs,
                                      pageType: reelType,
                                      hashTag: hashtag,
                                      user: user,
                                      music: music,
                                      onFetchMoreData: onFetchMoreData,
                                    ),
                                preventDuplicates: false,
                                opaque: false);
                          },
                          reel: reel,
                          isPinShow: isPinShow,
                          menus: menus,
                        );
                      }),
                ),
        );
      },
    );
  }
}

class ReelGridCard extends StatelessWidget {
  final Reel? reel;
  final VoidCallback? onTap;
  final bool isPinShow;
  final List<ContextMenuElement>? menus;

  const ReelGridCard(
      {super.key, this.reel, this.onTap, this.isPinShow = false, this.menus});

  @override
  Widget build(BuildContext context) {
    return ContextMenuWidget(
        child: InkWell(
          onTap: onTap,
          child: Stack(
            alignment: AlignmentDirectional.bottomEnd,
            children: [
              MyCachedImage(
                  height: 180,
                  width: Get.width / 3,
                  imageUrl: reel?.thumbnail?.addBaseURL(),
                  cornerRadius: 0),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.play,
                      color: cWhite,
                      size: 20,
                    ),
                    SizedBox(width: 3),
                    Text(
                      (reel?.viewsCount?.makeToString() ?? ''),
                      style: MyTextStyle.gilroyMedium(
                        size: 13,
                        color: cWhite,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        menuProvider: (_) {
          if (menus == null || reel == null) return Menu(children: []);

          // Pass the post instance into the menu items if required
          return Menu(
            children: menus!.map((element) {
              return MenuAction(
                title: LKeys.delete.tr,
                callback: () {
                  element.onTap?.call(reel!); // Pass the post to menu action
                },
              );
            }).toList(),
          );
        });
  }
}

class ContextMenuElement {
  final String title;
  final IconData? icon;
  final Function(Reel reel)? onTap; // Accepts Post

  ContextMenuElement({required this.title, this.icon, this.onTap});
}
