import 'package:flutter/material.dart';

class ReportItem extends StatelessWidget {
  final String title;
  final String description;
  final String status;
  final String date;
  final String? imageUrl;
  final String? rejectionReason;

  const ReportItem({
    Key? key,
    required this.title,
    required this.description,
    this.status = 'submitted',
    required this.date,
    this.imageUrl,
    this.rejectionReason,
  }) : super(key: key);

  // 신고 상태에 따른 배경색 반환
  Color _getStatusColor() {
    switch (status) {
      case 'approved':
        return Colors.green.withOpacity(0.2);
      case 'rejected':
        return Colors.red.withOpacity(0.2);
      case 'submitted':
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  // 신고 상태 한글 텍스트 반환
  String _getStatusText() {
    switch (status) {
      case 'approved':
        return '승인됨';
      case 'rejected':
        return '반려됨';
      case 'submitted':
      default:
        return '검토중';
    }
  }

  // 신고 상태 아이콘 반환
  IconData _getStatusIcon() {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'submitted':
      default:
        return Icons.pending;
    }
  }

  // 신고 상태 아이콘 색상 반환
  Color _getStatusIconColor() {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'submitted':
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _getStatusColor(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지가 있다면 표시
            if (imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상태 표시 행
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 날짜 표시
                      Expanded(
                        child: Text(
                          date,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      // 상태 표시 칩
                      Chip(
                        label: Text(
                          _getStatusText(),
                          style: TextStyle(
                            color: _getStatusIconColor(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        avatar: Icon(
                          _getStatusIcon(),
                          color: _getStatusIconColor(),
                          size: 18,
                        ),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // 제목
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // 내용
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14),
                  ),
                  
                  // 반려된 경우 반려 사유 표시
                  if (status == 'rejected' && rejectionReason != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '반려 사유:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rejectionReason!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}