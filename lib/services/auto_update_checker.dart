import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/update_config.dart';
import '../views/widgets/update_dialog.dart';
import 'update_service.dart';

/// Cek update otomatis di latar belakang saat aplikasi dibuka.
///
/// - Dibatasi sekali per [checkInterval] agar tidak kena batas API GitHub
///   (60 request/jam per IP tanpa login).
/// - Versi yang dipilih "Lewati versi ini" tidak ditawarkan lagi.
/// - Gagal cek (offline, dsb.) diabaikan diam-diam.
class AutoUpdateChecker {
  AutoUpdateChecker._();

  static const checkInterval = Duration(hours: 3);
  static const _lastCheckKey = 'update_last_check_at';
  static const _skippedKey = 'update_skipped_version';

  static bool _running = false;

  static Future<void> run(BuildContext context) async {
    if (_running || !isUpdateConfigured) return;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _running = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final last = prefs.getInt(_lastCheckKey);
      if (last != null &&
          now.difference(DateTime.fromMillisecondsSinceEpoch(last)) <
              checkInterval) {
        return;
      }

      final current = await UpdateService.currentVersion();
      final latest = await UpdateService().fetchLatest();
      await prefs.setInt(_lastCheckKey, now.millisecondsSinceEpoch);

      if (!UpdateService.isNewer(latest.version, current)) return;
      if (prefs.getString(_skippedKey) == latest.version) return;
      if (!context.mounted) return;

      final skip = await showUpdateDialog(
        context,
        release: latest,
        currentVersion: current,
      );
      if (skip == true) await prefs.setString(_skippedKey, latest.version);
    } catch (e) {
      debugPrint('Auto update check gagal: $e');
    } finally {
      _running = false;
    }
  }
}
