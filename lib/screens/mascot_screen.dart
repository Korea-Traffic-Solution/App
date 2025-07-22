import 'package:flutter/material.dart';

class Mascot_Screen extends StatefulWidget {
  const Mascot_Screen({Key? key}) : super(key: key);

  @override
  _Mascot_ScreenState createState() => _Mascot_ScreenState();
}

class _Mascot_ScreenState extends State<Mascot_Screen> {
  // 현재 선택된 가이드 페이지
  int _currentGuideIndex = 0;
  
  // 가이드 페이지 컨트롤러
  final PageController _pageController = PageController();
  
  // 가이드 데이터
  final List<Map<String, dynamic>> _guidePages = [
    {
      'title': '잡았다 킥라니에 오신 것을 환영합니다',
      'description': '이 앱은 공용 킥보드 등의 안전 위반 사항을 신고하고 관리하는 앱입니다.',
      'icon': Icons.security,
      'color': Colors.green,
    },
    {
      'title': '신고하기',
      'description': '위법 상황을 발견하셨나요? 사진을 찍고 위치와 상세 내용을 입력하여 신고해 주세요.',
      'icon': Icons.report_problem,
      'color': Colors.orange,
    },
    {
      'title': 'AI 챗봇',
      'description': '궁금한 법률이나 벌금 정보를 챗봇에게 물어보세요. 쉽고 빠르게 법적 안내를 제공합니다.',
      'icon': Icons.smart_toy,
      'color': Colors.blue,
    },
    {
      'title': '관련 뉴스',
      'description': '공용 킥보드과 관련된 최신 뉴스와 정보를 확인할 수 있습니다.',
      'icon': Icons.article,
      'color': Colors.yellow,
    },
    {
      'title': '내 신고',
      'description': '내가 제출한 신고 내역과 처리 상태를 확인할 수 있습니다.',
      'icon': Icons.history,
      'color': Colors.purple,
    },
    {
      'title': '안전 신고 가이드라인',
      'description': '명확한 증거 사진과 정확한 위치 정보가 제공될 경우 신고가 빠르게 처리됩니다.',
      'icon': Icons.help_outline,
      'color': Colors.teal,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  // 상세 사용 설명서 보기
  void _showDetailedGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        '안전 신고 앱 사용 설명서',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildGuideSection(
                      '앱 사용의 목적',
                      '이 앱은 공유 킥보드 및 기타 모빌리티 서비스 이용 시 발생하는 안전 위반 사항을 신고하고 관리하기 위한 서비스입니다. 시민들의 적극적인 참여로 더 안전한 도시 환경을 만들어 나갈 수 있습니다.',
                      Icons.emoji_objects,
                    ),
                    _buildGuideSection(
                      '신고 방법',
                      '1. 하단 메뉴에서 \'신고하기\' 탭을 선택합니다.\n'
                      '2. 위반 사항을 목격한 날짜를 선택합니다.\n'
                      '3. 위치 정보를 입력합니다. (현재 위치 가져오기 기능 활용 가능)\n'
                      '4. 위반 상황이 명확하게 보이는 사진을 첨부합니다.\n'
                      '5. 위반 유형을 선택하고 필요한 경우 상세 내용을 입력합니다.\n'
                      '6. 미리보기로 내용을 확인한 후 신고 버튼을 누릅니다.',
                      Icons.report_problem,
                    ),
                    _buildGuideSection(
                      '주요 위반 유형',
                      '• 안전모 미착용: 헬멧 없이 주행하는 경우\n'
                      '• 2인 탑승: 1인용 이동 수단에 2명 이상 탑승',
                      Icons.warning_amber,
                    ),
                    _buildGuideSection(
                      '신고 처리 과정',
                      '1. 신고 접수: 제출된 신고는 시스템에 등록됩니다.\n'
                      '2. 검토 과정: 담당자가 내용과 증거 사진을 검토합니다.\n'
                      '3. 처리 결정: 검토 결과에 따라 승인 또는 반려 처리됩니다.\n'
                      '4. 결과 통보: 처리 결과는 \'내 신고\' 탭에서 확인할 수 있습니다.',
                      Icons.sync,
                    ),
                    _buildGuideSection(
                      '관련 뉴스 확인',
                      '\'관련뉴스\' 탭에서는 공유 킥보드와 모빌리티 안전에 관한 최신 뉴스와 정보를 확인할 수 있습니다. 정기적으로 업데이트되는 콘텐츠를 통해 안전 정보를 얻으세요.',
                      Icons.article,
                    ),
                    _buildGuideSection(
                      '신고 내역 확인',
                      '\'내 신고\' 탭에서 본인이 제출한 모든 신고 내역과 처리 상태를 확인할 수 있습니다. 승인된 신고는 녹색, 반려된 신고는 빨간색, 검토 중인 신고는 회색으로 표시됩니다.',
                      Icons.history,
                    ),
                    _buildGuideSection(
                      '신고 시 주의사항',
                      '• 명확한 증거 사진을 첨부해주세요.\n'
                      '• 정확한 위치 정보를 제공해주세요.\n'
                      '• 허위 신고는 법적 책임이 따를 수 있습니다.\n'
                      '• 개인정보 보호를 위해 신고 내용에 개인을 특정할 수 있는 정보는 포함하지 마세요.\n'
                      '• 긴급 상황이나 범죄 행위는 경찰(112)이나 소방서(119)로 신고해주세요.',
                      Icons.help_outline,
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('확인'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // 가이드 섹션 위젯
  Widget _buildGuideSection(String title, String content, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8FFDB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              _showDetailedGuide(context);
            },
            icon: const Icon(Icons.info_outline, color: Colors.green),
            label: const Text(
              '상세 설명',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 마스코트 이미지 - 간단한 구조로 변경
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Image.asset(
              'assets/images/01.png',
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
          
          // 가이드 슬라이더
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // 페이지 인디케이터
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _guidePages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentGuideIndex == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentGuideIndex == index
                              ? _guidePages[index]['color']
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 가이드 페이지 슬라이더
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentGuideIndex = index;
                        });
                      },
                      itemCount: _guidePages.length,
                      itemBuilder: (context, index) {
                        final guide = _guidePages[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: guide['color'].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  guide['icon'],
                                  size: 50,
                                  color: guide['color'],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                guide['title'],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      guide['description'],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // 버튼 영역
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            if (_currentGuideIndex > 0) {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          child: Text(
                            '이전',
                            style: TextStyle(
                              color: _currentGuideIndex > 0
                                  ? Colors.black87
                                  : Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (_currentGuideIndex < _guidePages.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              // 마지막 페이지에서는 신고하기 화면으로 이동
                              Navigator.of(context).pushReplacementNamed('/report');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _guidePages[_currentGuideIndex]['color'],
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            _currentGuideIndex < _guidePages.length - 1
                                ? '다음'
                                : '끝',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}