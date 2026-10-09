import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dalattrip/core/config/supabase_config.dart';
import 'package:dalattrip/features/check_in/domain/entities/check_in_entry.dart';
import 'package:dalattrip/features/profile/domain/entities/user_profile.dart';

void main() {
  test('Supabase config uses the project root URL and publishable key', () {
    expect(SupabaseConfig.url, 'https://smyvqoudgbfqxdnwcxer.supabase.co');
    expect(SupabaseConfig.url, isNot(contains('/rest/v1')));
    expect(SupabaseConfig.publishableKey, startsWith('sb_publishable_'));
  });

  test('remote check-in metadata contains URL but never local path', () {
    final entry = CheckInEntry(
      id: 'checkin-1',
      mediaPath: 'https://example.supabase.co/checkin.jpg',
      mediaUrl: 'https://example.supabase.co/checkin.jpg',
      localMediaPath: r'C:\temp\checkin.jpg',
      mediaType: CheckInMediaType.photo,
      capturedAt: DateTime.utc(2026, 10, 9),
      placeName: 'Hồ Xuân Hương',
    );

    final remote = entry.toRemoteJson();
    expect(remote['mediaUrl'], startsWith('https://'));
    expect(remote.containsKey('localMediaPath'), isFalse);
    expect(remote.values, isNot(contains(r'C:\temp\checkin.jpg')));
  });

  test('UserProfile prioritizes avatarUrl from Firestore', () {
    final profile = UserProfile.fromFirestore({
      'email': 'user@example.com',
      'username': 'traveler',
      'displayName': 'Traveler',
      'avatarUrl': 'https://example.supabase.co/avatar.jpg',
      'avatarPath': r'C:\local\avatar.jpg',
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
    }, 'firebase-uid');

    expect(profile.preferredAvatar, 'https://example.supabase.co/avatar.jpg');
  });

  test('Storage policies bind Firebase JWT and media path to the same UID', () {
    final sql = File('supabase/storage_setup.sql').readAsStringSync();

    expect(sql, contains("to anon, authenticated"));
    expect(
      sql,
      contains(
        "(auth.jwt()->>'iss') = "
        "'https://securetoken.google.com/dalattrip-8c1d2'",
      ),
    );
    expect(sql, contains("(auth.jwt()->>'aud') = 'dalattrip-8c1d2'"));
    expect(
      sql,
      contains("(storage.foldername(name))[1] = (auth.jwt()->>'sub')"),
    );
  });
}
