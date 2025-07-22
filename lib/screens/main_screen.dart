import 'package:flutter/material.dart';
import 'mascot_screen.dart';
import 'report_violation_screen.dart';
import 'chat_screen.dart'; 
import 'safety_news_screen.dart';
import 'my_reports_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;
  
  // 각 탭에 대한 아이콘 애니메이션 컨트롤러 리스트 (5개로 증가)
  late List<AnimationController> _iconAnimationControllers;
  
  // 애니메이션된 아이콘들
  List<Widget> _animatedIcons = [];
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    
    // 전환 애니메이션 컨트롤러
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // 아이콘 애니메이션 컨트롤러 초기화 (5개로 증가)
    _iconAnimationControllers = List.generate(
      5,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );
    
    // 첫 번째 아이콘 애니메이션 시작
    _iconAnimationControllers[_selectedIndex].forward();
    
    // 애니메이션된 아이콘 위젯 생성
    _createAnimatedIcons();
  }
  
  void _createAnimatedIcons() {
    final iconData = [
      Icons.home, 
      Icons.report_problem, 
      Icons.smart_toy_rounded, // AI 챗봇 아이콘 (중간에 위치)
      Icons.article, 
      Icons.history
    ];
    final labels = ['설명서', '신고하기', 'AI 챗봇', '관련뉴스', '내 신고'];
    
    _animatedIcons = List.generate(
      5,
      (index) {
        final sizeAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
          CurvedAnimation(
            parent: _iconAnimationControllers[index],
            curve: Curves.easeInOut,
          ),
        );
        
        return AnimatedBuilder(
          animation: _iconAnimationControllers[index],
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: sizeAnimation.value,
                  child: Icon(
                    iconData[index],
                    // AI 챗봇 아이콘의 경우 다른 색상 적용
                    color: index == 2 && _selectedIndex == index 
                        ? const Color(0xFF4A90E2) 
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  labels[index],
                  style: TextStyle(
                    // AI 챗봇 텍스트의 경우 다른 색상 적용
                    color: index == 2 && _selectedIndex == index 
                        ? const Color(0xFF4A90E2) 
                        : null,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    for (var controller in _iconAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  void _onItemTapped(int index) {
    // 이전 아이콘 애니메이션 되돌리기
    _iconAnimationControllers[_selectedIndex].reverse();
    
    setState(() {
      _selectedIndex = index;
    });
    
    // PageView 애니메이션으로 전환
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    // 새 아이콘 애니메이션 시작
    _iconAnimationControllers[index].forward();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageTransitionSwitcher(
        transitionBuilder: (
          Widget child,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // 스와이프 비활성화
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          children: [
            Mascot_Screen(key: UniqueKey()),
            ReportViolationScreen(key: UniqueKey()),
            ChatScreen(key: UniqueKey()), // AI 챗봇 화면 추가 (중간에 위치)
            SafetyNewsScreen(key: UniqueKey()),
            MyReportsScreen(key: UniqueKey()),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: _animatedIcons[0],
              label: '',
            ),
            BottomNavigationBarItem(
              icon: _animatedIcons[1],
              label: '',
            ),
            BottomNavigationBarItem(
              icon: _animatedIcons[2], // AI 챗봇 아이콘 (중간에 위치)
              label: '',
            ),
            BottomNavigationBarItem(
              icon: _animatedIcons[3],
              label: '',
            ),
            BottomNavigationBarItem(
              icon: _animatedIcons[4],
              label: '',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
    );
  }
}

// 페이지 전환을 위한 FadeThroughTransition 클래스
class FadeThroughTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  const FadeThroughTransition({
    Key? key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      builder: (context, child) {
        final value = animation.value;
        final secondaryValue = secondaryAnimation.value;
        
        final fadeIn = CurveTween(curve: const Interval(0.5, 1.0)).transform(value);
        final fadeOut = CurveTween(curve: const Interval(0.0, 0.5)).transform(secondaryValue);
        
        return Stack(
          children: [
            FadeTransition(
              opacity: AlwaysStoppedAnimation<double>(1.0 - fadeOut),
              child: secondaryAnimation.status == AnimationStatus.completed 
                  ? const SizedBox.shrink() 
                  : this.child,
            ),
            FadeTransition(
              opacity: AlwaysStoppedAnimation<double>(fadeIn),
              child: animation.status == AnimationStatus.dismissed 
                  ? const SizedBox.shrink() 
                  : child,
            ),
          ],
        );
      },
      child: child,
    );
  }
}

// PageTransitionSwitcher 클래스
class PageTransitionSwitcher extends StatefulWidget {
  final Widget child;
  final Widget Function(Widget, Animation<double>, Animation<double>) transitionBuilder;

  const PageTransitionSwitcher({
    Key? key,
    required this.child,
    required this.transitionBuilder,
  }) : super(key: key);

  @override
  _PageTransitionSwitcherState createState() => _PageTransitionSwitcherState();
}

class _PageTransitionSwitcherState extends State<PageTransitionSwitcher> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _secondaryAnimationController;

  late Animation<double> _animation;
  late Animation<double> _secondaryAnimation;

  Widget? _oldWidget;
  final _childKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _secondaryAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _secondaryAnimation = CurvedAnimation(
      parent: _secondaryAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _secondaryAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PageTransitionSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.child.key != oldWidget.child.key) {
      _oldWidget = oldWidget.child;
      _secondaryAnimationController.forward(from: 0.0);
      _animationController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.transitionBuilder(
      widget.child,
      _animation,
      _secondaryAnimation,
    );
  }
}