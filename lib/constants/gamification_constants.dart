class GamificationConstants {
  // --- LEVEL REWARDS (Quà lên cấp) ---
  // Level -> Frame/Chat Border
  static const List<Map<String, dynamic>> LEVEL_REWARDS = [
    {'level': 1, 'title': 'Tân binh', 'image': 'assets/badges/bronze_1.png', 'type': 'badge'},
    {'level': 5, 'title': 'Khung Chat Cơ Bản', 'image': 'assets/frame_chat/chatborder.png', 'type': 'frame_chat'},
    {'level': 10, 'title': 'Khung Avatar Đồng', 'image': 'assets/frame_avatar/1.png', 'type': 'frame_avatar'},
    {'level': 20, 'title': 'Khung Avatar Bạc', 'image': 'assets/frame_avatar/2.png', 'type': 'frame_avatar'},
    {'level': 30, 'title': 'Khung Avatar Vàng', 'image': 'assets/frame_avatar/3.png', 'type': 'frame_avatar'},
    {'level': 40, 'title': 'Khung Avatar Bạch Kim', 'image': 'assets/frame_avatar/4.png', 'type': 'frame_avatar'},
    {'level': 50, 'title': 'Khung Avatar Huyền Thoại', 'image': 'assets/frame_avatar/5.png', 'type': 'frame_avatar'},
  ];

  // --- BATTLE PASS REWARDS ---
  static const List<Map<String, dynamic>> BATTLEPASS_REWARDS_FREE = [
    {'level': 2, 'title': 'Voucher 10%', 'discount': 10, 'type': 'voucher', 'image': 'assets/badges/bronze_1.png'},
    {'level': 5, 'title': 'Huy hiệu Nỗ lực', 'image': 'assets/badges/silver_2.png', 'type': 'badge'},
    {'level': 15, 'title': 'Khung Avatar Mùa 1', 'image': 'assets/frame_avatar/2.png', 'type': 'frame_avatar'},
  ];

  static const List<Map<String, dynamic>> BATTLEPASS_REWARDS_VIP = [
    {'level': 3, 'title': 'Voucher 20%', 'discount': 20, 'type': 'voucher', 'image': 'assets/badges/silver_1.png'},
    {'level': 5, 'title': 'Khung Avatar VIP', 'image': 'assets/frame_avatar/4.png', 'type': 'frame_avatar'},
    {'level': 10, 'title': 'Khung Chat VIP', 'image': 'assets/frame_chat/chatborder.png', 'type': 'frame_chat'},
    {'level': 20, 'title': 'Khung Avatar Legend', 'image': 'assets/frame_avatar/5.png', 'type': 'frame_avatar'},
    {'level': 35, 'title': 'Voucher 35%', 'discount': 35, 'type': 'voucher', 'image': 'assets/badges/gold_1.png'},
  ];

  // --- LEADERBOARD REWARDS (Top 1, 2, 3) ---
  static const Map<int, String> LEADERBOARD_BADGES = {
    1: 'assets/badges/gold_1.png',
    2: 'assets/badges/silver_1.png',
    3: 'assets/badges/bronze_1.png',
  };

  // --- TỔNG HỢP TOÀN BỘ KHUNG CHO TÚI ĐỒ ---
  static const List<String> ALL_AVATAR_FRAMES = [
    'assets/frame_avatar/1.png',
    'assets/frame_avatar/2.png',
    'assets/frame_avatar/3.png',
    'assets/frame_avatar/4.png',
    'assets/frame_avatar/5.png',
  ];

  static const List<String> ALL_CHAT_FRAMES = [
    'assets/frame_chat/chatborder.png',
  ];

  // Gamification EXP
  static const int EXP_TOP_1_SCORE = 50;
  static const int EXP_TOP_2_SCORE = 30;
  static const int EXP_TOP_3_SCORE = 10;
}
