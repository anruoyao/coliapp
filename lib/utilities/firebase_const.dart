class FirebaseConst {
  static const pagination = 20;
  static const chats = "chats";
  static const users = "users";
  static const messages = "messages";
  static const msg = "msg";
  static const id = "id";
  static const msgType = "msgType";
  static const sentBy = "sentBy";
  static const userId = "userId";
  static const fullName = "fullName";
  static const userName = "userName";
  static const image = "image";
  static const userList = "userList";
  static const iBlocked = "iBlocked";
  static const iAmBlocked = "iAmBlocked";
  static const conversationId = "conversationId";
  static const isDeleted = "isDeleted";
  static const deletedId = "deletedId";
  static const isMuted = "isMuted";
  static const lastMsg = "lastMsg";
  static const newMsgCount = "newMsgCount";
  static const time = "time";
  static const type = "type";
  static const unreadCounts = "unreadCounts";
  static const deleteChatIds = "deleteChatIds";
}

class FirebaseAudioConst {
  static const audioSpaces = "audio_spaces";
  static const messages = "messages";
  static const id = "id";
  static const title = "title";
  static const description = "description";
  static const topics = "topics";
  static const type = "type";
  static const users = "users";
  static const profilePicture = "profilePicture";
  static const fullName = "fullName";
  static const userName = "userName";
  static const micStatus = "micStatus";
  static const isVerified = "isVerified";
  static const userId = "userId";
  static const content = "content";
  static const time = "time";
}

enum MessageType {
  text('TEXT'),
  image('IMAGE'),
  video('VIDEO'),
  storyReply('STORY_REPLY');

  const MessageType(this.value);

  final String value;
}
