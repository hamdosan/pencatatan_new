import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Menjadwalkan pengingat jika user belum mencatat pengeluaran selama 1 hari.
///
/// Setiap kali ada catatan baru, jadwal lama dibatalkan dan pengingat
/// dijadwalkan ulang 24 jam setelah input terakhir.
class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  static const _notificationId = 1001;
  static const _lastInputKey = 'last_expense_input_at';
  static const reminderDelay = Duration(days: 1);

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_reminder',
      'Pengingat Harian',
      channelDescription:
          'Pengingat jika belum mencatat pengeluaran selama 1 hari',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  Future<void> init() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _ready = true;

    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_lastInputKey);
    if (lastMs == null) {
      // Belum pernah input: anggap mulai dihitung sejak app pertama dibuka.
      await markExpenseInput();
    } else {
      await _schedule(DateTime.fromMillisecondsSinceEpoch(lastMs));
    }
  }

  /// Panggil setiap kali user menambah catatan pengeluaran.
  Future<void> markExpenseInput() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastInputKey, now.millisecondsSinceEpoch);
    await _schedule(now);
  }

  Future<void> _schedule(DateTime lastInput) async {
    if (!_ready) return;
    await _plugin.cancel(id: _notificationId);

    var target = lastInput.add(reminderDelay);
    final now = DateTime.now();
    // Sudah lewat 1 hari (mis. app lama tidak dibuka): ingatkan sebentar lagi.
    if (!target.isAfter(now)) target = now.add(const Duration(minutes: 1));

    await _plugin.zonedSchedule(
      id: _notificationId,
      title: 'Jangan lupa catat pengeluaran',
      body: 'Kamu belum mencatat pengeluaran selama 1 hari terakhir.',
      scheduledDate: tz.TZDateTime.from(target.toUtc(), tz.UTC),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
