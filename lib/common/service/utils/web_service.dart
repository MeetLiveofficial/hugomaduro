import 'package:krimson/utilities/const_res.dart';

class WebService {
  static var user = _User();
  static var setting = _Setting();
  static var addPostStory = _AddPostStory();
  static var post = _Post();
  static var google = _Google();
  static var notification = _Notification();
  static var giftWallet = _GiftWallet();
  static var search = _Search();
  static var moderation = _Moderation();
  static var common = _Common();
  static var chat = _Chat();
  static var support = _Support();
  static var live = _Live();
  static var livekit = _LiveKit();
  static var call = _Call();
  static var privilege = _Privilege();
  static var task = _Task();
  static var filter = _Filter();
  static var app = _App();
}

class _App {
  String checkUpdate = "${apiURL}app/checkUpdate";
}

class _Filter {
  String list = "${apiURL}filter/list";
  String sync = "${apiURL}filter/sync";
}

class _Task {
  String list = "${apiURL}task/list";
  String claim = "${apiURL}task/claim";
  String reportProgress = "${apiURL}task/reportProgress";
  String withdrawalEligibility = "${apiURL}task/withdrawalEligibility";
}

class _Privilege {
  String hub = "${apiURL}privilege/hub";
  String dressingCatalog = "${apiURL}privilege/dressingCatalog";
  String equipDressing = "${apiURL}privilege/equipDressing";
  String honorWall = "${apiURL}privilege/honorWall";
  String leaderboard = "${apiURL}privilege/leaderboard";
}

class _Call {
  String create = "${apiURL}call/create";
  String findMatch = "${apiURL}call/findMatch";
  String joinMatch = "${apiURL}call/joinMatch";
  String leaveMatch = "${apiURL}call/leaveMatch";
  String matchHeartbeat = "${apiURL}call/matchHeartbeat";
  String inbox = "${apiURL}call/inbox";
  String status = "${apiURL}call/status";
  String accept = "${apiURL}call/accept";
  String reject = "${apiURL}call/reject";
  String cancel = "${apiURL}call/cancel";
  String end = "${apiURL}call/end";
  String extendMatch = "${apiURL}call/extendMatch";
  String matchConfig = "${apiURL}call/matchConfig";
  String unlockMatch = "${apiURL}call/unlockMatch";
  String workStats = "${apiURL}call/workStats";
  String updateCallPrice = "${apiURL}call/updateCallPrice";
  String sendComment = "${apiURL}call/sendComment";
  String fetchComments = "${apiURL}call/fetchComments";
}

class _Chat {
  String fetchThreads = "${apiURL}chat/fetchThreads";
  String fetchMessages = "${apiURL}chat/fetchMessages";
  String sendMessage = "${apiURL}chat/sendMessage";
  String updateThread = "${apiURL}chat/updateThread";
  String markRead = "${apiURL}chat/markRead";
  String translate = "${apiURL}chat/translate";
}

class _Support {
  String summary = "${apiURL}support/summary";
  String openOrGet = "${apiURL}support/openOrGet";
  String fetchMessages = "${apiURL}support/fetchMessages";
  String sendMessage = "${apiURL}support/sendMessage";
  String markRead = "${apiURL}support/markRead";
}

class _Live {
  String listActive = "${apiURL}live/listActive";
  String start = "${apiURL}live/start";
  String join = "${apiURL}live/join";
  String leave = "${apiURL}live/leave";
  String like = "${apiURL}live/like";
  String recordGift = "${apiURL}live/recordGift";
  String sendComment = "${apiURL}live/sendComment";
  String fetchComments = "${apiURL}live/fetchComments";
  String fetchSession = "${apiURL}live/fetchSession";
  String invite = "${apiURL}live/invite";
  String pendingInvites = "${apiURL}live/pendingInvites";
  String startBattle = "${apiURL}live/startBattle";
  String respondBattle = "${apiURL}live/respondBattle";
  String restartBattle = "${apiURL}live/restartBattle";
  String endBattle = "${apiURL}live/endBattle";
}

class _LiveKit {
  String token = "${apiURL}livekit/token";
}

class _Common {
  String ipApi = "http://ip-api.com/json/";
}

class _Moderation {
  String moderatorDeletePost = "${apiURL}moderator/moderator_deletePost";
  String moderatorUnFreezeUser = "${apiURL}moderator/moderator_unFreezeUser";
  String moderatorFreezeUser = "${apiURL}moderator/moderator_freezeUser";
  String moderatorDeleteStory = "${apiURL}moderator/moderator_deleteStory";
}

class _Notification {
  String fetchAdminNotifications = "${apiURL}misc/fetchAdminNotifications";
  String fetchActivityNotifications = "${apiURL}misc/fetchActivityNotifications";
  String pushNotificationToSingleUser = "${apiURL}misc/pushNotificationToSingleUser";
}

class _GiftWallet {
  String sendGift = "${apiURL}misc/sendGift";
  String fetchMyWithdrawalRequest = "${apiURL}misc/fetchMyWithdrawalRequest";
  String fetchMyRecharges = "${apiURL}misc/fetchMyRecharges";
  String fetchWalletHistory = "${apiURL}misc/fetchWalletHistory";
  String submitWithdrawalRequest = "${apiURL}misc/submitWithdrawalRequest";
  String buyCoins = "${apiURL}misc/buyCoins";
  String createCryptoPayment = "${apiURL}misc/createCryptoPayment";
  String checkCryptoPayment = "${apiURL}misc/checkCryptoPayment";
  String syncPendingCryptoPayments = "${apiURL}misc/syncPendingCryptoPayments";
  String createWompiPayment = "${apiURL}misc/createWompiPayment";
  String checkWompiPayment = "${apiURL}misc/checkWompiPayment";
  String syncPendingWompiPayments = "${apiURL}misc/syncPendingWompiPayments";
}

class _User {
  String loginInUser = "${apiURL}user/logInUser";
  String logInFakeUser = "${apiURL}user/logInFakeUser";
  String registerUser = "${apiURL}user/registerUser";
  String logInAnonymousUser = "${apiURL}user/logInAnonymousUser";
  String deleteMyAccount = "${apiURL}user/deleteMyAccount";
  String logOutUser = "${apiURL}user/logOutUser";
  String subscribePlus = "${apiURL}user/subscribePlus";
  String startKyc = "${apiURL}user/startKyc";
  String fetchUserDetails = "${apiURL}user/fetchUserDetails";
  String agencyListWorkers = "${apiURL}user/agencyListWorkers";
  String agencyCreateWorker = "${apiURL}user/agencyCreateWorker";
  String updateUserDetails = "${apiURL}user/updateUserDetails";
  String checkUsernameAvailability = "${apiURL}user/checkUsernameAvailability";
  String addUserLink = "${apiURL}user/addUserLink";
  String editeUserLink = "${apiURL}user/editeUserLink";
  String deleteUserLink = "${apiURL}user/deleteUserLink";
  String searchUsers = "${apiURL}user/searchUsers";
  String exploreStreamers = "${apiURL}user/exploreStreamers";
  String fetchMyFollowers = "${apiURL}user/fetchMyFollowers";
  String fetchUserFollowers = "${apiURL}user/fetchUserFollowers";
  String fetchUserFollowings = "${apiURL}user/fetchUserFollowings";
  String fetchMyFollowings = "${apiURL}user/fetchMyFollowings";
  String followUser = "${apiURL}user/followUser";
  String unFollowUser = "${apiURL}user/unFollowUser";
  String blockUser = "${apiURL}user/blockUser";
  String unBlockUser = "${apiURL}user/unBlockUser";
  String reportUser = "${apiURL}misc/reportUser";
  String fetchMyBlockedUsers = "${apiURL}user/fetchMyBlockedUsers";
  String updateLastUsedAt = "${apiURL}user/updateLastUsedAt";
  String impressionCatalog = "${apiURL}user/impressionCatalog";
  String impressionRate = "${apiURL}user/impressionRate";
}

class _AddPostStory {
  String addPostFeedText = "${apiURL}post/addPost_Feed_Text";
  String searchHashtags = "${apiURL}post/searchHashtags";
  String addPostFeedImage = "${apiURL}post/addPost_Feed_Image";
  String addPostFeedVideo = "${apiURL}post/addPost_Feed_Video";
  String addPostReel = "${apiURL}post/addPost_Reel";
}

class _Post {
  String fetchPostsDiscover = "${apiURL}post/fetchPostsDiscover";
  String fetchPostById = "${apiURL}post/fetchPostById";
  String fetchPostsByLocation = "${apiURL}post/fetchPostsByLocation";
  String fetchPostsNearBy = "${apiURL}post/fetchPostsNearBy";
  String fetchPostsFollowing = "${apiURL}post/fetchPostsFollowing";
  String fetchReelPostsByMusic = "${apiURL}post/fetchReelPostsByMusic";
  String fetchUserPosts = "${apiURL}post/fetchUserPosts";
  String fetchPostsByHashtag = "${apiURL}post/fetchPostsByHashtag";
  String fetchSavedPosts = "${apiURL}post/fetchSavedPosts";
  String deletePost = "${apiURL}post/deletePost";
  String increaseShareCount = "${apiURL}post/increaseShareCount";
  String increaseViewsCount = "${apiURL}post/increaseViewsCount";
  String pinPost = "${apiURL}post/pinPost";
  String unpinPost = "${apiURL}post/unpinPost";
  String likePost = "${apiURL}post/likePost";
  String disLikePost = "${apiURL}post/disLikePost";
  String savePost = "${apiURL}post/savePost";
  String unSavePost = "${apiURL}post/unSavePost";
  String reportPost = "${apiURL}misc/reportPost";
  String addPostComment = "${apiURL}post/addPostComment";
  String likeComment = "${apiURL}post/likeComment";
  String fetchPostComments = "${apiURL}post/fetchPostComments";
  String fetchPostCommentReplies = "${apiURL}post/fetchPostCommentReplies";
  String deleteComment = "${apiURL}post/deleteComment";
  String deleteCommentReply = "${apiURL}post/deleteCommentReply";
  String pinComment = "${apiURL}post/pinComment";
  String unPinComment = "${apiURL}post/unPinComment";
  String disLikeComment = "${apiURL}post/disLikeComment";
  String replyToComment = "${apiURL}post/replyToComment";
  String fetchMusicExplore = "${apiURL}post/fetchMusicExplore";
  String fetchMusicByCategories = "${apiURL}post/fetchMusicByCategories";
  String fetchSavedMusics = "${apiURL}post/fetchSavedMusics";
  String serchMusic = "${apiURL}post/serchMusic";
  String createStory = "${apiURL}post/createStory";
  String viewStory = "${apiURL}post/viewStory";
  String deleteStory = "${apiURL}post/deleteStory";
  String addUserMusic = "${apiURL}post/addUserMusic";
  String fetchStory = "${apiURL}post/fetchStory";
  String fetchStoryByID = "${apiURL}post/fetchStoryByID";
  String fetchExplorePageData = "${apiURL}post/fetchExplorePageData";
}

class _Setting {
  String fetchSettings = "${apiURL}settings/fetchSettings";
  String uploadFileGivePath = "${apiURL}settings/uploadFileGivePath";
  String deleteFile = "${apiURL}settings/deleteFile";
}

class _Google {
  String get searchTextByPlace {
    return "https://places.googleapis.com/v1/places:searchText?fields=*";
  }

  String searchNearByPlace(double lat, double lon) {
    return 'https://places.googleapis.com/v1/places:searchNearby?fields=*';
  }
}

class _Search {
  String searchPosts = "${apiURL}post/searchPosts";
}
