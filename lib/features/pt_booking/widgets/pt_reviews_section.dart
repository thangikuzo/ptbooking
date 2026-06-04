import 'package:flutter/material.dart';
import 'package:ptbooking/features/pt_booking/models/review_model.dart';

class PTReviewsSection extends StatelessWidget {
  final List<ReviewModel> reviews;
  final VoidCallback onWriteReview;
  final Color primaryColor;
  final Color accentColor;

  const PTReviewsSection({
    super.key,
    required this.reviews,
    required this.onWriteReview,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Đánh giá",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            TextButton.icon(
              onPressed: onWriteReview,
              icon: Icon(Icons.edit_note, color: accentColor, size: 18),
              label: Text(
                "Viết đánh giá",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accentColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
            child: const Center(
              child: Text("Chưa có đánh giá nào. Hãy là người đầu tiên!", style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ...reviews.map(
            (review) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: review.userAvatar.isNotEmpty ? NetworkImage(review.userAvatar) : null,
                        child: review.userAvatar.isEmpty
                            ? const Icon(Icons.person, color: Colors.grey, size: 20)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          Row(
                            children: List.generate(
                              5,
                              (index) => Icon(
                                index < review.rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(review.content, style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.5)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
