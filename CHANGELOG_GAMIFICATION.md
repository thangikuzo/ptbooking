# BẢNG TỔNG HỢP THAY ĐỔI (CHANGELOG) - TÍNH NĂNG GAMIFICATION THỬ THÁCH

File này được tạo ra để giúp nhóm dễ dàng đối chiếu và giải quyết conflict (nếu có) khi merge code. Dưới đây là danh sách toàn bộ các file đã bị thay đổi (MODIFIED) và tạo mới (NEW) so với bản gốc ban đầu.

---

## 🟡 CÁC FILE BỊ THAY ĐỔI (MODIFIED)

### 1. `lib/models/user_model.dart`
- **Thay đổi:** 
  - Thêm các trường dữ liệu phục vụ Gamification: `level`, `exp`, `bpLevel`, `bpExp`, `isVip`, `lastLogin`, `loginStreak`.
  - Thêm các trường tương tác PT: `following`, `rating`, `followerCount`, và **`challengeCount`** (Đếm số thử thách PT đã tạo).

### 2. `lib/services/gamification_service.dart`
- **Thay đổi:**
  - Cập nhật logic để **chặn hoàn toàn** việc cộng EXP, cộng Quà và lên cấp đối với tài khoản có `role` là 'PT' hoặc 'Admin'.
  - Thay đổi công thức tính mốc lên cấp: `Max EXP = Level * 500`.
  - Cập nhật vòng lặp `while (currentExp >= maxExp)` để xử lý việc User nhảy vọt 2-3 cấp cùng lúc nếu lượng EXP nhận vào quá lớn.

### 3. `lib/screens/account_screen.dart`
- **Thay đổi:**
  - Ẩn hoàn toàn thanh hiển thị Level, EXP, BP Level trên Header đối với tài khoản PT.
  - Cập nhật giao diện Header sang màu Gradient Xanh Lá - Trắng, kèm bóng đổ mượt mà.
  - Thêm mục Menu "Phần thưởng cấp độ" (Chỉ hiện cho User).
  - Ẩn thẻ "Thẻ Battle Pass" đối với PT.

### 4. `lib/screens/battle_pass_screen.dart`
- **Thay đổi:**
  - Cập nhật giao diện toàn diện sang tone màu Trắng - Xanh ngọc.
  - Sửa lại bảng màu quà tặng và sử dụng hình ảnh từ thư mục `assets/` (Khung avatar, huy hiệu, viền chat, voucher).

### 5. `lib/screens/leaderboard_screen.dart`
- **Thay đổi:**
  - Giao diện Header bo góc, Gradient Xanh Lá.
  - Cập nhật UI hiển thị phần thưởng đạt được của Top 3 dưới tên của họ.
  - Sửa lại thuật toán chia thưởng: Tab "Yêu thích" nhận thưởng EXP bằng đúng một nửa (`1/2`) so với Tab "Chuyên môn".

### 6. `lib/screens/pt_ranking_screen.dart`
- **Thay đổi:**
  - Cấu trúc thành 3 Tab: Top Đánh giá (Rating), Top Theo dõi (Followers), và Năng nổ nhất (Challenge Count).
  - Áp dụng UI Gradient Xanh-Trắng mới mẻ, làm nổi bật màu sắc Cúp cho Top 1, 2, 3.

### 7. `lib/screens/notification_screen.dart`
- **Thay đổi:**
  - Áp dụng UI Gradient Xanh-Trắng.
  - Fix lỗi hiển thị Stream bằng cách bắt lỗi `snapshot.hasError` và rà soát kỹ logic đọc Real-time.

### 8. `lib/screens/pt_create_challenge_screen.dart`
- **Thay đổi:** Thêm logic `FieldValue.increment(1)` vào trường `challengeCount` của PT khi tạo thử thách.

---

## 🟢 CÁC FILE ĐƯỢC TẠO MỚI (NEW)

- **Mới:** Xây dựng màn hình Timeline dọc mô tả lộ trình lên Cấp độ và phần thưởng. Áp dụng hiệu ứng xám đi (Grayscale) cho các phần thưởng chưa mở khóa và load ảnh vật phẩm từ `assets/`.

### 2. `lib/constants/gamification_constants.dart`
- **Mới:** Quản lý toàn bộ dữ liệu phần thưởng thật (level, battlepass, leaderboard rewards) mapping với thư mục `assets/`.

### 3. `lib/screens/inventory_screen.dart`
- **Mới:** Màn hình Kho đồ cho phép người dùng chọn Khung Avatar và Khung Chat đã mở khóa.

### 4. `lib/screens/achievement_screen.dart`
- **Mới:** Màn hình Bảng thành tích hiển thị các Huy hiệu (Badges) đã đạt được từ các Thử thách.

---

## 🔵 CÁC FILE ĐƯỢC CẬP NHẬT LỚN (GIAI ĐOẠN 2)

### 1. `lib/models/user_model.dart`
- **Thay đổi:** Thêm các mảng và biến cho Kho đồ và Thành tích (`unlockedFrames`, `unlockedChatFrames`, `unlockedBadges`, `selectedFrame`, `selectedChatFrame`).

### 2. `lib/screens/challenge_detail_screen.dart`
- **Thay đổi:**
  - Thêm chức năng hiển thị **Hộp quà** xem phần thưởng ở AppBar.
  - Sửa AppBar sang màu Gradient Xanh - Trắng.
  - Thêm nút "TRAO THƯỞNG & KẾT THÚC" dành riêng cho PT tạo thử thách (khi thời gian Đã kết thúc).
  - Viết logic hàm `_distributeRewards()`: Sắp xếp điểm submissions, tặng Huy hiệu (Top 1, 2, 3) và EXP thẳng vào Data của User, cập nhật cờ `isRewardsDistributed`.

### 3. `lib/screens/leaderboard_screen.dart`
- **Fix lỗi:** Sửa lỗi hiển thị người chơi lạ bằng cách thêm câu truy vấn lọc `.where('challengeId', isEqualTo: widget.challengeTitle)`.

### 4. `lib/widgets/main_wrapper.dart` & `lib/screens/challenge_screen.dart`
- **Đồng bộ UI:** Chấm đỏ thông báo sẽ hiển thị trực tiếp ở icon Thử thách trong thanh BottomNavigationBar và ở hình cái chuông trong AppBar (Màu đỏ tươi).

### 5. `lib/models/challenge_model.dart`
- **Thay đổi:** Thêm cờ `isRewardsDistributed` để xác nhận thử thách đã được trao thưởng xong.

---

## 🟣 CÁC FILE ĐƯỢC CẬP NHẬT LỚN (GIAI ĐOẠN 3)

### 1. `lib/screens/challenge_detail_screen.dart`
- **Thay đổi:**
  - Sửa lỗi `RenderFlex Overflow` do thiếu ảnh fallback ở Hộp Quà, thêm `errorBuilder`.
  - Cập nhật UI chấm điểm: Thay vì nhập số thủ công, hiển thị **Custom Dialog 4 tiêu chí** (Biên độ, Tư thế, Kiểm soát, Hoàn thành), mỗi cột 10 ô vuông tương tác. Điểm trung bình được tự động tính.
  - Sửa logic trao thưởng: Sau khi tính điểm và trao phần thưởng, hệ thống sẽ **xóa sạch toàn bộ bài nộp (submissions)** và **xóa luôn thử thách** khỏi Database.

### 2. `lib/screens/challenge_screen.dart`
- **Thay đổi:**
  - Thêm icon mở `PTRankingScreen` trên góc phải `AppBar`.
  - Bổ sung logic tự động quét các thử thách đã kết thúc nhưng chưa trao thưởng (khi PT vào màn hình), từ đó gửi **thông báo nhắc nhở PT**.

### 3. `lib/screens/edit_profile_screen.dart`
- **Thay đổi:**
  - Nâng cấp phần hiển thị Avatar, cho phép **bọc Khung Avatar (Frame)** đang chọn đè lên trên ảnh đại diện.
  - Thêm nút chuyển hướng nhanh sang màn hình **Túi Đồ** (Inventory).

### 4. `lib/screens/inventory_screen.dart`
- **Thay đổi:**
  - Cập nhật toàn diện hiển thị **TẤT CẢ** các khung avatar và khung chat có trong game.
  - Áp dụng UI phủ mờ và icon Lock 🔒 đè lên trên các vật phẩm PT hoặc User chưa sở hữu, ngăn tương tác.

### 5. `lib/screens/achievement_screen.dart`
- **Thay đổi:**
  - Nâng cấp lưới GridView, giờ đây mỗi huy hiệu sẽ đi kèm **Tên thử thách** bên dưới để gợi nhớ thành tích. Hiển thị ảnh `assets/` chuẩn thay vì Icon mặc định.

### 6. Toàn hệ thống
- **Fix lỗi:** Rà soát và sử dụng đồng bộ dữ liệu ảnh thật trong thư mục `assets/` cho mọi phần thưởng (Badge, Frame Avatar, Frame Chat). Loại bỏ triệt để các Icon thay thế tạm bợ.

---

## 🟤 CÁC FILE ĐƯỢC CẬP NHẬT LỚN (GIAI ĐOẠN 4, 5, 6)

### 1. `lib/services/notification_service.dart` (NEW)
- **Tạo mới:** Khởi tạo thư viện `flutter_local_notifications` v21.0.0. Xây dựng hàm `scheduleStreakReminder()` để đẩy thông báo giữ chuỗi vào lúc 16:00 hằng ngày. 
- Xây dựng hàm `scheduleChallengeEndNotification()` đặt giờ tự động dựa theo `endTime` của thử thách.

### 2. `android/app/build.gradle.kts`
- **Thay đổi (Hotfix):** Bật `isCoreLibraryDesugaringEnabled` và bổ sung phụ thuộc `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` để hỗ trợ API Java 8+ cần thiết cho Scheduled Notifications trên nền tảng Android cũ.

### 3. `lib/models/user_model.dart`
- **Thay đổi:** Thêm mảng `unlockedVouchers` để lưu trữ danh sách các Voucher giảm giá thu thập được.

### 4. `lib/services/gamification_service.dart`
- **Thay đổi:** Cập nhật hàm trả thưởng của Battle Pass và Level Up, quét các phần thưởng có chứa từ khóa 'Voucher' để đẩy vào mảng `unlockedVouchers` của người dùng. Cài đặt luật: Voucher >= 30% có hạn 30 ngày, < 30% vĩnh viễn.

### 5. `lib/screens/inventory_screen.dart`
- **Thay đổi:** Thêm Tab mới "Voucher". Xây dựng UI danh sách Voucher dạng thẻ. Tích hợp `qr_flutter` hiển thị Modal quét mã QR tặng/sử dụng Voucher kèm hạn sử dụng trực quan.

### 6. `lib/screens/chat_screen.dart` (Các Widget liên quan)
- **Thay đổi:** Áp dụng kỹ thuật 9-Patch `centerSlice` vào trang trí Khung Chat (`DecorationImage`). Loại bỏ màu nền cam mặc định khi tin nhắn được gắn Khung Chat, giúp khung bám khít đoạn text mà không bị méo góc bo tròn.

### 7. `lib/screens/challenge_detail_screen.dart`
- **Thay đổi:** 
  - Khóa toàn bộ các thao tác tương tác của User (Tham gia, Nộp bài, Bình luận, Thả tim) nếu `DateTime.now().isAfter(endTime)`. 
  - PT chỉ có thể chấm điểm khi trạng thái là Đã kết thúc.

### 8. `lib/screens/dev_tool_screen.dart`
- **Thay đổi:** Cập nhật UI đồng bộ sử dụng `ElevatedButton.icon`. Bổ sung nút "Test Thông báo Đẩy (Streak)" cho phép giả lập bắn Push Notification sau 3 giây.
