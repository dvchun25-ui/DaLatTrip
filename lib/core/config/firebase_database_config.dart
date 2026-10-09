class FirebaseDatabaseConfig {
  FirebaseDatabaseConfig._();

  static const String url = String.fromEnvironment(
    'FIREBASE_DATABASE_URL',
    defaultValue:
        'https://dalattrip-8c1d2-default-rtdb.asia-southeast1.firebasedatabase.app',
  );
}
