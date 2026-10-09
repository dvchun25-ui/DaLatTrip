import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dalattrip/constants/app_colors.dart';
import 'package:dalattrip/features/auth/services/user_firestore_service.dart';

/// Màn hình tìm kiếm người dùng theo @username & Quản lý danh sách kết bạn chuẩn phong cách iOS
class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final UserFirestoreService _userService = UserFirestoreService.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<UserProfile> _searchResults = [];
  List<String> _recentSearches = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  User? get _currentUser => _auth.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRecentSearches();
    if (_currentUser != null) {
      _userService.syncUserProfile(_currentUser!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_user_searches') ?? [];
    });
  }

  Future<void> _saveRecentSearch(String term) async {
    final clean = term.trim();
    if (clean.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(clean);
    _recentSearches.insert(0, clean);
    if (_recentSearches.length > 5) {
      _recentSearches = _recentSearches.sublist(0, 5);
    }
    await prefs.setStringList('recent_user_searches', _recentSearches);
    setState(() {});
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    setState(() => _isSearching = true);
    final results = await _userService.searchUsers(cleanQuery);
    _saveRecentSearch(cleanQuery);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tìm kiếm người dùng')),
        body: const Center(
          child: Text('Vui lòng đăng nhập để sử dụng tính năng kết bạn.'),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1712) : AppColors.scaffoldBackground;
    final cardColor = isDark ? const Color(0xFF1B2822) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.chevron_left, color: textColor),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Kết bạn & Thành viên',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF81C784),
          unselectedLabelColor: textColor.withValues(alpha: 0.5),
          indicatorColor: const Color(0xFF81C784),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          tabs: const [
            Tab(text: 'Tìm @username'),
            Tab(text: 'Bạn bè của tôi'),
          ],
        ),
      ),
      body: StreamBuilder<UserProfile?>(
        stream: _userService.streamUserProfile(currentUser.uid),
        builder: (context, snapshot) {
          final myProfile = snapshot.data;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildSearchTab(myProfile, isDark, cardColor, textColor),
              _buildFriendsTab(myProfile, isDark, cardColor, textColor),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchTab(UserProfile? myProfile, bool isDark, Color cardColor, Color textColor) {
    return Column(
      children: [
        // iOS Search Bar
        Container(
          color: cardColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141F1A) : const Color(0xFFF2F7F4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tìm bằng tên hoặc @username (Ví dụ: @vchun_211)',
                hintStyle: TextStyle(
                  color: textColor.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(CupertinoIcons.search, color: Color(0xFF81C784), size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(CupertinoIcons.xmark_circle_fill, size: 18, color: textColor.withValues(alpha: 0.4)),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        // Recent searches chips
        if (_searchController.text.isEmpty && _recentSearches.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Gần đây:',
                  style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _recentSearches.map((term) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text('@$term', style: const TextStyle(fontSize: 11, color: Color(0xFF81C784))),
                            backgroundColor: isDark ? const Color(0xFF1B2822) : Colors.white,
                            side: BorderSide(color: const Color(0xFF81C784).withValues(alpha: 0.3)),
                            onPressed: () {
                              _searchController.text = term;
                              _performSearch(term);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

        const Divider(height: 1, color: Colors.black12),
        Expanded(
          child: _isSearching
              ? const Center(child: CupertinoActivityIndicator())
              : _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.person_crop_circle_badge_plus,
                            size: 56,
                            color: const Color(0xFF81C784).withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchController.text.isEmpty
                                ? 'Nhập @username để tìm kiếm người dùng'
                                : 'Không tìm thấy người dùng.\nHãy kiểm tra lại tên người dùng.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final target = _searchResults[index];
                        return _buildUserCard(target, myProfile, isDark, cardColor, textColor);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFriendsTab(UserProfile? myProfile, bool isDark, Color cardColor, Color textColor) {
    if (myProfile == null || myProfile.friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.group,
              size: 56,
              color: const Color(0xFF81C784).withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Bạn chưa có ai trong danh sách bạn bè.\nHãy nhập @username ở tab tìm kiếm để kết bạn!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: myProfile.friends.length,
      itemBuilder: (context, index) {
        final friendUid = myProfile.friends[index];
        return FutureBuilder<UserProfile?>(
          future: _userService.getUserProfile(friendUid),
          builder: (context, snapshot) {
            final friend = snapshot.data;
            if (friend == null) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: _buildUserCard(friend, myProfile, isDark, cardColor, textColor),
            );
          },
        );
      },
    );
  }

  Widget _buildUserCard(
    UserProfile target,
    UserProfile? myProfile,
    bool isDark,
    Color cardColor,
    Color textColor,
  ) {
    final currentUid = _currentUser?.uid;
    final isMe = target.uid == currentUid;
    final isFriend = myProfile?.friends.contains(target.uid) ?? false;
    final isSent = myProfile?.sentRequests.contains(target.uid) ?? false;
    final isReceived = myProfile?.receivedRequests.contains(target.uid) ?? false;

    final avatarPath = target.avatarPath ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar User
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF81C784).withValues(alpha: 0.15),
            backgroundImage: avatarPath.isNotEmpty ? NetworkImage(avatarPath) : null,
            child: avatarPath.isEmpty
                ? Text(
                    target.displayName.isNotEmpty ? target.displayName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Color(0xFF81C784),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Thông tin Tên hiển thị & @username (KHÔNG hiển thị Email)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  target.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF81C784).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '@${target.username}',
                    style: const TextStyle(
                      color: Color(0xFF81C784),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Action buttons
          if (isMe)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Tài khoản của bạn',
                style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.6)),
              ),
            )
          else if (isFriend)
            OutlinedButton.icon(
              onPressed: () async {
                if (currentUid != null) {
                  await _userService.removeFriend(
                    currentUid: currentUid,
                    targetUid: target.uid,
                  );
                }
              },
              icon: const Icon(CupertinoIcons.checkmark_seal_fill, size: 15),
              label: const Text('Bạn bè'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF81C784),
                side: const BorderSide(color: Color(0xFF81C784)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
            )
          else if (isReceived)
            FilledButton.icon(
              onPressed: () async {
                if (currentUid != null) {
                  await _userService.acceptFriendRequest(
                    currentUid: currentUid,
                    targetUid: target.uid,
                  );
                }
              },
              icon: const Icon(CupertinoIcons.person_badge_plus, size: 15),
              label: const Text('Chấp nhận'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF81C784),
                foregroundColor: const Color(0xFF0F1712),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
            )
          else if (isSent)
            ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Đã gửi lời mời', style: TextStyle(fontSize: 11)),
            )
          else
            FilledButton.icon(
              onPressed: () async {
                if (currentUid != null) {
                  await _userService.sendFriendRequest(
                    currentUid: currentUid,
                    targetUid: target.uid,
                  );
                }
              },
              icon: const Icon(CupertinoIcons.person_add_solid, size: 15),
              label: const Text('Kết bạn'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF81C784),
                foregroundColor: const Color(0xFF0F1712),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}
