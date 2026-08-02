import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/package_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class UpdateService {
  static const String _githubApiUrl = 'https://api.github.com/repos/parthasdey2304/vastavikComputers/releases/latest';

  /// Returns the download URL if an update is available, otherwise returns null.
  static Future<String?> checkForUpdate() async {
    if (kIsWeb) return null; // Web doesn't use APK updates
    if (!Platform.isAndroid) return null; // Only Android supported for now

    try {
      final dio = Dio();
      final response = await dio.get(
        _githubApiUrl,
        options: Options(headers: {'Accept': 'application/vnd.github.v3+json'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final latestVersionTag = data['tag_name'] as String?;
        final assets = data['assets'] as List<dynamic>?;

        if (latestVersionTag != null && assets != null && assets.isNotEmpty) {
          final currentPackageInfo = await PackageInfo.fromPlatform();
          final currentVersion = currentPackageInfo.version;

          // Clean tags (e.g., 'v1.0.1' -> '1.0.1')
          final cleanedLatest = latestVersionTag.replaceAll('v', '');
          final cleanedCurrent = currentVersion.replaceAll('v', '');

          if (_isNewerVersion(cleanedLatest, cleanedCurrent)) {
            // Find the APK asset
            for (var asset in assets) {
              final assetName = asset['name'] as String;
              if (assetName.toLowerCase().endsWith('.apk')) {
                return asset['browser_download_url'] as String;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for update: $e');
    }
    return null;
  }

  /// Downloads and installs the APK from the given URL.
  /// Reports progress via the [onProgress] callback.
  static Future<void> downloadAndInstall(String apkUrl, Function(double) onProgress) async {
    try {
      // 1. Request Storage Permissions (required for Android < 11 mostly, but good practice)
      if (Platform.isAndroid) {
        if (await Permission.storage.request().isDenied) {
          // You could fallback to application documents directory, but external storage is safer for package installer
        }
      }

      // 2. Get local path to save APK
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        debugPrint('Could not get external storage directory');
        return;
      }

      final savePath = '${directory.path}/update.apk';
      final file = File(savePath);
      if (file.existsSync()) {
        file.deleteSync();
      }

      // 3. Download APK
      final dio = Dio();
      await dio.download(
        apkUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      // 4. Install APK
      final result = await OpenFilex.open(savePath);
      debugPrint('Install result: ${result.message}');
    } catch (e) {
      debugPrint('Error downloading or installing update: $e');
    }
  }

  /// Compares two semantic version strings. Returns true if v1 > v2.
  static bool _isNewerVersion(String v1, String v2) {
    try {
      final v1Parts = v1.split('.').map(int.parse).toList();
      final v2Parts = v2.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final part1 = i < v1Parts.length ? v1Parts[i] : 0;
        final part2 = i < v2Parts.length ? v2Parts[i] : 0;

        if (part1 > part2) return true;
        if (part1 < part2) return false;
      }
    } catch (e) {
      debugPrint('Version parse error: $e');
    }
    return false;
  }
}
