import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

enum SocialType { google, apple, email }

/// Nút đăng nhập qua mạng xã hội (Google, Apple, Email) hỗ trợ cả chế độ compact và full-width
class SocialLoginButton extends StatelessWidget {
  final SocialType type;
  final VoidCallback? onPressed;
  final bool isFullWidth;
  final String? customText;

  const SocialLoginButton({
    super.key,
    required this.type,
    required this.onPressed,
    this.isFullWidth = false,
    this.customText,
  });

  @override
  Widget build(BuildContext context) {
    if (isFullWidth) {
      return _buildFullWidthButton();
    }
    return _buildCompactButton();
  }

  Widget _buildCompactButton() {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.socialButtonBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.socialButtonBorder, width: 1.2),
        ),
        alignment: Alignment.center,
        child: _buildSocialIcon(),
      ),
    );
  }

  Widget _buildFullWidthButton() {
    String label;
    switch (type) {
      case SocialType.google:
        label = customText ?? 'Tiếp tục với Google';
        break;
      case SocialType.apple:
        label = customText ?? 'Tiếp tục với Apple';
        break;
      case SocialType.email:
        label = customText ?? 'Tiếp tục với Email';
        break;
    }

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.socialButtonBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.socialButtonBorder, width: 1.2),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: Center(child: _buildSocialIcon()),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon() {
    switch (type) {
      case SocialType.google:
        return const _GoogleIcon();
      case SocialType.apple:
        return const Icon(Icons.apple, size: 26, color: Colors.black);
      case SocialType.email:
        return const Icon(
          Icons.mail_outline_rounded,
          size: 22,
          color: AppColors.primary,
        );
    }
  }
}

/// Icon Google vẽ thuần Flutter mượt mà không bị vỡ hoặc thiếu asset
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(22, 22), painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    final paint = Paint()..style = PaintingStyle.fill;

    // Red
    paint.color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 * 0.75,
        3.14159 * 0.5,
        false,
      )
      ..close();
    canvas.drawPath(redPath, paint);

    // Yellow
    paint.color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 * 1.25,
        3.14159 * 0.5,
        false,
      )
      ..close();
    canvas.drawPath(yellowPath, paint);

    // Green
    paint.color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        3.14159 * 0.25,
        3.14159 * 0.5,
        false,
      )
      ..close();
    canvas.drawPath(greenPath, paint);

    // Blue
    paint.color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 * 0.25,
        3.14159 * 0.5,
        false,
      )
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(bluePath, paint);

    // Inner White circle cutout for the 'G'
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.58, paint);

    // Blue bar in the middle of 'G'
    paint.color = const Color(0xFF4285F4);
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        center.dx - 1,
        center.dy - radius * 0.22,
        radius * 1.05,
        radius * 0.44,
      ),
      const Radius.circular(1),
    );
    canvas.drawRRect(barRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
