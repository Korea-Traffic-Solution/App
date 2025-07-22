import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 바인딩 초기화 보장

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  await dotenv.load(fileName: 'assets/config/.env');

  // 에러 핸들링 추가
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Flutter error: ${details.exception}');
  };

  runApp(SafetyApp());
}

class SafetyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '안전 신고 앱',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // 로그인 페이지를 홈 화면으로 설정
      home: LoginScreen(
        onLoginSuccess: () {
          // 로그인 성공 시 MainScreen으로 이동
          // 이 방식은 Navigator를 사용할 수 없으므로 수정합니다
        },
      ),
      routes: {
        '/main': (context) => MainScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}