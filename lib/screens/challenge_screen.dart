import 'package:flutter/material.dart';
import '../models/challenge_model.dart';
import 'challenge_detail_screen.dart';

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Challenge> mockChallenges = [
      Challenge(
          id: 'c1',
          title: 'Hít đất 100 cái',
          description: 'Chia làm 4 set, nghỉ 30s giữa set',
          imageUrl: 'https://cdn-icons-png.flaticon.com/512/2964/2964514.png',
          points: 50
      ),
      Challenge(
          id: 'c2',
          title: 'Plank thần sầu 5 phút',
          description: 'Giữ form chuẩn, không rớt bụng',
          imageUrl: 'https://cdn-icons-png.flaticon.com/512/2964/2964514.png',
          points: 100
      ),
      Challenge(
          id: 'c3',
          title: 'Chạy bộ 5km',
          description: 'Hoàn thành dưới 30 phút (Pace 6)',
          imageUrl: 'https://cdn-icons-png.flaticon.com/512/2964/2964514.png',
          points: 200
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thử thách"),
        backgroundColor: const Color(0xFFE53935),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: mockChallenges.length, // Báo cho thợ biết có bao nhiêu cục data
        itemBuilder: (context, index) {
          // Lấy từng cái thử thách ra theo số thứ tự (index)
          final challenge = mockChallenges[index];
          // TRẢ VỀ CÁI GIAO DIỆN TẠI ĐÂY
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChallengeDetailScreen(challenge: challenge),
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 4, // Độ nổi của cái thẻ (đổ bóng)
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row( // HÀNG NGANG: Chứa Ảnh (Trái) và Chữ (Phải)
                  children: [
                    // 1. CÁI ẢNH BÊN TRÁI
                    Image.network(
                      challenge.imageUrl,
                      width: 60,
                      height: 60,
                    ),
                    const SizedBox(width: 16), // Cục gạch tạo khoảng cách
            
                    // 2. CỤM CHỮ Ở GIỮA (Dùng Expanded để nó đẩy giãn hết không gian)
                    Expanded(
                      child: Column( // CỘT DỌC: Tên nằm trên, Mô tả nằm dưới
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge.title,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            challenge.description,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
            
                    // 3. ĐIỂM THƯỞNG BÊN PHẢI CÙNG
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${challenge.points} điểm',
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}