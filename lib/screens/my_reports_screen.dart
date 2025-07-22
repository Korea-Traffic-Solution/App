import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({Key? key}) : super(key: key);

  @override
  _MyReportsScreenState createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _reports = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  // 사용자의 신고 내역 가져오기
  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = '로그인이 필요합니다';
        });
        return;
      }

      // 현재 로그인된 uid 출력
      print('현재 로그인 uid: ${user.uid}');

      // 1. Report 컬렉션에서 신고 내역 가져오기 (최상위 Report 컬렉션, 본인 신고만)
      final reportsQuery = await FirebaseFirestore.instance
          .collection('Report')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final reports = reportsQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // 2. 각 신고의 id로 Conclusion 컬렉션에서 결론(result 등) 가져오기
      for (var report in reports) {
        final reportId = report['id'];
        final conclusionDoc = await FirebaseFirestore.instance
            .collection('Conclusion')
            .doc('conclusion_$reportId')
            .get();

        if (conclusionDoc.exists) {
          final conclusionData = conclusionDoc.data();
          report['result'] = conclusionData?['result'] ?? '';
          report['aiConclusion'] = conclusionData?['aiConclusion'] ?? '';
          report['region'] = conclusionData?['region'] ?? '';
          
          // 디버깅용 출력
          print('Report ID: $reportId');
          print('Region from conclusion: ${conclusionData?['region']}');
          print('Report region: ${report['region']}');
        }
      }

      setState(() {
        _reports = List<Map<String, dynamic>>.from(reports);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '신고 내역을 불러오는 데 실패했습니다: $e';
      });
      print('Error fetching reports: $e');
    }
  }

  // 신고 상태에 따른 배경색 반환
  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
      case '승인':
        return Colors.green.withOpacity(0.2);
      case 'rejected':
      case '반려':
        return Colors.red.withOpacity(0.2);
      case '미확인':
        return Colors.orange.withOpacity(0.2);
      case 'submitted':
      case '검토중':
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  // 신고 상태 한글 텍스트 반환
  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
      case '승인':
        return '승인됨';
      case 'rejected':
      case '반려':
        return '반려됨';
      case '미확인':
        return '미확인';
      case 'submitted':
      case '검토중':
      default:
        return '검토중';
    }
  }

  // 신고 상태 아이콘 반환
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
      case '승인':
        return Icons.check_circle;
      case 'rejected':
      case '반려':
        return Icons.cancel;
      case '미확인':
        return Icons.help_outline;
      case 'submitted':
      case '검토중':
      default:
        return Icons.pending;
    }
  }

  // 신고 상태 아이콘 색상 반환
  Color _getStatusIconColor(String status) {
    switch (status) {
      case 'approved':
      case '승인':
        return Colors.green;
      case 'rejected':
      case '반려':
        return Colors.red;
      case '미확인':
        return Colors.orange;
      case 'submitted':
      case '검토중':
      default:
        return Colors.grey;
    }
  }

  // 신고 상태(result) 추출 함수 수정: result 우선, 없으면 status
  String _extractResultStatus(Map<String, dynamic> report) {
    if (report['result'] != null && (report['result'] as String).isNotEmpty) {
      return report['result'] as String;
    }
    return report['status'] as String? ?? 'submitted';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 신고 내역', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _reports.isEmpty
                  ? const Center(child: Text('신고 내역이 없습니다'))
                  : RefreshIndicator(
                      onRefresh: _fetchReports,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          final report = _reports[index];
                          // 기존 status 추출 부분을 아래처럼 변경
                          final status = _extractResultStatus(report);
                          final createdAt = report['createdAt'] as Timestamp?;

                          final dynamic dateRaw = report['date'];
                          String dateString = '날짜 정보 없음';

                          if (dateRaw is Timestamp) {
                            dateString = DateFormat('yyyy년 MM월 dd일 HH:mm').format(dateRaw.toDate());
                          } else if (dateRaw is String) {
                            dateString = dateRaw;
                          } else if (dateRaw is List) {
                            dateString = '잘못된 날짜 데이터'; // 혹은 빈 문자열 etc.
                          } else if (createdAt != null) {
                            dateString = DateFormat('yyyy년 MM월 dd일 HH:mm').format(createdAt.toDate());
                          }

                          final date = dateString;

                          final dynamic violationRaw = report['violation'];
                          String violationText;
                          if (violationRaw is List) {
                            violationText = violationRaw.join(', ');
                          } else if (violationRaw is String) {
                            violationText = violationRaw;
                          } else {
                            violationText = '위반 사항 정보 없음';
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16.0),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: _getStatusColor(status),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 이미지가 있다면 표시
                                  if (report['imageUrl'] != null)
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                      child: Image.network(
                                        report['imageUrl'] as String,
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
                                                _getStatusText(status),
                                                style: TextStyle(
                                                  color: _getStatusIconColor(status),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              avatar: Icon(
                                                _getStatusIcon(status),
                                                color: _getStatusIconColor(status),
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
                                        
                                        // 장소 정보
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, 
                                              color: Colors.orange, 
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                (report['region'] as String?)?.isNotEmpty == true
                                                    ? report['region'] as String
                                                    : '위치 정보 없음',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        
                                        // 위반 사항 정보
                                        Text(
                                          violationText,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        
                                        // 반려된 경우 반려 사유 표시
                                        if (status == 'rejected' && report['rejectionReason'] != null)
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
                                                    report['rejectionReason'] as String,
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
                        },
                      ),
                    ),
    );
  }
}