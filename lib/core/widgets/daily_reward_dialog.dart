import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class DailyRewardDialog extends StatelessWidget {
  final int streak;

  const DailyRewardDialog({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    bool isBigReward = streak == 7;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context, isBigReward),
    );
  }

  Widget contentBox(BuildContext context, bool isBigReward) {
    return Stack(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.only(left: 20, top: 45, right: 20, bottom: 20),
          margin: const EdgeInsets.only(top: 45),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black, offset: Offset(0, 10), blurRadius: 10),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                isBigReward ? "Quà Khủng Ngày 7!" : "Quà Đăng Nhập Hàng Ngày",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 15),
              Text(
                "Bạn đã đăng nhập liên tục $streak ngày.",
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRewardItem("EXP", isBigReward ? "+50" : "+10", Colors.blue),
                  const SizedBox(width: 20),
                  _buildRewardItem("BP EXP", isBigReward ? "+25" : "+5", Colors.orange),
                ],
              ),
              const SizedBox(height: 22),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Nhận", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          child: Pulse(
            infinite: true,
            child: CircleAvatar(
              backgroundColor: isBigReward ? Colors.orange : Colors.blueAccent,
              radius: 45,
              child: Icon(
                isBigReward ? Icons.card_giftcard : Icons.star,
                color: Colors.white,
                size: 50,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRewardItem(String title, String amount, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Text(amount, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 5),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
