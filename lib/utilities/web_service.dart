import 'package:untitled/utilities/const.dart';

class WebService {
  static Moderator moderator = Moderator();
  static const String generateAgoraToken = "${apiURL}generateAgoraToken";
  static const String fetchSetting = "${apiURL}fetchSetting";
  static const String fetchPlatformNotification =
      "${apiURL}fetchPlatformNotification";
  static const String fetchUserNotification = "${apiURL}fetchUserNotification";
  static const String fetchFAQs = "${apiURL}fetchFAQs";

  static const String fetchPosts = "${apiURL}fetchPosts";
  static const String likePost = "${apiURL}likePost";
  static const String dislikePost = "${apiURL}dislikePost";
  static const String deleteMyPost = "${apiURL}deleteMyPost";
  static const String addPost = "${apiURL}addPost";
  static const String fetchPostByUser = "${apiURL}fetchPostByUser";
  static const String reportPost = "${apiURL}reportPost";
  static const String addComment = "${apiURL}addComment";
  static const String deleteComment = "${apiURL}deleteComment";
  static const String fetchComments = "${apiURL}fetchComments";
  static const String fetchPostsByHashtag = "${apiURL}fetchPostsByHashtag";
  static const String fetchPostByPostId = "${apiURL}fetchPostByPostId";
  static const String uploadFile = "${apiURL}uploadFile";
  static const String searchPost = "${apiURL}searchPost";
  static const String searchPostByInterestId =
      "${apiURL}searchPostByInterestId";
  static const String likeDislikeComment = "${apiURL}likeDislikeComment";
  static const String fetchUsersWhoLikedPost =
      "${apiURL}fetchUsersWhoLikedPost";
  static const String searchHashtag = "${apiURL}searchHashtag";

  static const String logOut = "${apiURL}logOut";
  static const String deleteUser = "${apiURL}deleteUser";
  static const String editProfile = "${apiURL}editProfile";
  static const String checkUsername = "${apiURL}checkUsername";
  static const String addUser = "${apiURL}addUser";

  // 邮箱本地化登录（替代 Firebase 邮箱认证）
  static const String emailRegister = "${apiURL}emailRegister";
  static const String emailLogin = "${apiURL}emailLogin";
  static const String resendVerification = "${apiURL}resendVerification";
  static const String forgotPassword = "${apiURL}forgotPassword";
  static const String fetchRandomProfile = "${apiURL}fetchRandomProfile";
  static const String followUser = "${apiURL}followUser";
  static const String unfollowUser = "${apiURL}unfollowUser";
  static const String fetchProfile = "${apiURL}fetchProfile";
  static const String reportUser = "${apiURL}reportUser";
  static const String profileVerification = "${apiURL}profileVerification";
  static const String searchProfile = "${apiURL}searchProfile";
  static const String fetchFollowingList = "${apiURL}fetchFollowingList";
  static const String fetchFollowersList = "${apiURL}fetchFollowersList";
  static const String userBlockedByUser = "${apiURL}UserBlockedByUser";
  static const String userUnBlockedByUser = "${apiURL}UserUnblockedByUser";
  static const String fetchBlockedUserList = "${apiURL}fetchBlockedUserList";

  static const String createRoom = "${apiURL}createRoom";
  static const String editRoom = "${apiURL}editRoom";
  static const String fetchMyOwnRooms = "${apiURL}fetchMyOwnRooms";
  static const String fetchRoomsByInterest = "${apiURL}fetchRoomsByInterest";
  static const String fetchRandomRooms = "${apiURL}fetchRandomRooms";
  static const String fetchRoomDetail = "${apiURL}fetchRoomDetail";
  static const String reportRoom = "${apiURL}reportRoom";
  static const String joinOrRequestRoom = "${apiURL}joinOrRequestRoom";
  static const String acceptInvitation = "${apiURL}acceptInvitation";
  static const String rejectInvitation = "${apiURL}rejectInvitation";
  static const String getInvitationList = "${apiURL}getInvitationList";
  static const String inviteUserToRoom = "${apiURL}inviteUserToRoom";
  static const String leaveThisRoom = "${apiURL}leaveThisRoom";
  static const String fetchRoomRequestList = "${apiURL}fetchRoomRequestList";
  static const String acceptRoomRequest = "${apiURL}acceptRoomRequest";
  static const String rejectRoomRequest = "${apiURL}rejectRoomRequest";
  static const String deleteRoom = "${apiURL}deleteRoom";
  static const String fetchRoomUsersList = "${apiURL}fetchRoomUsersList";
  static const String fetchRoomAdmins = "${apiURL}fetchRoomAdmins";
  static const String removeUserFromRoom = "${apiURL}removeUserFromRoom";
  static const String makeRoomAdmin = "${apiURL}makeRoomAdmin";
  static const String removeAdminFromRoom = "${apiURL}removeAdminFromRoom";
  static const String searchUserForInvitation =
      "${apiURL}searchUserForInvitation";
  static const String muteUnmuteRoomNotification =
      "${apiURL}muteUnmuteRoomNotification";
  static const String fetchRoomsIAmIn = "${apiURL}fetchRoomsIAmIn";

  static const String fetchStories = "${apiURL}fetchStory";
  static const String viewStory = "${apiURL}viewStory";
  static const String createStory = "${apiURL}createStory";
  static const String deleteStory = "${apiURL}deleteStory";
  static const String fetchStoryByID = "${apiURL}fetchStoryByID";

  static const String pushNotificationToSingleUser =
      "${apiURL}pushNotificationToSingleUser";

  // 本地化聊天（替代 Firestore 实时数据库）
  static const String chatGetOrCreateConversation =
      "${apiURL}chat/getOrCreateConversation";
  static const String chatSendMessage = "${apiURL}chat/sendMessage";
  static const String chatFetchMessages = "${apiURL}chat/fetchMessages";
  static const String chatFetchConversations =
      "${apiURL}chat/fetchConversations";
  static const String chatMarkAsRead = "${apiURL}chat/markAsRead";
  static const String chatSetUnread = "${apiURL}chat/setUnread";
  static const String chatClearChat = "${apiURL}chat/clearChat";
  static const String chatDeleteChat = "${apiURL}chat/deleteChat";
  static const String chatAcceptRequest = "${apiURL}chat/acceptRequest";
  static const String chatRejectRequest = "${apiURL}chat/rejectRequest";

  static const String fetchMusicWithSearch = "${apiURL}fetchMusicWithSearch";
  static const String fetchMusicCategories = "${apiURL}fetchMusicCategories";
  static const String fetchMusicByCategory = "${apiURL}fetchMusicByCategory";
  static const String fetchSavedMusic = "${apiURL}fetchSavedMusic";

  static const String uploadReel = "${apiURL}uploadReel";
  static const String fetchReelsOnExplore = "${apiURL}fetchReelsOnExplore";
  static const String fetchReelsByHashtag = "${apiURL}fetchReelsByHashtag";
  static const String fetchReelsByMusic = "${apiURL}fetchReelsByMusic";
  static const String fetchReelsByUserId = "${apiURL}fetchReelsByUserId";
  static const String fetchSavedReels = "${apiURL}fetchSavedReels";
  static const String fetchReelById = "${apiURL}fetchReelById";
  static const String searchReelsByInterestId =
      "${apiURL}searchReelsByInterestId";
  static const String likeDislikeReel = "${apiURL}likeDislikeReel";
  static const String addReelComment = "${apiURL}addReelComment";
  static const String fetchReelComments = "${apiURL}fetchReelComments";
  static const String deleteReelComment = "${apiURL}deleteReelComment";
  static const String reportReel = "${apiURL}reportReel";
  static const String increaseReelViewCount = "${apiURL}increaseReelViewCount";
  static const String deleteReel = "${apiURL}deleteReel";
}

class Moderator {
  String deletePostByModerator = "${apiURL}Moderator/deletePostByModerator";
  String deleteCommentByModerator =
      "${apiURL}Moderator/deleteCommentByModerator";
  String deleteRoomByModerator = "${apiURL}Moderator/deleteRoomByModerator";
  String deleteStoryByModerator = "${apiURL}Moderator/deleteStoryByModerator";
  String userBlockByModerator = "${apiURL}Moderator/userBlockByModerator";
  String deleteReelCommentByModerator =
      "${apiURL}Moderator/deleteReelCommentByModerator";
  String deleteReelByModerator = "${apiURL}Moderator/deleteReelByModerator";
}
