import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:dalattrip/core/utils/username_utils.dart';
import 'package:dalattrip/features/profile/data/repositories/firestore_user_repository.dart';
import 'package:dalattrip/features/profile/domain/entities/user_profile.dart';

class EditUsernameScreen extends StatefulWidget {
  final UserProfile profile;

  const EditUsernameScreen({super.key, required this.profile});

  @override
  State<EditUsernameScreen> createState() => _EditUsernameScreenState();
}

class _EditUsernameScreenState extends State<EditUsernameScreen> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _usernameController;
  Timer? _debounceTimer;

  bool _isChecking = false;
  bool _isSaving = false;
  bool _isAvailable = true;
  String? _usernameError;

  String get _normalizedUsername =>
      UsernameUtils.normalizeUsername(_usernameController.text);
  String get _displayName =>
      _displayNameController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
  bool get _displayNameValid =>
      _displayName.length >= 2 && _displayName.length <= 40;
  bool get _hasChanges =>
      _normalizedUsername != widget.profile.username ||
      _displayName != widget.profile.displayName;
  bool get _canSave =>
      !_isSaving &&
      !_isChecking &&
      _usernameError == null &&
      _displayNameValid &&
      _normalizedUsername.isNotEmpty &&
      _isAvailable &&
      _hasChanges;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.profile.displayName,
    );
    _usernameController = TextEditingController(text: widget.profile.username);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onDisplayNameChanged(String _) => setState(() {});

  void _onUsernameChanged(String value) {
    _debounceTimer?.cancel();
    final normalized = UsernameUtils.normalizeUsername(value);
    final error = UsernameUtils.validateUsername(value);
    if (error != null) {
      setState(() {
        _usernameError = error;
        _isChecking = false;
        _isAvailable = false;
      });
      return;
    }
    if (normalized == widget.profile.username) {
      setState(() {
        _usernameError = null;
        _isChecking = false;
        _isAvailable = true;
      });
      return;
    }

    setState(() {
      _usernameError = null;
      _isChecking = true;
      _isAvailable = false;
    });
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final available = await FirestoreUserRepository.instance
          .isUsernameAvailable(normalized);
      if (!mounted || _normalizedUsername != normalized) return;
      setState(() {
        _isChecking = false;
        _isAvailable = available;
        _usernameError = available
            ? null
            : 'Tên người dùng đã được sử dụng. Vui lòng chọn tên khác.';
      });
    });
  }

  Future<void> _save() async {
    if (!_displayNameValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biệt danh phải có từ 2 đến 40 ký tự.')),
      );
      return;
    }
    final usernameError = UsernameUtils.validateUsername(
      _usernameController.text,
    );
    if (usernameError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(usernameError)));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await FirestoreUserRepository.instance.updateUserIdentity(
        uid: widget.profile.uid,
        displayName: _displayName,
        newUsername: _normalizedUsername,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật biệt danh và tên người dùng.'),
          backgroundColor: Color(0xFF81C784),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF0F1712)
        : const Color(0xFFF5F7F5);
    final card = isDark ? const Color(0xFF1B2822) : Colors.white;
    final text = isDark ? Colors.white : const Color(0xFF18251F);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        leading: IconButton(
          icon: Icon(CupertinoIcons.chevron_left, color: text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Chỉnh sửa hồ sơ',
          style: TextStyle(color: text, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Biệt danh',
                    style: TextStyle(color: text, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _displayNameController,
                    maxLength: 40,
                    textCapitalization: TextCapitalization.words,
                    onChanged: _onDisplayNameChanged,
                    decoration: InputDecoration(
                      hintText: 'Tên hiển thị để bạn bè tìm kiếm',
                      errorText:
                          _displayNameController.text.isNotEmpty &&
                              !_displayNameValid
                          ? 'Biệt danh cần từ 2 đến 40 ký tự'
                          : null,
                      filled: true,
                      fillColor: background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Tên người dùng duy nhất',
                    style: TextStyle(color: text, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usernameController,
                    onChanged: _onUsernameChanged,
                    autocorrect: false,
                    decoration: InputDecoration(
                      prefixText: '@ ',
                      hintText: 'dalat_traveler',
                      errorText: _usernameError,
                      suffixIcon: _isChecking
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : _isAvailable &&
                                _normalizedUsername != widget.profile.username
                          ? const Icon(
                              CupertinoIcons.checkmark_alt_circle_fill,
                              color: Color(0xFF81C784),
                            )
                          : null,
                      filled: true,
                      fillColor: background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bạn bè có thể tìm bằng biệt danh hoặc @username.',
                    style: TextStyle(
                      color: text.withValues(alpha: 0.55),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _canSave ? _save : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF81C784),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Lưu thay đổi',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
