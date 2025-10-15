// ⚙️ Firebase configuration loader (ENV-based version)

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Default [FirebaseOptions] untuk aplikasi Fountaine.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'FirebaseOptions belum dikonfigurasi untuk Web. '
        'Tambahkan key Web ke file .env jika ingin mendukung Web.',
      );
    }

    // Pilih platform (Android / iOS)
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _fromEnv(isIOS: false);
      case TargetPlatform.iOS:
        return _fromEnv(isIOS: true);
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'FirebaseOptions belum dikonfigurasi untuk macOS.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'FirebaseOptions belum dikonfigurasi untuk Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'FirebaseOptions belum dikonfigurasi untuk Linux.',
        );
      default:
        throw UnsupportedError('Platform ini belum didukung FirebaseOptions.');
    }
  }

  /// 🔒 Ambil konfigurasi dari file `.env`
  /// Jika `.env` tidak ditemukan atau kosong, akan lempar error
  static FirebaseOptions _fromEnv({required bool isIOS}) {
    // Pastikan dotenv sudah dimuat sebelum dipanggil
    if (dotenv.env.isEmpty) {
      throw Exception(
        'File .env belum dimuat! '
        'Tambahkan `await dotenv.load(fileName: ".env");` di main() sebelum initializeApp().',
      );
    }

    // Gunakan key berdasarkan platform
    final apiKey = isIOS
        ? dotenv.env['FIREBASE_IOS_API_KEY']
        : dotenv.env['FIREBASE_ANDROID_API_KEY'];
    final appId = isIOS
        ? dotenv.env['FIREBASE_IOS_APP_ID']
        : dotenv.env['FIREBASE_ANDROID_APP_ID'];
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
    final senderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'];
    final bucket = dotenv.env['FIREBASE_STORAGE_BUCKET'];
    final bundleId = dotenv.env['FIREBASE_IOS_BUNDLE_ID'];

    if ([apiKey, appId, projectId, senderId].contains(null)) {
      throw Exception(
        'Beberapa variabel environment Firebase belum diisi di .env!',
      );
    }

    // Kembalikan konfigurasi
    return FirebaseOptions(
      apiKey: apiKey!,
      appId: appId!,
      projectId: projectId!,
      messagingSenderId: senderId!,
      storageBucket: bucket,
      iosBundleId: isIOS ? bundleId : null,
    );
  }
}
