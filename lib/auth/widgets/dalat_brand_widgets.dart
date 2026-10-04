import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_asset_images.dart';

/// Logo thương hiệu DaLatTrip chuẩn xác 100% (Đã bỏ dòng chữ nhỏ bên dưới)
class DalatLogo extends StatelessWidget {
  final bool showTagline;
  final double? height;
  final double? iconSize;

  const DalatLogo({
    super.key,
    this.showTagline = true,
    this.height,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final double effectiveHeight = height ?? (iconSize != null ? iconSize! * 1.5 : 90.0);

    return AppAssetImages.logo(
      height: effectiveHeight,
      fit: BoxFit.contain,
    );
  }
}

/// Huy hiệu tròn màu xanh bạc hà chứa icon (Khóa / Tích xanh)
class DalatBadgeIcon extends StatelessWidget {
  final IconData icon;
  final double size;

  const DalatBadgeIcon({
    super.key,
    required this.icon,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.mintBadge,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: size * 0.46,
        color: AppColors.mintIcon,
      ),
    );
  }
}

/// Header đồi thông sương mờ cho màn hình Tạo tài khoản & Đăng ký
class DalatHeaderBanner extends StatelessWidget {
  final VoidCallback? onBack;
  final bool showBackButton;
  final double height;
  final Widget? overlayChild;

  const DalatHeaderBanner({
    super.key,
    this.onBack,
    this.showBackButton = true,
    this.height = 180,
    this.overlayChild,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ảnh nền đồi thông sương mờ
          AppAssetImages.splashBg(
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.2),
          ),

          // 2. Lớp sương mờ chuyển nhẹ
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.7),
                  Colors.white,
                ],
                stops: const [0.0, 0.4, 0.85, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          if (overlayChild != null)
            Positioned.fill(child: overlayChild!),

          // 3. Nút Back
          if (showBackButton)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: InkWell(
                onTap: onBack ?? () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Phong cảnh đồi thông + nhà lồng kính + chữ viết tay nghệ thuật phía dưới
class DalatBottomLandscape extends StatelessWidget {
  final String? quoteText;
  final double? height;

  const DalatBottomLandscape({
    super.key,
    this.quoteText,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? 280.0;

    return SizedBox(
      height: effectiveHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ảnh gốc nhà lồng kính Đà Lạt
          AppAssetImages.glasshouseBg(
            fit: BoxFit.cover,
            alignment: const Alignment(0, 0.2),
          ),

          // 2. Lớp gradient phủ mờ từ trên xuống để hòa vào màu nền
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF3F7F4),
                  const Color(0xFFF3F7F4).withValues(alpha: 0.7),
                  const Color(0xFFF3F7F4).withValues(alpha: 0.0),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.18, 0.45, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 3. Chữ thư pháp viết tay nghệ thuật "Da Lat vẫn luôn chờ bạn"
          Positioned(
            right: 24,
            top: 28,
            child: Text(
              quoteText ?? 'Da Lat\nvẫn luôn chờ bạn',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'serif',
                fontStyle: FontStyle.italic,
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E3A2F),
                letterSpacing: 0.5,
                height: 1.2,
                shadows: [
                  Shadow(
                    color: Colors.white,
                    blurRadius: 8,
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

/// Biển chỉ dẫn gỗ "Đi Đà Lạt cùng Dalattrip ♡" và hoa cúc họa mi
class DalatWoodenSignpost extends StatelessWidget {
  const DalatWoodenSignpost({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    const Color(0xFFD4E7DC).withValues(alpha: 0.5),
                    const Color(0xFFAECFBF).withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _SignpostPainter(),
            ),
          ),
          Positioned(
            right: 28,
            bottom: 28,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF8D6E53),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF5D4037), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Đi Đà Lạt',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFF8E7),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'cùng Dalattrip ♡',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFFEFEBE9),
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

class _SignpostPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final postPaint = Paint()..color = const Color(0xFF6D4C41);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.72, size.height * 0.35, 12, size.height * 0.65),
      postPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
