import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../data/datasources/local_place_data_source.dart';
import '../../../data/models/place_model.dart';
import '../../auth/services/user_firestore_service.dart';
import '../../profile/screens/user_search_screen.dart';
import '../services/checkin_firestore_service.dart';

/// Màn hình Check-in du lịch Đà Lạt thay thế tab Khám phá trên Navigation Bar
class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  final CheckinFirestoreService _checkinService = CheckinFirestoreService.instance;
  final UserFirestoreService _userService = UserFirestoreService.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _currentUser => _auth.currentUser;
  UserProfile? _myProfile;

  @override
  void initState() {
    super.initState();
    _loadMyProfile();
  }

  Future<void> _loadMyProfile() async {
    final user = _currentUser;
    if (user != null) {
      final profile = await _userService.syncUserProfile(user);
      if (mounted) setState(() => _myProfile = profile);
    }
  }

  void _openUserSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UserSearchScreen()),
    );
  }

  void _openCheckinComposer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CheckinComposeSheet(
        myProfile: _myProfile,
        currentUser: _currentUser,
        onPosted: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Bài Check-in của bạn đã được đăng thành công!'),
              backgroundColor: AppColors.primary,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Check-in Đà Lạt 📍',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 19,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined, color: AppColors.primary),
            tooltip: 'Kết bạn & Tìm User ID',
            onPressed: _openUserSearch,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Banner tạo bài đăng Check-in mới
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: _currentUser?.photoURL != null &&
                            _currentUser!.photoURL!.isNotEmpty
                        ? NetworkImage(_currentUser!.photoURL!)
                        : null,
                    child: _currentUser?.photoURL == null ||
                            _currentUser!.photoURL!.isEmpty
                        ? const Icon(Icons.person, color: AppColors.primary)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _openCheckinComposer,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F7F4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Bạn đang check-in ở địa điểm nào Đà Lạt?',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _openCheckinComposer,
                    icon: const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Nút nhanh mở Tìm bạn bè theo ID
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: _openUserSearch,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Tìm bạn bè theo Mã User ID để xem Check-in',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Danh sách bài đăng Check-in từ Firestore
          StreamBuilder<List<CheckinPost>>(
            stream: _checkinService.streamCheckins(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              final checkins = snapshot.data ?? [];
              if (checkins.isEmpty) {
                return SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_location_alt_outlined,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Chưa có bài Check-in nào',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Hãy là người đầu tiên chia sẻ khoảnh khắc check-in tuyệt đẹp tại Đà Lạt!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _openCheckinComposer,
                          icon: const Icon(Icons.edit_location_alt_rounded),
                          label: const Text('Tạo bài Check-in ngay'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = checkins[index];
                    return _buildCheckinPostCard(item);
                  },
                  childCount: checkins.length,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildCheckinPostCard(CheckinPost post) {
    final uid = _currentUser?.uid;
    final isLiked = uid != null && post.likes.contains(uid);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tác giả bài viết
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: post.userAvatar.isNotEmpty
                      ? NetworkImage(post.userAvatar)
                      : null,
                  child: post.userAvatar.isEmpty
                      ? Text(
                          post.userName.isNotEmpty ? post.userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (post.userId.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '@${post.userId}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              post.placeName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTime(post.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Nội dung suy nghĩ / status
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14).copyWith(bottom: 10),
              child: Text(
                post.content,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
              ),
            ),

          // Hình ảnh Check-in
          if (post.imageUrl.isNotEmpty)
            ClipRRect(
              child: Image.network(
                post.imageUrl,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  color: const Color(0xFFF2F7F4),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),

          // Tương tác Thả tim
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    if (uid != null) {
                      _checkinService.toggleLike(post.id, uid);
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isLiked ? Colors.redAccent : AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.likes.length}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isLiked ? Colors.redAccent : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  post.placeAddress,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes <= 0 ? 1 : diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else {
      return '${diff.inDays} ngày trước';
    }
  }
}

/// Modal tạo bài đăng Check-in mới
class _CheckinComposeSheet extends StatefulWidget {
  final UserProfile? myProfile;
  final User? currentUser;
  final VoidCallback onPosted;

  const _CheckinComposeSheet({
    required this.myProfile,
    required this.currentUser,
    required this.onPosted,
  });

  @override
  State<_CheckinComposeSheet> createState() => _CheckinComposeSheetState();
}

class _CheckinComposeSheetState extends State<_CheckinComposeSheet> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  List<PlaceModel> _samplePlaces = [];
  PlaceModel? _selectedPlace;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    try {
      final places = await LocalPlaceDataSource().getAllPlaces();
      if (mounted) {
        setState(() {
          _samplePlaces = places;
          if (places.isNotEmpty) _selectedPlace = places.first;
        });
      }
    } catch (_) {}
  }

  Future<void> _submitCheckin() async {
    final user = widget.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để tạo bài check-in.')),
      );
      return;
    }

    final content = _contentController.text.trim();
    final place = _selectedPlace;
    if (place == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn địa điểm check-in.')),
      );
      return;
    }

    setState(() => _isPosting = true);
    try {
      final defaultImage = place.imageUrl ??
          'https://images.unsplash.com/photo-1588668214407-6ea9a6d8c272?w=800';
      final photoUrl = _imageUrlController.text.trim().isNotEmpty
          ? _imageUrlController.text.trim()
          : defaultImage;

      final post = CheckinPost(
        id: '',
        uid: user.uid,
        userName: widget.myProfile?.displayName ?? user.displayName ?? 'Du khách Đà Lạt',
        userAvatar: widget.myProfile?.photoUrl ?? user.photoURL ?? '',
        userId: widget.myProfile?.userId ?? '',
        placeName: place.name,
        placeAddress: place.address ?? 'Đà Lạt, Lâm Đồng',
        latitude: place.latitude,
        longitude: place.longitude,
        content: content.isEmpty ? 'Check-in tại ${place.name} ✨' : content,
        imageUrl: photoUrl,
        createdAt: DateTime.now(),
      );

      await CheckinFirestoreService.instance.createCheckin(post);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onPosted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể đăng check-in: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tạo bài Check-in mới 📍',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Chọn Địa điểm Đà Lạt
          const Text(
            'Địa điểm Check-in:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F7F4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<PlaceModel>(
                isExpanded: true,
                value: _selectedPlace,
                hint: const Text('Chọn địa điểm Đà Lạt'),
                items: _samplePlaces.take(30).map((place) {
                  return DropdownMenuItem<PlaceModel>(
                    value: place,
                    child: Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPlace = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Nội dung status
          TextField(
            controller: _contentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Cảm nhận của bạn về địa điểm này...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              filled: true,
              fillColor: const Color(0xFFF2F7F4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // URL ảnh (tùy chọn)
          TextField(
            controller: _imageUrlController,
            decoration: InputDecoration(
              hintText: 'Link ảnh Check-in (để trống nếu dùng ảnh mặc định)...',
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.link, size: 18),
              filled: true,
              fillColor: const Color(0xFFF2F7F4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isPosting ? null : _submitCheckin,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isPosting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Đăng Check-in',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
