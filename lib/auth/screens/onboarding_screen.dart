import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../widgets/auth_button.dart';
import 'login_screen.dart';

/// Màn hình Onboarding chuẩn 100% theo ảnh thiết kế
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _pages = [
    const OnboardingItem(
      title: 'Lên kế hoạch\nchuyến đi thông minh',
      description:
          'Gợi ý địa điểm phù hợp, tối ưu lịch trình\nvà chi phí theo sở thích của bạn',
      card1:
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=500&q=80',
      card2:
          'https://images.unsplash.com/photo-1519046904884-53103b34b206?auto=format&fit=crop&w=500&q=80',
      card3:
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=500&q=80',
    ),
    const OnboardingItem(
      title: 'Khám phá quán cà phê\nvà homestay cực chill',
      description:
          'Hàng trăm điểm check-in sương mù đồi thông\nđang chờ bạn khám phá',
      card1:
          'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=500&q=80',
      card2:
          'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=500&q=80',
      card3:
          'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=500&q=80',
    ),
    const OnboardingItem(
      title: 'Trải nghiệm trọn vẹn\ncùng người thân yêu',
      description:
          'Tối ưu từng khoảnh khắc đáng nhớ\ntrong chuyến du lịch Đà Lạt của bạn',
      card1:
          'https://images.unsplash.com/photo-1533105079780-92b9be482077?auto=format&fit=crop&w=500&q=80',
      card2:
          'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=500&q=80',
      card3:
          'https://images.unsplash.com/photo-1472214103451-9374bd1c798e?auto=format&fit=crop&w=500&q=80',
    ),
  ];

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
  }

  Future<void> _navigateToLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBF9),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Space for top bar
                const SizedBox(height: 36),

                // Stacked Cards Carousel
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  return Column(
                    children: [
                      const Spacer(),
                      // Stacked Polaroid Cards
                      SizedBox(
                        width: 320,
                        height: 310,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            // Card 1: Top Left Tilted Photo (Da Lat hills)
                            Positioned(
                              left: 20,
                              top: 0,
                              child: Transform.rotate(
                                angle: -0.09,
                                child: _buildPolaroidCard(
                                  imageUrl: item.card1,
                                  width: 128,
                                  height: 180,
                                ),
                              ),
                            ),

                            // Card 2: Lower Left Tilted Photo (Glamping cafe)
                            Positioned(
                              left: 32,
                              top: 92,
                              child: Transform.rotate(
                                angle: -0.13,
                                child: _buildPolaroidCard(
                                  imageUrl: item.card2,
                                  width: 135,
                                  height: 115,
                                ),
                              ),
                            ),

                            // Card 3: Right Main Tilted Photo (Da Lat town view)
                            Positioned(
                              right: 22,
                              top: 86,
                              child: Transform.rotate(
                                angle: 0.08,
                                child: _buildPolaroidCard(
                                  imageUrl: item.card3,
                                  width: 152,
                                  height: 132,
                                  isMain: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),

                      // Title
                      Text(
                        item.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.3,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Description
                      Text(
                        item.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),
            ),

            // Indicator Dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3.5),
                    width: _currentPage == index ? 8 : 6,
                    height: _currentPage == index ? 8 : 6,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.primary
                          : const Color(0xFFD6E2DB),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),

            // "Bắt đầu →" Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: AuthButton(
                text: 'Bắt đầu',
                trailingIcon: const Icon(
                  Icons.arrow_forward,
                  size: 19,
                  color: Colors.white,
                ),
                onPressed: _onNext,
              ),
            ),
          ],
        ),

        // Skip Button Positioned Top-Right
        Positioned(
          top: 6,
          right: 16,
          child: TextButton(
            onPressed: _navigateToLogin,
            child: const Text(
              'Bỏ qua',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);
  }

  Widget _buildPolaroidCard({
    required String imageUrl,
    required double width,
    required double height,
    bool isMain = false,
  }) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isMain ? 0.14 : 0.08),
            blurRadius: isMain ? 16 : 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFFC7DECF),
              child: const Center(
                child: Icon(Icons.photo, color: Colors.white, size: 28),
              ),
            );
          },
        ),
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final String card1;
  final String card2;
  final String card3;

  const OnboardingItem({
    required this.title,
    required this.description,
    required this.card1,
    required this.card2,
    required this.card3,
  });
}
