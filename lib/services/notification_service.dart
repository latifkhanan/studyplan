import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/jadwal.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String _ringtonePrefKey = 'selected_ringtone_sound';
  static const String _customSoundPathKey = 'custom_ringtone_file_path';
  static const String _customSoundNameKey = 'custom_ringtone_file_name';
  static const String _customSoundUriKey = 'custom_ringtone_media_uri';
  static const MethodChannel _soundChannel = MethodChannel(
    'com.example.studyplan/notification_sound',
  );
  static const List<int> _supportedAlarmMinutes = [5, 10, 15, 30];

  NotificationService._init();

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    // Configure timezone to match Indonesia / local offset
    final offsetHours = DateTime.now().timeZoneOffset.inHours;
    String tzLocationName = 'Asia/Jakarta';
    if (offsetHours == 8) {
      tzLocationName = 'Asia/Makassar';
    } else if (offsetHours == 9) {
      tzLocationName = 'Asia/Jayapura';
    }

    try {
      tz.setLocalLocation(tz.getLocation(tzLocationName));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      } catch (_) {}
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification clicked: ${details.payload}');
      },
    );

    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  Future<String> getSelectedRingtone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ringtonePrefKey) ?? 'default_alarm';
  }

  Future<void> setSelectedRingtone(String ringtoneKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ringtonePrefKey, ringtoneKey);
  }

  Future<String?> getCustomAudioPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customSoundPathKey);
  }

  Future<String?> getCustomAudioName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customSoundNameKey);
  }

  Future<String?> getCustomAudioUri() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customSoundUriKey);
  }

  Future<void> setCustomAudioFile(String filePath, String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    String? soundUri;
    if (defaultTargetPlatform == TargetPlatform.android) {
      soundUri = await _soundChannel.invokeMethod<String>(
        'importCustomAlarmSound',
        {'path': filePath, 'name': fileName},
      );
      if (soundUri == null || soundUri.isEmpty) {
        throw StateError('Android did not return a notification sound URI.');
      }
      await prefs.setString(_customSoundUriKey, soundUri);
    }
    await prefs.setString(_customSoundPathKey, filePath);
    await prefs.setString(_customSoundNameKey, fileName);
    await setSelectedRingtone('custom_file');
  }

  Future<AndroidNotificationDetails> _getAndroidDetailsForRingtone(
    String ringtoneKey,
  ) async {
    AudioAttributesUsage usage = AudioAttributesUsage.alarm;
    AndroidNotificationCategory category = AndroidNotificationCategory.alarm;
    String channelId = 'studyplan_alarm_channel_v4';
    String channelName = 'Alarm Jadwal Kuliah Utama';
    AndroidNotificationSound? sound;

    if (ringtoneKey == 'default_notification') {
      usage = AudioAttributesUsage.notification;
      category = AndroidNotificationCategory.reminder;
      channelId = 'studyplan_notif_channel_v2';
      channelName = 'Notifikasi Jadwal Kuliah';
      sound = const UriAndroidNotificationSound(
        'content://settings/system/notification_sound',
      );
    } else if (ringtoneKey == 'digital_alarm') {
      channelId = 'studyplan_digital_channel_v3';
      channelName = 'Alarm Digital Melodi';
      sound = const RawResourceAndroidNotificationSound('melodi');
    } else if (ringtoneKey == 'gentle_chime') {
      channelId = 'studyplan_gentle_channel_v3';
      channelName = 'Chime Lembut';
      sound = const RawResourceAndroidNotificationSound('lembut');
    } else if (ringtoneKey == 'custom_file') {
      channelName = 'Alarm File Audio Kustom';
      if (defaultTargetPlatform == TargetPlatform.android) {
        final soundUri = await getCustomAudioUri();
        if (soundUri == null || soundUri.isEmpty) {
          throw StateError(
            'Pilih ulang file MP3 kustom agar bisa dipakai sebagai suara notifikasi.',
          );
        }
        final mediaId = Uri.parse(soundUri).pathSegments.last;
        channelId = 'studyplan_custom_audio_$mediaId';
        sound = UriAndroidNotificationSound(soundUri);
      }
    } else {
      sound = const UriAndroidNotificationSound(
        'content://settings/system/alarm_alert',
      );
    }

    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Alarm dan notifikasi pengingat otomatis sebelum jadwal kelas berlangsung',
      importance: Importance.max,
      priority: Priority.max,
      category: category,
      audioAttributesUsage: usage,
      sound: sound,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      ticker: 'Kelas Anda segera dimulai!',
    );
  }

  int _dayNameToWeekday(String hari) {
    switch (hari.toLowerCase().trim()) {
      case 'senin':
        return DateTime.monday;
      case 'selasa':
        return DateTime.tuesday;
      case 'rabu':
        return DateTime.wednesday;
      case 'kamis':
        return DateTime.thursday;
      case 'jumat':
        return DateTime.friday;
      case 'sabtu':
        return DateTime.saturday;
      case 'minggu':
        return DateTime.sunday;
      default:
        return DateTime.monday;
    }
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(
    int classWeekday,
    int classHour,
    int classMinute,
    int minutesBefore,
  ) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime classDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      classHour,
      classMinute,
    );

    while (classDate.weekday != classWeekday) {
      classDate = classDate.add(const Duration(days: 1));
    }

    var alarmDate = classDate.subtract(Duration(minutes: minutesBefore));
    if (!alarmDate.isAfter(now)) {
      classDate = classDate.add(const Duration(days: 7));
      alarmDate = classDate.subtract(Duration(minutes: minutesBefore));
    }

    return alarmDate;
  }

  Future<void> scheduleWeeklyJadwalAlarm(Jadwal jadwal) async {
    if (jadwal.id == null || !jadwal.isAlarmActive) return;

    await initialize();
    await requestPermissions();
    await cancelJadwalAlarm(jadwal.id!);

    final ringtoneKey = await getSelectedRingtone();
    final androidDetails = await _getAndroidDetailsForRingtone(ringtoneKey);

    const iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final parts = jadwal.jamMulai.replaceAll('.', ':').split(':');
    if (parts.length < 2) return;

    final startHour = int.tryParse(parts[0]) ?? 8;
    final startMinute = int.tryParse(parts[1]) ?? 0;

    final weekday = _dayNameToWeekday(jadwal.hari);
    final title = '🔔 Kelas Anda Segera Dimulai!';
    final alarmMinutes = jadwal.alarmMinutesList.toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    for (final minutesBefore in alarmMinutes) {
      if (!_supportedAlarmMinutes.contains(minutesBefore)) continue;
      final scheduledDate = _nextInstanceOfDayAndTime(
        weekday,
        startHour,
        startMinute,
        minutesBefore,
      );
      final notificationId = _alarmNotificationId(jadwal.id!, minutesBefore);
      final body =
          'Mata kuliah ${jadwal.mataKuliah} akan dimulai $minutesBefore menit lagi di ${jadwal.ruangan}. Dosen: ${jadwal.dosen}';

      debugPrint(
        'Scheduling alarm for ${jadwal.mataKuliah} at $scheduledDate (weekday $weekday, $minutesBefore minutes before)',
      );
      try {
        await _notificationsPlugin.zonedSchedule(
          notificationId,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: 'jadwal_${jadwal.id}',
        );
        debugPrint(
          'Successfully scheduled alarm for ${jadwal.mataKuliah} ($minutesBefore minutes before)',
        );
      } catch (e) {
        debugPrint('Error scheduling exact alarm, trying inexact: $e');
        try {
          await _notificationsPlugin.zonedSchedule(
            notificationId,
            title,
            body,
            scheduledDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: 'jadwal_${jadwal.id}',
          );
        } catch (err) {
          debugPrint('Error scheduling fallback alarm: $err');
        }
      }
    }
  }

  int _alarmNotificationId(int jadwalId, int minutesBefore) {
    return 1000000000 +
        jadwalId * _supportedAlarmMinutes.length +
        _supportedAlarmMinutes.indexOf(minutesBefore);
  }

  Future<void> scheduleTestAlarmInSeconds(int seconds) async {
    await initialize();
    await requestPermissions();

    final ringtoneKey = await getSelectedRingtone();

    final androidDetails = await _getAndroidDetailsForRingtone(ringtoneKey);

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentSound: true,
        presentAlert: true,
      ),
    );

    final scheduledDate = tz.TZDateTime.now(tz.local)
        .add(Duration(seconds: seconds));

    try {
      await _notificationsPlugin.zonedSchedule(
        8888,
        '🔔 Kelas Anda Segera Dimulai!',
        'Uji coba notifikasi & alarm jadwal kuliah berhasil berbunyi!',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'test_alarm',
      );
    } catch (_) {
      try {
        await _notificationsPlugin.zonedSchedule(
          8888,
          '🔔 Kelas Anda Segera Dimulai!',
          'Uji coba notifikasi & alarm jadwal kuliah berhasil berbunyi!',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'test_alarm',
        );
      } catch (_) {}
    }
  }

  Future<void> showInstantTestNotification() async {
    await initialize();
    await requestPermissions();

    final ringtoneKey = await getSelectedRingtone();

    final androidDetails = await _getAndroidDetailsForRingtone(ringtoneKey);

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentSound: true,
        presentAlert: true,
      ),
    );

    await _notificationsPlugin.show(
      9999,
      '🔔 Kelas Anda Segera Dimulai!',
      'Uji coba notifikasi & alarm jadwal kuliah berhasil berbunyi!',
      notificationDetails,
    );
  }

  Future<void> stopAudioPreview() async {
    await _notificationsPlugin.cancel(9999);
    await _notificationsPlugin.cancel(8888);
  }

  Future<void> cancelJadwalAlarm(int id) async {
    await initialize();
    await _notificationsPlugin.cancel(id);
    for (final minutesBefore in _supportedAlarmMinutes) {
      await _notificationsPlugin.cancel(
        _alarmNotificationId(id, minutesBefore),
      );
    }
  }

  Future<void> syncAllAlarms(List<Jadwal> schedules) async {
    await initialize();
    for (var j in schedules) {
      if (j.id != null) {
        if (j.isAlarmActive) {
          await scheduleWeeklyJadwalAlarm(j);
        } else {
          await cancelJadwalAlarm(j.id!);
        }
      }
    }
  }
}
