import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../auth/screens/login_screen.dart';
import '../../../auth/services/auth_service.dart';
import '../../auth/services/user_firestore_service.dart';
import '../avatar_controller.dart';
import 'edit_username_screen.dart';
import 'user_search_screen.dart';

/// Màn hình Trang cá nhân chuẩn phong cách iOS
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserFirestoreService _userService = UserFirestoreService.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AvatarController _avatarController = AvatarController();
  bool _isUploadingAvatar = false;
  String? _localAvatarFallback;

  User? get _currentUser => _auth.currentUser;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _userService.syncUserProfile(_currentUser!);
    }
  }

  void _openUserSearch() {
    Navigator.of(
      context,
    ).push(CupertinoPageRoute(builder: (_) => const UserSearchScreen()));
  }

  void _openEditUsername(UserProfile profile) {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => EditUsernameScreen(profile: profile)),
    );
  }

  Future<void> _changeAvatar() async {
    if (_isUploadingAvatar) return;
    setState(() => _isUploadingAvatar = true);
    try {
      final result = await _avatarController.pickAndUploadAvatar();
      if (!mounted || result == null) return;
      if (!result.uploaded) {
        setState(() => _localAvatarFallback = result.displayPath);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Chưa tải được ảnh lên cloud. Đang dùng bản cục bộ; hãy thử lại khi có mạng.',
            ),
            action: SnackBarAction(label: 'Thử lại', onPressed: _changeAvatar),
          ),
        );
      } else {
        setState(() => _localAvatarFallback = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật ảnh đại diện.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể đổi ảnh đại diện: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  ImageProvider<Object>? _avatarProvider(String value) {
    if (value.startsWith('https://') || value.startsWith('http://')) {
      return CachedNetworkImageProvider(value);
    }
    if (value.isNotEmpty && File(value).existsSync()) {
      return FileImage(File(value));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF0F1712)
        : AppColors.scaffoldBackground;
    final cardColor = isDark ? const Color(0xFF1B2822) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        title: Text(
          'Trang cá nhân',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              CupertinoIcons.person_badge_plus,
              color: Color(0xFF81C784),
            ),
            tooltip: 'Kết bạn & Tìm @username',
            onPressed: _openUserSearch,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Header Profile Card
            if (currentUser != null)
              StreamBuilder<UserProfile?>(
                stream: _userService.streamUserProfile(currentUser.uid),
                builder: (context, snapshot) {
                  final profile = snapshot.data;
                  final displayName =
                      profile?.displayName ??
                      currentUser.displayName ??
                      currentUser.email?.split('@').first ??
                      'Người dùng Đà Lạt';
                  final username =
                      profile?.username ??
                      (currentUser.email != null &&
                              currentUser.email!.contains('@')
                          ? currentUser.email!.split('@').first
                          : 'user_${currentUser.uid.substring(0, 6)}');
                  final avatarPath =
                      _localAvatarFallback ??
                      profile?.preferredAvatar ??
                      currentUser.photoURL ??
                      '';
                  final avatarProvider = _avatarProvider(avatarPath);
                  final bio = profile?.bio ?? 'Yêu du lịch Đà Lạt 🌲';

                  return Container(
                    color: cardColor,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _isUploadingAvatar ? null : _changeAvatar,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 42,
                                backgroundColor: const Color(
                                  0xFF81C784,
                                ).withValues(alpha: 0.15),
                                backgroundImage: avatarProvider,
                                child: avatarProvider == null
                                    ? Text(
                                        displayName.isNotEmpty
                                            ? displayName[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF81C784),
                                        ),
                                      )
                                    : null,
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: CircleAvatar(
                                  radius: 15,
                                  backgroundColor: const Color(0xFF81C784),
                                  child: _isUploadingAvatar
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          CupertinoIcons.camera_fill,
                                          color: Colors.white,
                                          size: 15,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF81C784,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '@$username',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF81C784),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bio,
                          style: TextStyle(
                            fontSize: 13,
                            color: textColor.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Quick buttons: Đổi Username & Kết bạn
                        if (profile != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _openEditUsername(profile),
                                icon: const Icon(CupertinoIcons.at, size: 16),
                                label: const Text('Chỉnh hồ sơ'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF81C784),
                                  side: const BorderSide(
                                    color: Color(0xFF81C784),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: _openUserSearch,
                                icon: const Icon(
                                  CupertinoIcons.search,
                                  size: 16,
                                ),
                                label: const Text('Tìm bạn bè'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textColor,
                                  side: BorderSide(
                                    color: textColor.withValues(alpha: 0.3),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),

                        if (profile != null) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildStatItem(
                                'Bạn bè',
                                '${profile.friends.length}',
                                textColor,
                              ),
                              Container(
                                height: 20,
                                width: 1,
                                color: textColor.withValues(alpha: 0.2),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                              ),
                              _buildStatItem(
                                'Lời mời kết bạn',
                                '${profile.receivedRequests.length}',
                                textColor,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              )
            else
              Container(
                color: cardColor,
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: const Text('Chưa đăng nhập'),
              ),

            const SizedBox(height: 12),

            // Menu Section
            Container(
              color: cardColor,
              child: Column(
                children: [
                  _buildMenuItem(
                    CupertinoIcons.person_crop_circle_badge_checkmark,
                    'Đổi biệt danh và @username',
                    () {
                      if (_currentUser != null) {
                        _userService.getUserProfile(_currentUser!.uid).then((
                          p,
                        ) {
                          if (p != null) _openEditUsername(p);
                        });
                      }
                    },
                    textColor,
                  ),
                  Divider(
                    height: 1,
                    indent: 56,
                    color: textColor.withValues(alpha: 0.1),
                  ),
                  _buildMenuItem(
                    CupertinoIcons.group,
                    'Kết bạn & Tìm kiếm @username',
                    _openUserSearch,
                    textColor,
                  ),
                  Divider(
                    height: 1,
                    indent: 56,
                    color: textColor.withValues(alpha: 0.1),
                  ),
                  // Private Account Info Section (Email resides here, not public)
                  ListTile(
                    leading: const Icon(
                      CupertinoIcons.mail,
                      color: Color(0xFF81C784),
                    ),
                    title: Text(
                      'Email tài khoản (Riêng tư)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      currentUser?.email ?? 'Chưa cập nhật',
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    indent: 56,
                    color: textColor.withValues(alpha: 0.1),
                  ),
                  _buildMenuItem(
                    CupertinoIcons.square_arrow_right,
                    'Đăng xuất',
                    () async {
                      try {
                        await AuthService.instance.signOut();
                      } catch (_) {}
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    textColor,
                    isDestructive: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String count, Color textColor) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF81C784),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textColor.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap,
    Color textColor, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? const Color(0xFFE53935)
            : const Color(0xFF81C784),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: isDestructive ? const Color(0xFFE53935) : textColor,
        ),
      ),
      trailing: Icon(
        CupertinoIcons.chevron_right,
        color: textColor.withValues(alpha: 0.3),
        size: 18,
      ),
      onTap: onTap,
    );
  }
}
