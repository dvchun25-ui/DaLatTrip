import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_asset_images.dart';
import '../../features/navigation/main_navigation_screen.dart';
import '../services/auth_service.dart';
import '../widgets/dalat_brand_widgets.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

/// Màn hình Splash Screen sử dụng ảnh gốc 100% người dùng cung cấp
class SplashScreen extends StatefulWidget {
  final bool navigateAfterDelay;

  const SplashScreen({super.key, this.navigateAfterDelay = true});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _timer;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
    if (widget.navigateAfterDelay) {
      _timer = Timer(const Duration(milliseconds: 1000), _performNavigation);
    }
  }

  Future<void> _performNavigation() async {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;
    _timer?.cancel();

    try {
      final hasSavedSession = await AuthService.instance.hasSavedSession();
      if (!mounted) return;

      if (hasSavedSession) {
        // Nếu đã có tài khoản login sẵn -> Nhảy ngay vào Trang chủ
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
      if (!mounted) return;

      if (hasSeenOnboarding) {
        // Đã từng mở app trước đó -> Vào thẳng trang Đăng nhập
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        // Lần đầu tải & mở app -> Hiện 3 màn hình Onboarding
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _performNavigation,
      child: Scaffold(
        backgroundColor: const Color(0xFFCDE0D5),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Ảnh nền gốc Đà Lạt (Đồi thông, bình minh & tháp chuông)
            AppAssetImages.splashBg(fit: BoxFit.cover),

          // 2. Gradient rất nhẹ để giữ nguyên độ nét và màu ảnh gốc.
          // Chỉ làm tối phần chân ảnh một chút để chữ luôn dễ đọc.
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.10),
                  Colors.white.withValues(alpha: 0.02),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.46),
                ],
                stops: const [0.0, 0.28, 0.52, 0.78, 1.0],
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
                  const SizedBox(height: 42),

                  // Logo DALATTRIP
                  const Center(
                    child: DalatLogo(showTagline: true, height: 96),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Khám phá Đà Lạt theo cách của bạn',
                    style: TextStyle(
                      color: Color(0xFF173C31),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.15,
                      shadows: [
                        Shadow(color: Colors.white70, blurRadius: 8),
                      ],
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
                            color: Color(0xFFFFFBF0),
                            shadows: [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 8,
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
                            color: Color(0xFFFFF5DA),
                            shadows: [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 8,
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
