import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/check_in_member.dart';

class CheckInRecipientTile extends StatelessWidget {
  final CheckInMember member;
  final bool isSelected;
  final ValueChanged<bool> onToggle;

  const CheckInRecipientTile({
    super.key,
    required this.member,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final avatarPath = member.avatarPath;
    final hasRemoteAvatar = avatarPath?.startsWith('http') ?? false;
    final hasLocalAvatar =
        avatarPath != null &&
        avatarPath.isNotEmpty &&
        !hasRemoteAvatar &&
        File(avatarPath).existsSync();

    return GestureDetector(
      onTap: () => onToggle(!isSelected),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141F1A), // Dark glass card phong cách iOS
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF81C784).withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF2D3E35),
              backgroundImage: hasRemoteAvatar
                  ? CachedNetworkImageProvider(avatarPath!)
                  : hasLocalAvatar
                  ? FileImage(File(avatarPath))
                  : null,
              child: !hasLocalAvatar && !hasRemoteAvatar
                  ? Text(
                      member.displayName.isNotEmpty
                          ? member.displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            // Tên & Nhóm
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        member.status == CheckInMemberStatus.owner
                            ? Icons.star_rounded
                            : Icons.group_outlined,
                        size: 13,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        member.status == CheckInMemberStatus.owner
                            ? 'Trưởng nhóm'
                            : 'Bạn bè',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Checkbox tròn phong cách iOS
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF81C784)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFF81C784) : Colors.white38,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF0F1712),
                      size: 18,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
