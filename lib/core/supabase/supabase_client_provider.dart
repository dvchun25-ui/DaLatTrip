import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class SupabaseClientProvider {
  SupabaseClientProvider._();

  static SupabaseClient? _client;

  static bool get isInitialized => _client != null;

  static SupabaseClient get client {
    final value = _client;
    if (value == null) {
      throw StateError('Supabase Storage chưa được khởi tạo.');
    }
    return value;
  }

  static Future<void> initialize() async {
    if (_client != null) return;
    if (!SupabaseConfig.isConfigured) {
      throw StateError('Thiếu cấu hình Supabase.');
    }

    final instance = await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
      accessToken: () async {
        try {
          return FirebaseAuth.instance.currentUser?.getIdToken();
        } catch (error) {
          debugPrint('Không lấy được Firebase ID token cho Supabase: $error');
          return null;
        }
      },
    );
    _client = instance.client;
  }
}
