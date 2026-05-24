import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh')); // Setup timezone Vietnam

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Xử lý khi user click vào thông báo
        debugPrint('Notification clicked: ${response.payload}');
      },
    );

    // Xin quyền Push Notification trên Android 13+
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  // 1. Lên lịch thông báo 8 tiếng trước khi hết ngày (16:00 hằng ngày)
  Future<void> scheduleStreakReminder() async {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 16, 0);

    // Nếu đã qua 16:00 hôm nay, hẹn sang 16:00 ngày mai
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: 1001,
      title: 'Đừng quên giữ chuỗi 🔥 nhé!',
      body: 'Chỉ còn 8 tiếng nữa là kết thúc ngày. Hãy đăng nhập để không bị mất chuỗi đăng nhập.',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_channel',
          'Nhắc nhở chuỗi đăng nhập',
          channelDescription: 'Thông báo nhắc nhở khi sắp mất chuỗi đăng nhập hằng ngày',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Lặp lại hằng ngày cùng giờ
    );
  }

  // Lên lịch thông báo khi thử thách kết thúc
  Future<void> scheduleChallengeEndNotification(String challengeName, DateTime endTime) async {
    final scheduledDate = tz.TZDateTime.from(endTime, tz.local);
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: endTime.millisecondsSinceEpoch ~/ 1000,
      title: 'Thử thách kết thúc!',
      body: 'Thử thách "$challengeName" đã kết thúc. Hãy vào app chấm điểm và trao thưởng ngay nhé!',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'challenge_end_channel',
          'Thử thách kết thúc',
          channelDescription: 'Nhắc nhở PT khi thời gian thử thách vừa hết',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // 2. Test thông báo
  Future<void> showTestNotification(String title, String body) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'test_channel',
      'Thử nghiệm',
      channelDescription: 'Kênh thông báo thử nghiệm',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: 'item x',
    );
  }

  // 3. Thông báo đẩy cho Thử thách (Lắng nghe tương tác hoặc khi thử thách kết thúc)
  Future<void> showInteractionNotification(String title, String body) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'interaction_channel',
      'Tương tác Thử thách',
      channelDescription: 'Thông báo khi có người bình luận, thích hoặc nộp bài',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecond, // ID random để không đè lên nhau
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }
}
