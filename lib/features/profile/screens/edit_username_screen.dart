import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dalattrip/core/utils/username_utils.dart';
import 'package:dalattrip/features/profile/data/repositories/firestore_user_repository.dart';
import 'package:dalattrip/features/profile/domain/entities/user_profile.dart';

class EditUsernameScreen extends StatefulWidget {
  final UserProfile profile;

  const EditUsernameScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditUsernameScreen> createState() => _EditUsernameScreenState();
}

class _EditUsernameScreenState extends State<EditUsernameScreen> {
  late TextEditingController _controller;
  Timer? _debounceTimer;

  bool _isChecking = false;
  bool _isSaving = false;
  String? _validationError;
  bool _isAvailable = false;
  String _currentNormalized = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.profile.username);
    _currentNormalized = widget.profile.username;
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _debounceTimer?.cancel();
    final normalized = UsernameUtils.normalizeUsername(value);

    setState(() {
      _currentNormalized = normalized;
      _isAvailable = false;
    });

    final error = UsernameUtils.validateUsername(value);
    if (error != null) {
      setState(() {
        _validationError = error;
        _isChecking = false;
      });
      return;
    }

    if (normalized == widget.profile.username) {
      setState(() {
        _validationError = null;
        _isChecking = false;
        _isAvailable = true;
      });
      return;
    }

    setState(() {
      _validationError = null;
      _isChecking = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final available = await FirestoreUserRepository.instance.isUsernameAvailable(normalized);
      if (mounted && _currentNormalized == normalized) {
        setState(() {
          _isChecking = false;
          _isAvailable = available;
          if (!available) {
            _validationError = 'Tên người dùng đã được sử dụng. Vui lòng chọn tên khác.';
          }
        });
      }
    });
  }

  Future<void> _saveUsername() async {
    final error = UsernameUtils.validateUsername(_controller.text);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final newUsername = UsernameUtils.normalizeUsername(_controller.text);
    if (newUsername == widget.profile.username) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirestoreUserRepository.instance.updateUsername(widget.profile.uid, newUsername);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã đổi tên người dùng thành @$newUsername'),
            backgroundColor: const Color(0xFF81C784),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1712) : const Color(0xFFF5F7F5);
    final cardColor = isDark ? const Color(0xFF1B2822) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF18251F);

    final canSave = !_isSaving &&
        !_isChecking &&
        _validationError == null &&
        _currentNormalized.isNotEmpty &&
        _currentNormalized != widget.profile.username &&
        _isAvailable;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.chevron_left, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Đổi Tên Người Dùng',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tên người dùng mới',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141F1A) : const Color(0xFFEFEFEF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _validationError != null
                              ? Colors.redAccent
                              : (_isAvailable
                                  ? const Color(0xFF81C784)
                                  : Colors.transparent),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            '@ ',
                            style: TextStyle(
                              color: Color(0xFF81C784),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'vchun_211',
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                              onChanged: _onUsernameChanged,
                            ),
                          ),
                          if (_isChecking)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF81C784),
                              ),
                            )
                          else if (_isAvailable && _currentNormalized != widget.profile.username)
                            const Icon(CupertinoIcons.checkmark_alt_circle_fill, color: Color(0xFF81C784), size: 22)
                          else if (_validationError != null)
                            const Icon(CupertinoIcons.exclamationmark_circle_fill, color: Colors.redAccent, size: 22),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_validationError != null)
                      Text(
                        _validationError!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else if (_isAvailable && _currentNormalized != widget.profile.username)
                      const Text(
                        '✓ Tên người dùng khả dụng',
                        style: TextStyle(
                          color: Color(0xFF81C784),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      Text(
                        'Username từ 4-20 ký tự, bao gồm chữ cái (a-z), số (0-9), dấu _ và dấu .',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: canSave ? _saveUsername : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF81C784),
                    disabledBackgroundColor: (isDark ? const Color(0xFF1B2822) : Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Lưu thay đổi',
                          style: TextStyle(
                            color: canSave ? const Color(0xFF0F1712) : Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
