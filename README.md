# ⚡ PTBooking – The Ultimate Fitness Challenge Platform

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Firebase-%23039BE5.svg?style=for-the-badge&logo=firebase" alt="Firebase">
  <img src="https://img.shields.io/badge/Cloudinary-%233448C5.svg?style=for-the-badge&logo=Cloudinary&logoColor=white" alt="Cloudinary">
</p>

**PTBooking** là hệ sinh thái kết nối **Personal Trainer (PT)** và **Học viên** thông qua các thử thách thể chất thời gian thực. Dự án tập trung vào tính minh bạch trong chấm điểm và trải nghiệm người dùng mượt mà.

---

## 🚀 Tính Năng Cốt Lõi

### 1. 🛡️ Phân Quyền Thông Minh (RBAC)
* **Học viên:** Tham gia thử thách, quay video và nộp bài trực tiếp qua Cloud.
* **PT (Chuyên gia):** Độc quyền quyền hạn chấm điểm, quản lý nội dung và phê duyệt bài tập.

### 2. 📹 Cloud Video Streaming
* Tích hợp **Cloudinary API** giúp tối ưu hóa dung lượng và tốc độ truyền tải video.
* Hệ thống xử lý video bài tập không gây tải cho server nội bộ.

### 3. 🏆 Đấu Trường Leaderboard
* Bảng xếp hạng thời gian thực sắp xếp theo điểm số chuyên môn.
* Hệ thống vinh danh **Top 3** với giao diện Huy chương (Vàng, Bạc, Đồng) trực quan.

### 4. ⚡ Tối Ưu Hóa Hiệu Năng
* Xử lý mượt mà danh sách video dài bằng cơ chế **Lazy Loading**.
* Quản lý bộ nhớ (Memory Management) tối ưu cho các thiết bị di động tầm trung.

---

## 🛠️ Công Nghệ Sử Dụng

| Layer | Technology |
| :--- | :--- |
| **Frontend** | Flutter (Dart) |
| **Backend** | Firebase Auth, Cloud Firestore |
| **Video Storage** | Cloudinary CDN |
| **State Mgmt** | Stateful & Local Persistence |

---

## 💻 Hướng Dẫn Cài Đặt

1.  **Clone dự án:**
    ```bash
    git clone [https://github.com/thangikuzo/ptbooking.git](https://github.com/thangikuzo/ptbooking.git)
    ```
2.  **Cài đặt thư viện:**
    ```bash
    flutter pub get
    ```
3.  **Chạy ứng dụng:**
    ```bash
    flutter run
    ```

---

## 🤝 Core Developers (Co-Founders)
* **Hoàng Thái Tú**
* **Nguyễn Đức Hảo**
* **Trần Nguyễn Hữu Thắng**

---
<p align="center">
  <i>"Transforming sweat into data. Every rep counts."</i>
</p>
