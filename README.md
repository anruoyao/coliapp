## Update Info

# Date: 26 Jan 2026

### Summary

- Maintenance mode - feature added
- Force App Update - feature added
- Bug fixes and improvements

#### Note

- replace first `pubspec.yaml` file.
- delete `pubspec.lock` file.
- run `flutter upgrade` in project terminal.
- run `flutter clean` in project terminal.
- run `flutter pub get` in project terminal.
- replace README.md file

#### Added Files

- [maintenance.png](assets/images/maintenance.png)
- [update.png](assets/images/update.png)
- [maintenance_screen.dart](lib/screens/maintenance_screen/maintenance_screen.dart)
- [update_app_screen.dart](lib/screens/update_screen/update_app_screen.dart)

#### Modified Files

- [image_extension.dart](lib/common/extensions/image_extension.dart)
- [setting_model.dart](lib/models/setting_model.dart)
- [profile_screen.dart](lib/screens/profile_screen/profile_screen.dart)
- [splash_controller.dart](lib/screens/splash_screen/splash_controller.dart)

--- Languages [languages](lib/localization/languages)

- languages.dart [localization](lib/localization)
- vietnamese.dart
- turkish.dart
- swedish.dart
- thai.dart
- spanish.dart
- russian.dart
- polish.dart
- portuguese.dart
- italian.dart
- japanese.dart
- korean.dart
- norwegian.dart
- french.dart
- german.dart
- greek.dart
- hindi.dart
- danish.dart
- dutch.dart
- english.dart
- chinese.dart
- arabic.dart

----

# Date: 19 Dec 2025

### Summary

- Video Player issue solved

#### Note

- replace first `pubspec.yaml` file.
- delete `pubspec.lock` file.
- run `flutter upgrade` in project terminal.
- run `flutter clean` in project terminal.
- run `flutter pub get` in project terminal.
- replace README.md file

#### Added Files

#### Modified Files

- [pubspec.lock](pubspec.lock)
- [tabbar_controller.dart](lib/screens/tabbar/tabbar_controller.dart)
- [reels_screen_controller.dart](lib/screens/reels_screen/reels_screen_controller.dart)
- [reel_page.dart](lib/screens/reels_screen/reel/reel_page.dart)
- [reels_screen.dart](lib/screens/reels_screen/reels_screen.dart)
- [login_screen.dart](lib/screens/login_screen/login_screen.dart)
- [login_controller.dart](lib/screens/login_screen/login_controller.dart)
- [dashboard_reels_controller.dart](lib/screens/dashboard_reels_screen/dashboard_reels_controller.dart)
- [reel_editor_screen.dart](lib/screens/camera_screen/reel_editor_screen.dart)
- [firebase_notification_manager.dart](lib/common/managers/firebase_notification_manager.dart)
- [settings.gradle](android/settings.gradle)

----

# Date: 02 Oct 2025

### Summary

- We have removed **Branch.io** from the project and implemented our **own
  deep linking solution**
  Replace all the files then follow the
  official [Deep Link](https://docs.retrytech.com/shortzz/shortzz_flutter#deeplink_setup).

### Why We Removed Branch.io

Branch.io is significantly more expensive for our use case. By switching to our
own deep linking
system, it will impact buyers to save min. $499 every month. Which makes this
move truly impactful
helping new startups financially.

### Current Status

- Branch.io SDK and configurations have been completely removed.
- Our own deep linking system is now active and configured as per the official
  documentation.
- We request all our existing buyers to make updates in source files (Flutter &
  Laravel both), Make
  database changes & follow the documentation listed above to move to
  independent Deeplink system.

#### Note

- replace first `pubspec.yaml` file.
- delete `pubspec.lock` file.
- run `flutter upgrade` in project terminal.
- run `flutter clean` in project terminal.
- run `flutter pub get` in project terminal.
- replace README.md file

#### Added Files

- [share_manager.dart](lib/common/managers/share_manager.dart)
- [context_menu_widget.dart](lib/common/managers/context_menu_widget.dart)

#### Modified Files

- [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)
- [AppDelegate.swift](ios/Runner/AppDelegate.swift)
- [AppFrameworkInfo.plist](ios/Flutter/AppFrameworkInfo.plist)
- [chatting_controller.dart](lib/screens/chats_screen/chatting_screen/chatting_controller.dart)
- [const.dart](lib/utilities/const.dart)
- [feed_screen.dart](lib/screens/feed_screen/feed_screen.dart)
- [feed_screen_controller.dart](lib/screens/feed_screen/feed_screen_controller.dart)
- [firebase_notification_manager.dart](lib/common/managers/firebase_notification_manager.dart)
- [gradle.properties](android/gradle.properties)
- [Info.plist](ios/Runner/Info.plist)
- [main.dart](lib/main.dart)
- [post_card.dart](lib/screens/post/post_card.dart)
- [post_controller.dart](lib/screens/post/post_controller.dart)
- [profile_controller.dart](lib/screens/profile_screen/profile_controller.dart)
- [pubspec.yaml](pubspec.yaml)
- [reel_page.dart](lib/screens/reels_screen/reel/reel_page.dart)
- [reel_page_controller.dart](lib/screens/reels_screen/reel/reel_page_controller.dart)
- [room_menu.dart](lib/screens/chats_screen/chat_room_view/room_menu/room_menu.dart)
- [settings.gradle](android/settings.gradle)
- [tabbar_controller.dart](lib/screens/tabbar/tabbar_controller.dart)
- [build.gradle](android/build.gradle)
- [build.gradle](android/app/build.gradle)
- [chat_card.dart](lib/screens/chats_screen/chat_view/chat_card.dart)
- [reels_grid.dart](lib/screens/reels_screen/reels_grid.dart)

#### Removed Files

- branch_manager.dart

----

# Date: 13 Aug 2025

### Summary

- Cache Video issue solved
- Bug fixes and improvements

#### Note

- replace first `pubspec.yaml` file.
- delete `pubspec.lock` file.
- run `flutter upgrade` in project terminal.
- run `flutter clean` in project terminal.
- run `flutter pub get` in project terminal.
- replace README.md file

#### Modified Files

- [audio_space_members_view.dart](lib/screens/audio_space/audio_spaces_screen/audio_space_screen/audio_space_members_view.dart)
- [branch_manager.dart](lib/common/managers/branch_manager.dart)
- [create_reel_bottom_view.dart](lib/screens/camera_screen/widget/create_reel_bottom_view.dart)
- [create_reel_screen.dart](lib/screens/camera_screen/create_reel_screen.dart)
- [moderator_service.dart](lib/common/api_service/moderator_service.dart)
- [post_controller.dart](lib/screens/post/post_controller.dart)
- [profile_controller.dart](lib/screens/profile_screen/profile_controller.dart)
- [reel_editor_screen.dart](lib/screens/camera_screen/reel_editor_screen.dart)
- [reel_page.dart](lib/screens/reels_screen/reel/reel_page.dart)
- [reels_screen.dart](lib/screens/reels_screen/reels_screen.dart)
- [reels_screen_controller.dart](lib/screens/reels_screen/reels_screen_controller.dart)
- [room_menu.dart](lib/screens/chats_screen/chat_room_view/room_menu/room_menu.dart)
- [sight_engine_service.dart](lib/common/api_service/sight_engine_service.dart)
- [story_media_picker.dart](lib/screens/story_screen/create_story_screen/widget/story_media_picker.dart)

----

# Date: 7 Aug 2025

### Summary

- Arabic issues solved
- AudioSpace improvements
- Bug fixes and improvements

#### Note

- replace first `pubspec.yaml` file.
- delete `pubspec.lock` file.
- run `flutter upgrade` in project terminal.
- run `flutter clean` in project terminal.
- run `flutter pub get` in project terminal.
- replace README.md file

#### Modified Files

- [api_service.dart](lib/common/api_service/api_service.dart)
- [audio_space_members_view.dart](lib/screens/audio_space/audio_spaces_screen/audio_space_screen/audio_space_members_view.dart)
- [audio_spaces_controller.dart](lib/screens/audio_space/audio_spaces_screen/audio_spaces_controller.dart)
- [audio_spaces_screen.dart](lib/screens/audio_space/audio_spaces_screen/audio_spaces_screen.dart)
- [chats_screen.dart](lib/screens/chats_screen/chats_screen.dart)
- [chatting_view.dart](lib/screens/chats_screen/chatting_screen/chatting_view.dart)
- [comment_screen.dart](lib/screens/post/comment/comment_screen.dart)
- [dashboard_reels_screen.dart](lib/screens/dashboard_reels_screen/dashboard_reels_screen.dart)
- [feed_screen_top_bar.dart](lib/screens/feed_screen/feed_screen_top_bar.dart)
- [firebase_notification_manager.dart](lib/common/managers/firebase_notification_manager.dart)
- [invite_someone_screen.dart](lib/screens/chats_screen/chat_room_view/screens/invite_someone_screen/invite_someone_screen.dart)
- [login_controller.dart](lib/screens/login_screen/login_controller.dart)
- [login_screen.dart](lib/screens/login_screen/login_screen.dart)
- [main.dart](lib/main.dart)
- [Podfile.lock](ios/Podfile.lock)
- [post_card.dart](lib/screens/post/post_card.dart)
- [profile_controller.dart](lib/screens/profile_screen/profile_controller.dart)
- [profile_screen.dart](lib/screens/profile_screen/profile_screen.dart)
- [pubspec.lock](pubspec.lock)
- [pubspec.yaml](pubspec.yaml)
- [room_members_screen.dart](lib/screens/chats_screen/chat_room_view/screens/room_member_screen/room_members_screen.dart)
- [setting_controller.dart](lib/screens/setting_screen/setting_controller.dart)
- [settings.gradle](android/settings.gradle)
- [subscription_manager.dart](lib/common/managers/subscription_manager.dart)

# Date: 19 May 2025

### Summary

- Audio Space Permission issue solved
- Bug fixes and improvements

#### Note

- replace first `pubspec.yaml` file.
- delete `pubspec.lock` file.
- run `flutter upgrade` in project terminal.
- run `flutter clean` in project terminal.
- run `flutter pub get` in project terminal.
- replace README.md file

#### Modified Files

- [audio_space_controller.dart](lib/screens/audio_space/audio_spaces_screen/audio_space_screen/audio_space_controller.dart)
- [audio_space_members_view.dart](lib/screens/audio_space/audio_spaces_screen/audio_space_screen/audio_space_members_view.dart)
- [chats_screen_controller.dart](lib/screens/chats_screen/chats_screen_controller.dart)
- [gradle-wrapper.properties](android/gradle/wrapper/gradle-wrapper.properties)
- [MainActivity.kt](android/app/src/main/kotlin/com/retrytech/chatter/untitled/MainActivity.kt)
- [profile_picture_screen.dart](lib/screens/profile_picture_screen/profile_picture_screen.dart)
- [reels_screen.dart](lib/screens/reels_screen/reels_screen.dart)

# Date: 19 May 2025

### Summary

- Profile Verification Camera issue solved
- Chat Interactive-Back Solved
- Admin Panel Responsive
- Bug fixes and improvements

#### Note

- replace first `pubspec.yaml` file.
- run `flutter upgrade` in project terminal.
- run `flutter clean` in project terminal.
- run `flutter pub get` in project terminal.
- replace README.md file

#### Modified Files

- [audio_space_controller.dart](lib/screens/audio_space/audio_spaces_screen/audio_space_screen/audio_space_controller.dart)
- [audio_space_screen.dart](lib/screens/audio_space/audio_spaces_screen/audio_space_screen/audio_space_screen.dart)
- [chatting_controller.dart](lib/screens/chats_screen/chatting_screen/chatting_controller.dart)
- [chatting_view.dart](lib/screens/chats_screen/chatting_screen/chatting_view.dart)
- [create_reel_screen_controller.dart](lib/screens/camera_screen/create_reel_screen_controller.dart)
- [profile_verification_controller.dart](lib/screens/profile_verification_screen/profile_verification_controller.dart)
- [profile_verification_screen.dart](lib/screens/profile_verification_screen/profile_verification_screen.dart)
- [sign_in_with_email_screen.dart](lib/screens/login_screen/sign_in_with_email_screen.dart)

# Date: 5 May 2025

### Summary

- Delete room function improved in admin panel.
- Verification icon in Reel Solved.
- SightEngine improved.
- Bug fixes and improvements

#### Note

- replace first `pubspec.yaml` file.
- run `flutter upgrade` in project terminal.
- run `flutter clean` in project terminal.
- run `flutter pub get` in project terminal.
- replace README.md file

#### Modified Files

- `ffmpeg_manager.dart` renamed to `editor_manager.dart`

- [add_post_controller.dart](lib/screens/add_post_screen/add_post_controller.dart)
- [add_reel_screen_controller.dart](lib/screens/camera_screen/add_reel_screen_controller.dart)
- [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)
- [base_controller.dart](lib/common/controller/base_controller.dart)
- [chat_card.dart](lib/screens/chats_screen/chat_view/chat_card.dart)
- [chats_screen.dart](lib/screens/chats_screen/chats_screen.dart)
- [const.dart](lib/utilities/const.dart)
- [create_reel_screen_controller.dart](lib/screens/camera_screen/create_reel_screen_controller.dart)
- [create_story_controller.dart](lib/screens/story_screen/create_story_screen/create_story_controller.dart)
- [create_story_screen.dart](lib/screens/story_screen/create_story_screen/create_story_screen.dart)
- [english.dart](lib/localization/languages/english.dart)
- [editor_manager.dart](lib/common/managers/editor_manager.dart)
- [edit_profile_controller.dart](lib/screens/edit_profile_screen/edit_profile_controller.dart)
- [image_video_manager.dart](lib/common/managers/image_video_manager.dart)
- [languages.dart](lib/localization/languages.dart)
- [languages_controller.dart](lib/screens/languages_screen/languages_controller.dart)
- [post_card.dart](lib/screens/post/post_card.dart)
- [profile_picture_controller.dart](lib/screens/profile_picture_screen/profile_picture_controller.dart)
- [profile_verification_controller.dart](lib/screens/profile_verification_screen/profile_verification_controller.dart)
- [profile_verification_screen.dart](lib/screens/profile_verification_screen/profile_verification_screen.dart)
- [reel_editor_screen.dart](lib/screens/camera_screen/reel_editor_screen.dart)
- [reel_page.dart](lib/screens/reels_screen/reel/reel_page.dart)
- [reels_screen.dart](lib/screens/reels_screen/reels_screen.dart)
- [reels_screen_controller.dart](lib/screens/reels_screen/reels_screen_controller.dart)
- [report_controller.dart](lib/screens/report_screen/report_controller.dart)
- [report_sheet.dart](lib/screens/report_screen/report_sheet.dart)
- [session_manager.dart](lib/common/managers/session_manager.dart)
- [setting_model.dart](lib/models/setting_model.dart)
- [sight_engine_service.dart](lib/common/api_service/sight_engine_service.dart)
- [sign_in_with_email_screen.dart](lib/screens/login_screen/sign_in_with_email_screen.dart)
- [string_extension.dart](lib/common/extensions/string_extension.dart)
- [user_info_and_description.dart](lib/screens/reels_screen/reel/widget/user_info_and_description.dart)
- [username_controller.dart](lib/screens/username_screen/username_controller.dart)
- [username_screen.dart](lib/screens/username_screen/username_screen.dart)
- [side_bar_list.dart](lib/screens/reels_screen/reel/widget/side_bar_list.dart)

# Date: 23 April 2025

### Summary

- FFmpeg Removed

#### Note

- replace first `pubspec.yaml` file.
- run `flutter upgrade` in project terminal.
- run `flutter clean` in project terminal.
- run `flutter pub get` in project terminal.
- replace README.md file

#### Modified Files

- [add_reel_screen_controller.dart](lib/screens/camera_screen/add_reel_screen_controller.dart)
- [build.gradle](android/app/build.gradle)
- [const.dart](lib/utilities/const.dart)
- [create_reel_screen.dart](lib/screens/camera_screen/create_reel_screen.dart)
- [create_reel_screen_controller.dart](lib/screens/camera_screen/create_reel_screen_controller.dart)
- [create_reel_top_view.dart](lib/screens/camera_screen/widget/create_reel_top_view.dart)
- [create_story_bottom_view.dart](lib/screens/story_screen/create_story_screen/widget/create_story_bottom_view.dart)
- [create_story_controller.dart](lib/screens/story_screen/create_story_screen/create_story_controller.dart)
- [create_story_screen.dart](lib/screens/story_screen/create_story_screen/create_story_screen.dart)
- [create_story_top_view.dart](lib/screens/story_screen/create_story_screen/widget/create_story_top_view.dart)
- [ffmpeg_manager.dart](lib/common/managers/editor_manager.dart)
- [floating_btn_for_creating.dart](lib/common/widgets/buttons/floating_btn_for_creating.dart)
- [new_api_service.dart](lib/common/api_service/new_api_service.dart)
- [random_screen.dart](lib/screens/random_screen/random_screen.dart)
- [random_screen_controller.dart](lib/screens/random_screen/random_screen_controller.dart)
- [reel_editor_screen.dart](lib/screens/camera_screen/reel_editor_screen.dart)
- [reel_page.dart](lib/screens/reels_screen/reel/reel_page.dart)
- [reel_service.dart](lib/common/api_service/reel_service.dart)

----

# Date: 27 March 2025

### Summary

- Reels Feature Added
- Search With Interests (Posts, Reels, Users)
- Interest attach with posts and reels
- Code Optimized
- Bug Fixed and improvements

#### Note

- replace first `pubspec.yaml` file.
- run `flutter upgrade` in project terminal.
- run `flutter clean` in project terminal.
- run `flutter pub get` in project terminal.
- replace README.md file

#### Added Files

- bookmark.png [images](assets/images/bookmark.png)
- bookmark_fill.png [images](assets/images/bookmark_fill.png)
- feed.png [images](assets/images/feed.png)
- gallery.png [images](assets/images/gallery.png)
- music.png [images](assets/images/music.png)
- music_note.png [images](assets/images/music_note.png)
- pause.png [images](assets/images/pause.png)
- pause_fill.png [images](assets/images/pause_fill.png)
- play.png [images](assets/images/play.png)
- play_fill.png [images](assets/images/play_fill.png)
- reels.png [images](assets/images/reels.png)
- report.png [images](assets/images/report.png)
- share.png [images](assets/images/share.png)
- story.png [images](assets/images/story.png)
- structure.jpg [images](assets/images/structure.jpg)
- camera_rotate.png [images](assets/images/camera_rotate.png)
- filter.png [images](assets/images/filter.png)
- flash.png [images](assets/images/flash.png)
- flash_off.png [images](assets/images/flash_off.png)

- Outfit-Medium.ttf [fonts](assets/fonts/Outfit-Medium.ttf)
- Outfit-Regular.ttf [fonts](assets/fonts/Outfit-Regular.ttf)

- [add_reel_data.dart](lib/models/add_reel_data.dart)
  [add_reel_screen.dart](lib/screens/camera_screen/add_reel_screen.dart)
  [add_reel_screen_controller.dart](lib/screens/camera_screen/add_reel_screen_controller.dart)
  [back_button.dart](lib/common/widgets/back_button.dart)
  [black_gradient_shadow.dart](lib/common/widgets/black_gradient_shadow.dart)
  [branch_manager.dart](lib/common/managers/branch_manager.dart)
  [color_filter_pageview_list.dart](lib/screens/camera_screen/color_filter_pageview_list.dart)
  [create_reel_bottom_view.dart](lib/screens/camera_screen/widget/create_reel_bottom_view.dart)
  [create_reel_screen.dart](lib/screens/camera_screen/create_reel_screen.dart)
  [create_reel_screen_controller.dart](lib/screens/camera_screen/create_reel_screen_controller.dart)
  [create_reel_top_view.dart](lib/screens/camera_screen/widget/create_reel_top_view.dart)
  [dashboard_reels_controller.dart](lib/screens/dashboard_reels_screen/dashboard_reels_controller.dart)
  [dashboard_reels_screen.dart](lib/screens/dashboard_reels_screen/dashboard_reels_screen.dart)
  [dashed_circle_painter.dart](lib/common/widgets/dashed_circle_painter.dart)
  [ffmpeg_manager.dart](lib/common/managers/editor_manager.dart)
  [filters.dart](lib/utilities/filters.dart)
  [floating_btn_for_creating.dart](lib/common/widgets/buttons/floating_btn_for_creating.dart)
  [follow_button.dart](lib/screens/follow_button/follow_button.dart)
  [follow_controller.dart](lib/screens/follow_button/follow_controller.dart)
  [follow_controller.dart](lib/screens/follow_button/follow_controller.dart)
  [image_video_manager.dart](lib/common/managers/image_video_manager.dart)
  [interest_selector.dart](lib/common/widgets/interest_selector.dart)
  [list_extension.dart](lib/common/extensions/list_extension.dart)
  [load_more_widget.dart](lib/common/managers/load_more_widget.dart)
  [loader_widget.dart](lib/common/widgets/loader_widget.dart)
  [music_categories_model.dart](lib/models/music_categories_model.dart)
  [music_category_page.dart](lib/screens/camera_screen/music_sheet/music_category_page.dart)
  [music_category_sheet.dart](lib/screens/camera_screen/music_sheet/music_category_sheet.dart)
  [music_explore_page.dart](lib/screens/camera_screen/music_sheet/music_explore_page.dart)
  [music_reels_screen.dart](lib/screens/reels_screen/music/music_reels_screen.dart)
  [music_reels_screen_controller.dart](lib/screens/reels_screen/music/music_reels_screen_controller.dart)
  [music_saved_page.dart](lib/screens/camera_screen/music_sheet/music_saved_page.dart)
  [music_service.dart](lib/common/api_service/music_service.dart)
  [music_sheet.dart](lib/screens/camera_screen/music_sheet/music_sheet.dart)
  [music_sheet_controller.dart](lib/screens/camera_screen/music_sheet/music_sheet_controller.dart)
  [music_trim_screen_controller.dart](lib/screens/camera_screen/music_trim_sheet/music_trim_screen_controller.dart)
  [music_trim_sheet.dart](lib/screens/camera_screen/music_trim_sheet/music_trim_sheet.dart)
  [musics_model.dart](lib/models/musics_model.dart)
  [my_debouncer.dart](lib/common/managers/my_debouncer.dart)
  [my_refresh_indicator.dart](lib/common/managers/my_refresh_indicator.dart)
  [new_api_service.dart](lib/common/api_service/new_api_service.dart)
  [no_data_view.dart](lib/common/widgets/no_data_view.dart)
  [play_button.dart](lib/common/widgets/buttons/play_button.dart)
  [reel_comment_card.dart](lib/screens/reels_screen/comments/reel_comment_card.dart)
  [reel_comment_controller.dart](lib/screens/reels_screen/comments/reel_comment_controller.dart)
  [reel_comment_model.dart](lib/models/reel_comment_model.dart)
  [reel_comment_screen.dart](lib/screens/reels_screen/comments/reel_comment_screen.dart)
  [reel_comments_model.dart](lib/models/reel_comments_model.dart)
  [reel_editor_screen.dart](lib/screens/camera_screen/reel_editor_screen.dart)
  [reel_model.dart](lib/models/reel_model.dart)
  [reel_model_extension.dart](lib/models/reel_model_extension.dart)
  [reel_page.dart](lib/screens/reels_screen/reel/reel_page.dart)
  [reel_page_controller.dart](lib/screens/reels_screen/reel/reel_page_controller.dart)
  [reel_page_type.dart](lib/enums/reel_page_type.dart)
  [reel_service.dart](lib/common/api_service/reel_service.dart)
  [reels_grid.dart](lib/screens/reels_screen/reels_grid.dart)
  [reels_model.dart](lib/models/reels_model.dart)
  [reels_screen.dart](lib/screens/reels_screen/reels_screen.dart)
  [reels_screen_controller.dart](lib/screens/reels_screen/reels_screen_controller.dart)
  [reels_text_field.dart](lib/screens/reels_screen/widget/reels_text_field.dart)
  [reels_top_bar.dart](lib/screens/reels_screen/widget/reels_top_bar.dart)
  [saved_reels_screen.dart](lib/screens/saved_reels_screen/saved_reels_screen.dart)
  [saved_reels_screen_controller.dart](lib/screens/saved_reels_screen/saved_reels_screen_controller.dart)
  [search_post_with_interest_screen.dart](lib/screens/search_post_with_interest_screen/search_post_with_interest_screen.dart)
  [search_post_with_interest_screen_controller.dart](lib/screens/search_post_with_interest_screen/search_post_with_interest_screen_controller.dart)
  [search_reel_with_interest_screen.dart](lib/screens/search_reel_with_interest_screen/search_reel_with_interest_screen.dart)
  [search_reel_with_interest_screen_controller.dart](lib/screens/search_reel_with_interest_screen/search_reel_with_interest_screen_controller.dart)
  [side_bar_list.dart](lib/screens/reels_screen/reel/widget/side_bar_list.dart)
  [single_reel_screen.dart](lib/screens/single_reel_screen/single_reel_screen.dart)
  [single_reel_screen_controller.dart](lib/screens/single_reel_screen/single_reel_screen_controller.dart)
  [status_message_model.dart](lib/models/status_message_model.dart)
  [user_info_and_description.dart](lib/screens/reels_screen/reel/widget/user_info_and_description.dart)

#### Modified Files

- All files from [languages](lib/localization/languages)

- add_post_controller.dart
- add_post_screen.dart
- AndroidManifest.xml
- api_service.dart
- audio_space.dart
- audio_space_interests_screen.dart
- audio_space_invite_screen.dart
- audio_space_members_view.dart
- audio_space_messages_view.dart
- audio_space_room_view.dart
- audio_spaces_screen.dart
- base_controller.dart
- block_user_controller.dart
- blocklist_screen.dart
- build.gradle [build](../chatter/android/app/build.gradle)
- build.gradle [build](../chatter/android/build.gradle)
- buttons.dart
- camera_filters.dart
- chat_card.dart
- chat_tag.dart
- chats_screen.dart
- chats_screen_controller.dart
- chatting_controller.dart
- chatting_view.dart
- comment_card.dart
- comment_controller.dart
- comment_screen.dart
- common_service.dart
- const.dart
- create_audio_space_controller.dart
- create_audio_space_screen.dart
- create_room_controller.dart
- create_room_screen.dart
- create_story_controller.dart
- create_story_screen.dart
- double_click_like.dart
- edit_profile_controller.dart
- edit_profile_screen.dart
- faq_screen.dart
- feed_screen.dart
- feed_screen_controller.dart
- feed_screen_top_bar.dart
- feed_stories_controller.dart
- feed_story_screen.dart
- follower_following_controller.dart
- follower_following_screen.dart
- font_extension.dart
- full_image_screen.dart
- gradle-wrapper.properties
- image_extension.dart
- image_video_chat_picker.dart
- indonesian.dart
- Info.plist
- int_extension.dart
- interests_screen.dart
- interstitial_manager.dart
- invitation_controller.dart
- invite_someone_controller.dart
- invite_someone_screen.dart
- join_requests_screen.dart
- languages.dart
- login_screen.dart
- logo_tag.dart
- main.dart
- moderator_service.dart
- my_cached_image.dart
- navigation.dart
- notification_controller.dart
- notification_screen.dart
- on_boarding_screen.dart
- params.dart
- Podfile
- Podfile.lock
- post_card.dart
- post_controller.dart
- post_service.dart
- posts_model.dart
- profile_controller.dart
- profile_picture_controller.dart
- profile_screen.dart
- profile_verification_controller.dart
- pubspec.lock
- random_screen.dart
- registration.dart
- report_controller.dart
- report_sheet.dart
- room_card.dart
- room_chat_view.dart
- room_controller.dart
- room_explore_by_interests.dart
- room_invitation_screen.dart
- room_members_controller.dart
- room_members_screen.dart
- room_menu.dart
- room_model.dart
- room_service.dart
- room_sheet.dart
- rooms_by_interest_controller.dart
- rooms_by_interest_screen.dart
- rooms_model.dart
- rooms_you_own_screen.dart
- search_bar.dart
- search_controller.dart
- search_screen.dart
- setting_controller.dart
- setting_screen.dart
- settings.gradle
- sight_engine_service.dart
- sign_in_with_email_screen.dart
- single_feed_model.dart
- single_post_screen.dart
- single_room_screen.dart
- story_screen.dart
- story_screen_controller.dart
- tabbar_controller.dart
- tabbar_screen.dart
- tag_controller.dart
- tag_screen.dart
- top_bar.dart
- user_notification_model.dart
- user_service.dart
- username_controller.dart
- username_screen.dart
- web_service.dart
- web_sheet_view.dart
- xmark_button.dart

#### Deleted Files

- no_data_found.dart
- folder `camera_filters` is deleted. [camera_filters](/lib/library/)

----

## Update Info

# Date: 27 December 2024

### Summary

- Android Camera issue solved
- Some Improvements

#### Note

- replace first `pubspec.yaml` file.
- run `flutter upgrade` in project terminal.
- run `flutter clean` in project terminal.
- run `flutter pub get` in project terminal.

#### Added Files

- [logger.dart](lib/common/managers/logger.dart)

#### Modified Files

- [add_post_controller.dart](lib/screens/add_post_screen/add_post_controller.dart)
- [api_service.dart](lib/common/api_service/api_service.dart)
- [build.gradle](android/app/build.gradle)
- [camera_filters.dart](lib/library/camera_filters/camera_filters.dart)
- [main.dart](lib/main.dart)
- [post_card.dart](lib/screens/post/post_card.dart)
- [pubspec.lock](pubspec.lock)
- [pubspec.yaml](pubspec.yaml)
- [README.md](README.md)
- [result_view.dart](lib/library/camera_filters/result_view.dart)
- [user_service.dart](lib/common/api_service/user_service.dart)
- [video_player_sheet.dart](lib/screens/post/video_player_sheet.dart)

---

# Date: 18 December 2024

### Summary

- Flutter upgrade
- Dependencies Updated

#### Note

- replace first `pubspec.yaml` file.
- run `flutter upgrade` in project terminal.

#### Modified Files

- [.gitignore](.gitignore)
- [add_post_screen.dart](lib/screens/add_post_screen/add_post_screen.dart)
- [audio_player_sheet.dart](lib/screens/post/audio_player_sheet.dart)
- [audio_space_ended_for_host_screen.dart](lib/screens/audio_space/audio_spaces_screen/audio_space_screen/audio_space_ended_for_host_screen.dart)
- [audio_space_ended_for_user_screen.dart](lib/screens/audio_space/audio_spaces_screen/audio_space_screen/audio_space_ended_for_user_screen.dart)
- [audio_space_invite_screen.dart](lib/screens/audio_space/create_audio_space_screen/audio_space_invite_screen.dart)
- [audio_space_members_view.dart](lib/screens/audio_space/audio_spaces_screen/audio_space_screen/audio_space_members_view.dart)
- [audio_space_messages_view.dart](lib/screens/audio_space/audio_spaces_screen/audio_space_screen/audio_space_messages_view.dart)
- [audio_space_room_view.dart](lib/screens/audio_space/audio_spaces_screen/audio_space_screen/audio_space_room_view.dart)
- [audio_space_screen.dart](lib/screens/audio_space/audio_spaces_screen/audio_space_screen/audio_space_screen.dart)
- [audio_spaces_screen.dart](lib/screens/audio_space/audio_spaces_screen/audio_spaces_screen.dart)
- [back_button.dart](lib/screens/extra_views/back_button.dart)
- [block_by_admin_screen.dart](lib/screens/block_by_admin_screen/block_by_admin_screen.dart)
- [blocklist_screen.dart](lib/screens/block_list_screen/blocklist_screen.dart)
- [build.gradle](android/app/build.gradle)
- [buttons.dart](lib/screens/extra_views/buttons.dart)
- [camera_filters.dart](lib/library/camera_filters/camera_filters.dart)
- [capture_or_choose_sheet.dart](lib/screens/add_post_screen/capture_or_choose_sheet.dart)
- [chat_card.dart](lib/screens/chats_screen/chat_view/chat_card.dart)
- [chat_tag.dart](lib/screens/chats_screen/chat_view/chat_tag.dart)
- [chats_screen.dart](lib/screens/chats_screen/chats_screen.dart)
- [chatting_view.dart](lib/screens/chats_screen/chatting_screen/chatting_view.dart)
- [circle_button.dart](lib/common/widgets/buttons/circle_button.dart)
- [circle_painter.dart](lib/common/widgets/plusing_animation/circle_painter.dart)
- [comment_screen.dart](lib/screens/post/comment/comment_screen.dart)
- [confirmation_sheet.dart](lib/screens/sheets/confirmation_sheet.dart)
- [const.dart](lib/utilities/const.dart)
- [content_full_screen.dart](lib/screens/chats_screen/chatting_screen/content_full_screen.dart)
- [create_audio_space_screen.dart](lib/screens/audio_space/create_audio_space_screen/create_audio_space_screen.dart)
- [create_room_screen.dart](lib/screens/rooms_you_own/create_room_screen/create_room_screen.dart)
- [double_click_like.dart](lib/screens/post/double_click_like.dart)
- [edit_profile_screen.dart](lib/screens/edit_profile_screen/edit_profile_screen.dart)
- [faq_screen.dart](lib/screens/faq_screen/faq_screen.dart)
- [feed_screen.dart](lib/screens/feed_screen/feed_screen.dart)
- [feed_story_screen.dart](lib/screens/feed_screen/feed_story_screen.dart)
- [filters.dart](lib/library/camera_filters/src/filters.dart)
- [full_image_screen.dart](lib/screens/profile_screen/full_image_screen.dart)
- [gradle-wrapper.properties](android/gradle/wrapper/gradle-wrapper.properties)
- [image_video_chat_picker.dart](lib/screens/chats_screen/chatting_screen/image_video_chat_picker.dart)
- [interests_screen.dart](lib/screens/interests_screen/interests_screen.dart)
- [invite_someone_screen.dart](lib/screens/chats_screen/chat_room_view/screens/invite_someone_screen/invite_someone_screen.dart)
- [join_requests_screen.dart](lib/screens/chats_screen/chat_room_view/screens/join_requests_screen.dart)
- [jsonld_parser.dart](lib/common/managers/url_extractor/parsers/jsonld_parser.dart)
- [login_button.dart](lib/screens/login_screen/login_button.dart)
- [login_controller.dart](lib/screens/login_screen/login_controller.dart)
- [menu.dart](lib/common/widgets/menu.dart)
- [notification_screen.dart](lib/screens/notification_screen/notification_screen.dart)
- [on_boarding_screen.dart](lib/screens/on_boarding_screen/on_boarding_screen.dart)
- [Podfile.lock](ios/Podfile.lock)
- [post_card.dart](lib/screens/post/post_card.dart)
- [profile_picture_screen.dart](lib/screens/profile_picture_screen/profile_picture_screen.dart)
- [profile_screen.dart](lib/screens/profile_screen/profile_screen.dart)
- [profile_verification_screen.dart](lib/screens/profile_verification_screen/profile_verification_screen.dart)
- [pubspec.lock](pubspec.lock)
- [pubspec.yaml](pubspec.yaml)
- [random_screen.dart](lib/screens/random_screen/random_screen.dart)
- [README.md](README.md)
- [record_audio_screen.dart](lib/screens/add_post_screen/record_audio/record_audio_screen.dart)
- [report_sheet.dart](lib/screens/report_screen/report_sheet.dart)
- [result_view.dart](lib/library/camera_filters/result_view.dart)
- [room_card.dart](lib/screens/rooms_screen/room_card.dart)
- [room_chat_view.dart](lib/screens/chats_screen/chat_room_view/room_chat_view.dart)
- [room_invitation_screen.dart](lib/screens/room_invitation_screen/room_invitation_screen.dart)
- [room_members_screen.dart](lib/screens/chats_screen/chat_room_view/screens/room_member_screen/room_members_screen.dart)
- [room_sheet.dart](lib/screens/rooms_screen/room_sheet.dart)
- [search_screen.dart](lib/screens/search_screen/search_screen.dart)
- [setting_controller.dart](lib/screens/setting_screen/setting_controller.dart)
- [setting_screen.dart](lib/screens/setting_screen/setting_screen.dart)
- [settings.gradle](android/settings.gradle)
- [sign_in_with_email_screen.dart](lib/screens/login_screen/sign_in_with_email_screen.dart)
- [story_screen.dart](lib/screens/story_screen/story_screen.dart)
- [story_view.dart](lib/library/story_view/widgets/story_view.dart)
- [username_screen.dart](lib/screens/username_screen/username_screen.dart)
- [video_player_sheet.dart](lib/screens/post/video_player_sheet.dart)

---

# Date: 9 November 2024

### Summary

- Profiles Clickable in Room Chat

#### Note

- run `flutter upgrade` in project terminal.

#### Modified Files

- chat_tag.dart
- main.dart
- pubspec.yaml
- README.md

---

# Date: 28 October 2024

### Summary

- Bug fixes and improvements
- Profiles Clickable in Chat
- Comments will be shown in admin panel

#### Added Files

- [Outfit-Light.ttf](assets/fonts/Outfit-Light.ttf)
- intro_bg.png [images](assets/images/intro_bg.png)

#### Modified Files

- add_post_controller.dart
- add_post_screen.dart
- audio_player_sheet.dart
- audio_space_members_view.dart
- audio_spaces_controller.dart
- audio_spaces_screen.dart
- banner_ad.dart
- build.gradle [build](../chatter/android/app/build.gradle)
- build.gradle [build](../chatter/android/build.gradle)
- camera_filters.dart
- capture_or_choose_sheet.dart
- chat.dart
- chatting_controller.dart
- chatting_view.dart
- comment_card.dart
- comment_controller.dart
- confirmation_sheet.dart
- const.dart
- content_full_screen.dart
- english.dart
- firebase_notification_manager.dart
- font_extension.dart
- image_extension.dart
- Info.plist
- invitation_controller.dart
- invite_someone_screen.dart
- languages.dart
- main.dart
- meeting.png
- mic_fill.png
- my_cached_image.dart
- notification_screen.dart
- on_boarding_screen.dart
- Podfile
- Podfile.lock
- post_card.dart
- post_controller.dart
- profile.png
- profile_controller.dart
- profile_screen.dart
- project.pbxproj
- pubspec.lock
- pubspec.yaml
- quill.png
- random.png
- random_screen.dart
- README.md
- report_sheet.dart
- room_card.dart
- room_controller.dart
- room_members_screen.dart
- room_memebers_controller.dart
- room_sheet.dart
- rooms_by_interest_controller.dart
- Runner.xcscheme
- search_controller.dart
- search_screen.dart
- splash_controller.dart
- subscription_manager.dart
- tabbar_screen.dart
- video_player_sheet.dart

#### Note

- After changing files you have to run command flutter pub get. Make sure you
  are using latest Flutter & Dart

---

# Date: 16 September 2024

### Summary

-- Username issue solved in EditProfile Screen
-- Double tap to like issue solved
-- Some bug fixes and improvements

#### Added Files

- No Added any files

#### Modified Files

- add_post_screen.dart
- audio_player_sheet.dart
- audio_spaces_screen.dart
- AndroidManifest.xml
- build.gradle
- comment_controller.dart
- feed_screen.dart
- post_controller.dart
- search_screen.dart
- sight_engine_service.dart
- edit_profile_controller.dart
- Podfile.lock
- post_card.dart
- pubspec.lock
- pubspec.yaml
- random_screen.dart
- README.md
- settings.gradle
- video_player_sheet.dart

# Note

- After changing files you have to run command flutter pub get. Make sure you
  are using latest Flutter & Dart

# Date: 17 August 2024

### Summary

-- Hero, Audio Post, Everything search, refresh and so many things
-- Bug fixes and improvements

#### Added Files

-

audio_player_sheet.dart [audio_player_sheet.dart](lib/screens/post/audio_player_sheet.dart)
-
capture_or_choose_sheet.dart [capture_or_choose_sheet.dart](lib/screens/add_post_screen/capture_or_choose_sheet.dart)
-
full_image_screen.dart [full_image_screen.dart](lib/screens/profile_screen/full_image_screen.dart)
-
moderator_service.dart [moderator_service.dart](lib/common/api_service/moderator_service.dart)
-
post_liked_users_controller.dart [post_liked_users_controller.dart](lib/screens/post/post_liked_users_controller.dart)
-
post_liked_users_screen.dart [post_liked_users_screen.dart](lib/screens/post/post_liked_users_screen.dart)
-
post_users_model.dart [post_users_model.dart](lib/models/post_users_model.dart)
-
record_audio_screen.dart [record_audio_screen.dart](lib/screens/add_post_screen/record_audio/record_audio_screen.dart)
-
search_hashtags_model.dart [search_hashtags_model.dart](lib/models/search_hashtags_model.dart)
-
sight_engine_media_model.dart [sight_engine_media_model.dart](lib/models/sight_engine_models/sight_engine_media_model.dart)
-
sight_engine_service.dart [sight_engine_service.dart](lib/common/api_service/sight_engine_service.dart)
-
text_moderation_model.dart [text_moderation_model.dart](lib/models/sight_engine_models/text_moderation_model.dart)

- All files from [url_extractor](lib/common/managers/url_extractor)
- All files from [add_to_cart](lib/library/add_to_cart)

--- Images [images](assets/images)

- hashtag.png
- send_story.png

#### Modified Files

- add_post_controller.dart
- add_post_screen.dart
- AndroidManifest.xml
- api_service.dart
- AppDelegate.swift
- audio_space_invite_screen.dart
- back_button.dart
- banner_ad.dart
- base_controller.dart
- block_by_admin_screen.dart
- build.gradle
- buttons.dart
- chat.dart
- chat_card.dart
- chat_tag.dart
- chatting_controller.dart
- chatting_view.dart
- comment_card.dart
- comment_controller.dart
- comment_screen.dart
- comments_model.dart
- common_service.dart
- const.dart
- content_full_screen.dart
- create_audio_space_controller.dart
- create_story_controller.dart
- cupertino_controller.dart
- edit_profile_controller.dart
- edit_profile_screen.dart
- feed_screen.dart
- feed_screen_controller.dart
- feed_stories_controller.dart
- feeds_model.dart
- firebase_const.dart
- gradle.properties
- gradle-wrapper.properties
- image_extension.dart
- image_video_chat_picker.dart
- languages.dart
- login_button.dart
- login_controller.dart
- main.dart
- my_cached_image.dart
- params.dart
- Podfile.lock
- post_card.dart
- post_controller.dart
- post_service.dart
- profile_controller.dart
- profile_screen.dart
- pubspec.lock
- pubspec.yaml
- random_screen.dart
- registration.dart
- report_sheet.dart
- room_controller.dart
- room_menu.dart
- room_service.dart
- rooms_by_interest_controller.dart
- rooms_screen.dart
- rooms_you_own_controller.dart
- Runner.entitlements
- search_controller.dart
- search_screen.dart
- session_manager.dart
- setting_model.dart
- settings.gradle
- sign_in_with_email_screen.dart
- story.dart
- story_screen.dart
- story_service.dart
- story_view.dart
- tabbar_controller.dart
- tabbar_screen.dart
- tag_controller.dart
- user_service.dart
- username_controller.dart
- video_player_sheet.dart
- web_service.dart
- widget_test.dart

- All files from [languages](lib/localization/languages)

###### **NOTE**: After all changes, please run the command - `flutter pub get`

---

# Date:- 3 July 2024

#### Added Files

- audio_space(Folder- All Files) [audio_space](lib/screens/audio_space)
- agora_token_model.dart
- agora_users_model.dart

--- Images [images](assets/images)

- audio_mic.png
- audio_room.png
- check.png
- handRaised.png
- headphone.png
- make_host.png
- mic_fill.png
- mic_slash.png
- trash.png

#### Modified Files

- Main.storyboard [Main.storyboard](ios/Runner/Base.lproj/Main.storyboard)
- build.gradle [build.gradle](android/app/build.gradle)
- pubspec.yaml [pubspec.yaml](pubspec.yaml)
- base_controller.dart
- camera_filters.dart
- chat.dart
- chatting_view.dart
- common_service.dart
- const.dart
- create_room_screen.dart
- feed_screen.dart
- feed_screen_top_bar.dart
- firebase_const.dart
- image_extension.dart
- indonesian.dart
- invite_someone_screen.dart
- languages_screen.dart
- main.dart
- my_cached_image.dart
- navigation.dart
- notification_service.dart
- on_boarding_screen.dart
- params.dart
- profile_screen.dart
- profile_verification_controller.dart
- profile_verification_screen.dart
- random_screen.dart
- report_controller.dart
- report_sheet.dart
- room_card.dart
- room_controller.dart
- room_explore_by_interests.dart
- room_sheet.dart
- rooms_by_interest_screen.dart
- rooms_you_own_screen.dart
- search_controller.dart
- search_screen.dart
- session_manager.dart
- setting_model.dart
- sign_in_with_email_screen.dart
- story_screen.dart
- top_bar.dart
- user_service.dart
- video_player_sheet.dart
- web_service.dart

--- Languages [languages](lib/localization/languages)

- languages.dart [localization](lib/localization)
- vietnamese.dart
- turkish.dart
- swedish.dart
- thai.dart
- spanish.dart
- russian.dart
- polish.dart
- portuguese.dart
- italian.dart
- japanese.dart
- korean.dart
- norwegian.dart
- french.dart
- german.dart
- greek.dart
- hindi.dart
- danish.dart
- dutch.dart
- english.dart
- chinese.dart
- arabic.dart

=======================================================

# Date:- 26 Apr 2024

#### Added Files

- banner_ad.dart
- interstitial_manager.dart
- firebase_notification_manager.dart
- subscription_manager.dart

#### Note

- notififcation_service.dart Renamed to ---- notification_service.dart

#### Modified Files

- add_post_controller.dart
- const.dart
- content_full_screen.dart
- feed_screen.dart
- invitations_model.dart
- languages.dart
- notification_screen.dart
- notification_service.dart
- Podfile.lock
- post_card.dart
- post_controller.dart
- profile_screen.dart
- profile_verification_controller.dart
- profile_verification_screen.dart
- pubspec.lock
- pubspec.yaml
- result_view.dart
- room_invitation_screen.dart
- username_controller.dart
- username_screen.dart
- video_player_sheet.dart
- session_manager.dart
- setting_controller.dart
- setting_screen.dart
- splash_controller.dart
- story.dart
- story_screen_controller.dart
- story_service.dart
- tabbar_screen.dart
- user_service.dart
- random_screen.dart
- registration.dart
- report_controller.dart
- camera_filters.dart
- chat_tag.dart
- chatting_controller.dart
- comment_card.dart
- comment_controller.dart
- edit_profile_controller.dart
- edit_profile_screen.dart
- feed_stories_controller.dart
- firebase_notification_manager.dart
- int_extension.dart
- interests_controller.dart
- languages_controller.dart
- login_controller.dart
- main.dart
- my_cached_image.dart
- AndroidManifest.xml
- banner_ad.dart
- interstitial_manager.dart
- room_controller.dart
- room_member_model.dart
- room_menu.dart
- add_post_screen.dart
- back_button.dart
- English.dart
- feed_story_screen.dart
- Russian.dart
- Spanish.dart
- Thai.dart
- Turkish.dart
- Vietnamese.dart
- build.gradle
- Danish.dart
- Double_click_like.dart
- Dutch.dart
- Finnish.dart
- French.dart
- German.dart
- Greek.dart
- Hindi.dart
- Indonesian.dart
- Italian.dart
- Japanese.dart
- Korean.dart
- Norwegian.dart
- Polish.dart
- Portuguese.dart
- Notification_service.dart
- Arabic.dart
- Chinese.dart
- Create_room_controller.dart
- Hebrew.dart
- Malay.dart
- Swedish.dart
- Norwegian.dart

  =============================================