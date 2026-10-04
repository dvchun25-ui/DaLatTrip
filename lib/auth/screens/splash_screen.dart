import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_asset_images.dart';
import '../widgets/dalat_brand_widgets.dart';
import 'onboarding_screen.dart';

/// Màn hình Splash Screen sử dụng ảnh gốc 100% người dùng cung cấp
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
    _handleNavigation();
  }

  void _handleNavigation() {
    Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCDE0D5),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ảnh nền gốc Đà Lạt (Đồi thông, bình minh & tháp chuông)
          AppAssetImages.splashBg(
            fit: BoxFit.cover,
          ),

          // 2. Lớp sương mờ dốc màu từ trên xuống dưới
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.75),
                  Colors.white.withValues(alpha: 0.35),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.75),
                ],
                stops: const [0.0, 0.22, 0.45, 0.75, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 3. Nội dung Logo và Chữ thư pháp
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  const SizedBox(height: 38),

                  // Logo DALATTRIP
                  const Center(
                    child: DalatLogo(
                      showTagline: true,
                      iconSize: 58,
                    ),
                  ),

                  const Spacer(),

                  // Chữ viết tay "Đi Đà Lạt / Dễ hơn bao giờ hết"
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const Text(
                          'Đi Đà Lạt',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontStyle: FontStyle.italic,
                            fontSize: 34,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFFF9E6),
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Dễ hơn bao giờ hết',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontStyle: FontStyle.italic,
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFFFF0D0),
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Indicator 4 chấm
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 18,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _buildDot(),
                            const SizedBox(width: 6),
                            _buildDot(),
                            const SizedBox(width: 6),
                            _buildDot(),
                          ],
                        ),
                        const SizedBox(height: 16),
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

  Widget _buildDot() {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
    );
  }
}
