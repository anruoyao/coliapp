import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/widgets/no_data_view.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/chat.dart';
import 'package:untitled/screens/chats_screen/chat_view/chat_card.dart';
import 'package:untitled/screens/chats_screen/chats_screen_controller.dart';
import 'package:untitled/screens/extra_views/logo_tag.dart';
import 'package:untitled/utilities/const.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ChatsScreensController controller = Get.find<ChatsScreensController>();
    return GetBuilder<ChatsScreensController>(
        init: controller,
        builder: (controller) {
          return Column(
            children: [
              top(controller),
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    segmentController(controller),
                    const SizedBox(height: 15),
                    Expanded(
                      child: PageView(
                        controller: controller.controller,
                        onPageChanged: controller.onChangePage,
                        children: [
                          chatList(controller, 1),
                          chatList(controller, 2),
                          chatList(controller, 0),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          );
        });
  }

  Widget chatList(ChatsScreensController controller, int type) {
    List<ChatUserRoom> chats = (type == 2)
        ? controller.filterRoomChats
        : controller.filterChats
            .where((element) => element.type == type)
            .toList();

    return NoDataView(
      showShow: chats.isEmpty,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 0),
        itemCount: chats.length,
        itemBuilder: (context, index) {
          var chatUserRoom = chats[index];
          return ChatCard(
            chatUserRoom: chatUserRoom,
            controller: controller,
          );
        },
      ),
    );
  }

  Widget segmentController(ChatsScreensController controller) {
    return CupertinoSlidingSegmentedControl(
      children: {
        0: buildSegment(LKeys.chats.tr, 0, controller),
        1: buildSegment(LKeys.rooms.tr, 1, controller),
        2: buildSegment(LKeys.requests.tr, 2, controller),
      },
      groupValue: controller.selectedPage,
      backgroundColor: cLightText.withValues(alpha: 0.2),
      thumbColor: cBlack,
      padding: const EdgeInsets.all(0),
      onValueChanged: (value) {
        controller.onChangeSegment(value ?? 0);
      },
    );
  }

  Widget buildSegment(
      String text, int index, ChatsScreensController controller) {
    return Container(
      alignment: Alignment.center,
      width: (Get.width / 3) - 30,
      child: Text(
        text.toUpperCase(),
        style: MyTextStyle.gilroySemiBold(
                size: 13,
                color: controller.selectedPage == index ? cWhite : cBlack)
            .copyWith(letterSpacing: 2),
      ),
    );
  }

  Widget top(ChatsScreensController controller) {
    double imageSize = controller.isSearching ? 17 : 25;
    return Container(
      color: cBG,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              controller.isSearching
                  ? Expanded(
                      child: TextField(
                        onChanged: controller.onChange,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                            hintText: LKeys.searchHere.tr,
                            hintStyle: MyTextStyle.gilroyRegular(
                                color: cLightText.withValues(alpha: 0.6)),
                            border: InputBorder.none,
                            counterText: '',
                            isDense: true,
                            contentPadding: const EdgeInsets.all(0)),
                        cursorColor: cPrimary,
                        style: MyTextStyle.gilroyRegular(color: cLightText),
                        controller: controller.textEditingController,
                        textInputAction: TextInputAction.newline,
                        autofocus: true,
                      ),
                    )
                  : Expanded(
                      child: Row(
                        children: [
                          SizedBox(width: imageSize),
                          const Spacer(),
                          const LogoTag(),
                          const Spacer(),
                        ],
                      ),
                    ),
              GestureDetector(
                child: Image.asset(
                  controller.isSearching ? MyImages.close : MyImages.search,
                  width: imageSize,
                  height: imageSize,
                ),
                onTap: () {
                  controller.textEditingController.text = "";
                  controller.isSearching = !controller.isSearching;
                  controller.update();
                  controller.onChange('');
                },
              ),
            ],
          )),
    );
  }
}

class ChatSheetButton extends StatelessWidget {
  final String title;
  final Function() onTap;

  const ChatSheetButton({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
          alignment: Alignment.center,
          width: double.infinity,
          color: cBlack,
          child: Text(title,
              style: MyTextStyle.gilroySemiBold(color: cWhite, size: 18))),
      onTap: () {
        Get.back();
        onTap();
      },
    );
  }
}
