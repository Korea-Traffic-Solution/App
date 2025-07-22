import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NewsItem {
  final String title;
  final String imageUrl;
  final String newsUrl;
  final String date;
  final String source;

  NewsItem({
    required this.title,
    required this.imageUrl,
    required this.newsUrl,
    required this.date,
    required this.source,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      title: _decodeHtmlEntities(_removeHtmlTags(json['title'] ?? '')),
      imageUrl: json['imageUrl'] ?? 'https://via.placeholder.com/150',
      newsUrl: json['link'] ?? '',
      date: _formatDate(json['pubDate'] ?? ''),
      source: json['source'] ?? '네이버 뉴스',
    );
  }

  // HTML 태그 제거 헬퍼 함수
  static String _removeHtmlTags(String htmlText) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlText.replaceAll(exp, '');
  }
  static String _decodeHtmlEntities(String text) {
  return text
      .replaceAll('&quot;', '"')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&apos;', "'")
      .replaceAll('&#x27;', "'")
      .replaceAll('&#x2F;', '/')
      .replaceAll('&#39;', "'")
      .replaceAll('&#47;', '/');
}

  // 날짜 형식 변환 헬퍼 함수
  static String _formatDate(String apiDate) {
    try {
      final date = DateTime.parse(apiDate);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return apiDate;
    }
  }
}

class NewsApiService {
  static Future<List<NewsItem>> fetchNews(String keyword) async {
    try {
      // .env 파일에서 API 키를 가져옵니다
      final clientId = dotenv.env['NAVER_CLIENT_ID'];
      final clientSecret = dotenv.env['NAVER_CLIENT_SECRET'];
      
      // API 키가 없으면 더미 데이터 반환
      if (clientId == null || clientSecret == null) {
        print('API 키가 설정되지 않았습니다. 더미 데이터를 반환합니다.');
        return _getDummyNewsData();
      }
      
      final url = Uri.parse('https://openapi.naver.com/v1/search/news.json?query=${Uri.encodeComponent(keyword)}&display=10&sort=date');
      
      final response = await http.get(
        url,
        headers: {
          'X-Naver-Client-Id': clientId,
          'X-Naver-Client-Secret': clientSecret,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        return items.map((item) => NewsItem.fromJson(item)).toList();
      } else {
        print('API 응답 오류: ${response.statusCode}');
        return _getDummyNewsData();
      }
    } catch (e) {
      print('네트워크 오류: $e');
      return _getDummyNewsData();
    }
  }

  // 더미 뉴스 데이터 (API 연결 전 테스트용)
  static List<NewsItem> _getDummyNewsData() {
    return [
      NewsItem(
        title: '공유 킥보드 이용자 안전수칙 강화... 헬멧 착용 의무화',
        imageUrl: 'https://via.placeholder.com/150',
        newsUrl: 'https://www.example.com/news/1',
        date: '2023-03-20',
        source: '교통안전공단',
      ),
      NewsItem(
        title: '서울시, 공유 킥보드 전용 주차구역 400곳 추가 설치',
        imageUrl: 'https://via.placeholder.com/150',
        newsUrl: 'https://www.example.com/news/2',
        date: '2023-03-18',
        source: '서울신문',
      ),
      NewsItem(
        title: '공유 킥보드 사고 증가... 안전교육 필요성 제기',
        imageUrl: 'https://via.placeholder.com/150',
        newsUrl: 'https://www.example.com/news/3',
        date: '2023-03-15',
        source: '안전뉴스',
      ),
      NewsItem(
        title: '킥보드 음주운전 적발 시 면허취소 법안 발의',
        imageUrl: 'https://via.placeholder.com/150',
        newsUrl: 'https://www.example.com/news/4',
        date: '2023-03-12',
        source: '법률신문',
      ),
      NewsItem(
        title: '공유 킥보드 업체, 헬멧 무료 대여 서비스 시작',
        imageUrl: 'https://via.placeholder.com/150',
        newsUrl: 'https://www.example.com/news/5',
        date: '2023-03-10',
        source: '모빌리티 타임즈',
      ),
      NewsItem(
        title: '한국도로공사, 도로 위 공유 킥보드 안전 가이드라인 발표',
        imageUrl: 'https://via.placeholder.com/150',
        newsUrl: 'https://www.example.com/news/6',
        date: '2023-03-08',
        source: '도로교통공단',
      ),
      NewsItem(
        title: '공유 킥보드 배터리 안전성 검사 강화',
        imageUrl: 'https://via.placeholder.com/150',
        newsUrl: 'https://www.example.com/news/7',
        date: '2023-03-05',
        source: '전자신문',
      ),
      NewsItem(
        title: '야간 킥보드 이용 시 발광 조끼 착용 권고',
        imageUrl: 'https://via.placeholder.com/150',
        newsUrl: 'https://www.example.com/news/8',
        date: '2023-03-03',
        source: '국민일보',
      ),
      NewsItem(
        title: '대학가 주변 공유 킥보드 주차 문제 심각',
        imageUrl: 'https://via.placeholder.com/150',
        newsUrl: 'https://www.example.com/news/9',
        date: '2023-03-01',
        source: '대학신문',
      ),
      NewsItem(
        title: '겨울철 공유 킥보드 사고 증가, 노면 관리 강화',
        imageUrl: 'https://via.placeholder.com/150',
        newsUrl: 'https://www.example.com/news/10',
        date: '2023-02-28',
        source: '기상신문',
      ),
    ];
  }
}