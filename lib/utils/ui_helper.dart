import 'package:flutter/material.dart';

class UIHelper {
  // 애니메이션이 적용된 스낵바 표시
  static void showAnimatedSnackBar(
    BuildContext context, {
    required String message,
    Color backgroundColor = Colors.black87,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    final snackBar = SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: backgroundColor,
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height - 100,
        left: 10,
        right: 10,
      ),
      duration: duration,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      action: action,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
  
  // 성공 스낵바
  static void showSuccessSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    showAnimatedSnackBar(
      context,
      message: message,
      backgroundColor: Colors.green,
      duration: duration,
    );
  }
  
  // 에러 스낵바
  static void showErrorSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    showAnimatedSnackBar(
      context,
      message: message,
      backgroundColor: Colors.red.shade700,
      duration: duration,
    );
  }
  
  // 경고 스낵바
  static void showWarningSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    showAnimatedSnackBar(
      context,
      message: message,
      backgroundColor: Colors.orange.shade700,
      duration: duration,
    );
  }
  
  // 애니메이션 버튼 스타일
  static ButtonStyle animatedButtonStyle({
    Color backgroundColor = Colors.green,
    double borderRadius = 12,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(vertical: 16),
  }) {
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.all(backgroundColor),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      padding: MaterialStateProperty.all(padding),
      overlayColor: MaterialStateProperty.resolveWith<Color?>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.pressed)) {
            return backgroundColor.withOpacity(0.7);
          }
          return null;
        },
      ),
      elevation: MaterialStateProperty.resolveWith<double>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.pressed)) {
            return 1.0;
          }
          return 3.0;
        },
      ),
    );
  }
  
  // 애니메이션이 적용된 카드 위젯
  static Widget animatedCard({
    required Widget child,
    required BuildContext context,
    Duration duration = const Duration(milliseconds: 300),
    double elevation = 2.0,
    double borderRadius = 12.0,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
    Color? color,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (value * 0.1),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        elevation: elevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        color: color,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
  
  // 화면 전환 애니메이션 (Hero 사용)
  static Widget heroContainer({
    required String tag,
    required Widget child,
    double borderRadius = 12.0,
  }) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        return ScaleTransition(
          scale: animation.drive(
            Tween<double>(begin: 0.9, end: 1.0).chain(
              CurveTween(curve: Curves.easeInOut),
            ),
          ),
          child: child,
        );
      },
      child: Material(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
  
  // 로딩 스피너
  static Widget loadingSpinner({
    Color color = Colors.green,
    double size = 24.0,
    double strokeWidth = 2.0,
  }) {
    return SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(
        color: color,
        strokeWidth: strokeWidth,
      ),
    );
  }
  
  // 이미지 로딩 위젯
  static Widget imageWithLoadingFallback({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: Colors.grey[600],
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(
              Icons.broken_image,
              size: 40,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }
}