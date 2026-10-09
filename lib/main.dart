import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'core/supabase/supabase_client_provider.dart';
import 'firebase_options.dart';
import 'constants/app_colors.dart';
import 'auth/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Giữ cache ảnh giải mã trong RAM ở mức vừa phải. Ảnh mẫu địa điểm được
  // đóng gói trong app; giới hạn này cũng áp dụng cho URL ảnh từ API về sau.
  PaintingBinding.instance.imageCache
    ..maximumSize = 50
    ..maximumSizeBytes = 50 * 1024 * 1024;
  const mapboxToken = String.fromEnvironment('MAPBOX_PUBLIC_TOKEN');
  // mapbox_maps_flutter 2.x only registers Android/iOS plugins. Calling its
  // global options API on Web debug throws before runApp can render anything.
  if (!kIsWeb && mapboxToken.isNotEmpty) {
    MapboxOptions.setAccessToken(mapboxToken);
  }
  Future<FirebaseApp> Function()? retryInitializer;
  try {
    await _initializeBackends();
  } catch (error) {
    debugPrint('Firebase initialization failed: $error');
    retryInitializer = _initializeBackends;
  }
  runApp(DaLatTripApp(firebaseInitializer: retryInitializer));
}

Future<FirebaseApp> _initializeBackends() async {
  final firebaseApp = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  try {
    await SupabaseClientProvider.initialize();
  } catch (error, stackTrace) {
    // Storage media là khả năng bổ sung. Firebase và các màn không dùng media
    // vẫn phải hoạt động khi Supabase tạm thời không khởi tạo được.
    debugPrint('Supabase Storage initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
  return firebaseApp;
}

class DaLatTripApp extends StatelessWidget {
  final Future<FirebaseApp> Function()? firebaseInitializer;

  const DaLatTripApp({super.key, this.firebaseInitializer});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DaLatTrip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.cardSurface,
        ),
        fontFamily: 'Roboto',
      ),
      home: firebaseInitializer == null
          ? const SplashScreen()
          : _FirebaseStartupGate(initializer: firebaseInitializer!),
    );
  }
}

class _FirebaseStartupGate extends StatefulWidget {
  final Future<FirebaseApp> Function() initializer;

  const _FirebaseStartupGate({required this.initializer});

  @override
  State<_FirebaseStartupGate> createState() => _FirebaseStartupGateState();
}

class _FirebaseStartupGateState extends State<_FirebaseStartupGate> {
  late Future<FirebaseApp> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = widget.initializer();
  }

  void _retry() {
    setState(() => _initialization = widget.initializer());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          // Use a different key from the Firebase-loading splash. Otherwise
          // Flutter reuses the same State object and its navigation timer is
          // never started when navigateAfterDelay changes from false to true.
          return const SplashScreen(key: ValueKey('firebase-ready'));
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Không thể khởi tạo ứng dụng',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const SplashScreen(
          key: ValueKey('firebase-initializing'),
          navigateAfterDelay: false,
        );
      },
    );
  }
}
