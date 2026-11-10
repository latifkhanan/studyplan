import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studyplan/models/jadwal.dart';
import 'package:studyplan/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ringtone and custom audio preferences round-trip', () async {
    final service = NotificationService.instance;
    expect(await service.getSelectedRingtone(), 'default_alarm');
    expect(await service.getCustomAudioPath(), isNull);
    expect(await service.getCustomAudioName(), isNull);
    expect(await service.getCustomAudioUri(), isNull);

    await service.setSelectedRingtone('digital_alarm');
    expect(await service.getSelectedRingtone(), 'digital_alarm');

    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await service.setCustomAudioFile('C:\\audio\\alarm.mp3', 'alarm.mp3');

    expect(await service.getCustomAudioPath(), 'C:\\audio\\alarm.mp3');
    expect(await service.getCustomAudioName(), 'alarm.mp3');
    expect(await service.getSelectedRingtone(), 'custom_file');
    expect(await service.getCustomAudioUri(), isNull);
  });

  test('inactive and unsaved schedules do not request notifications', () async {
    await NotificationService.instance.scheduleWeeklyJadwalAlarm(_schedule());
    await NotificationService.instance.scheduleWeeklyJadwalAlarm(
      _schedule(id: 12, isAlarmActive: false),
    );
  });

  test(
    'notifications initialize and schedule supported ringtone variants',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final calls = <String>[];
      var failFirstSchedule = true;
      const channel = MethodChannel(
        'dexterous.com/flutter/local_notifications',
      );
      const soundChannel = MethodChannel(
        'com.example.studyplan/notification_sound',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            if (call.method == 'importCustomAlarmSound') {
              return 'content://media/audio/42';
            }
            if (call.method == 'initialize' ||
                call.method == 'requestNotificationsPermission' ||
                call.method == 'requestExactAlarmsPermission') {
              return true;
            }
            if (call.method == 'zonedSchedule' && failFirstSchedule) {
              failFirstSchedule = false;
              throw PlatformException(code: 'exact_alarm_denied');
            }
            return null;
          });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            soundChannel,
            (call) async => 'content://media/audio/42',
          );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(soundChannel, null),
      );

      final service = NotificationService.instance;
      await service.initialize();
      await service.requestPermissions();

      for (final ringtone in [
        'default_alarm',
        'default_notification',
        'digital_alarm',
        'gentle_chime',
      ]) {
        await service.setSelectedRingtone(ringtone);
        await service.scheduleWeeklyJadwalAlarm(
          _schedule(id: 20, alarmMinutesList: [5, 7, 30]),
        );
      }

      await service.setCustomAudioFile('/audio/custom.mp3', 'custom.mp3');
      expect(await service.getCustomAudioUri(), 'content://media/audio/42');
      await service.scheduleWeeklyJadwalAlarm(
        _schedule(id: 21, alarmMinutesList: [15]),
      );
      await service.scheduleTestAlarmInSeconds(30);
      await service.showInstantTestNotification();
      await service.stopAudioPreview();
      await service.cancelJadwalAlarm(20);
      await service.syncAllAlarms([
        _schedule(id: 22),
        _schedule(id: 23, isAlarmActive: false),
        _schedule(),
      ]);

      expect(calls, contains('initialize'));
      expect(calls, contains('requestNotificationsPermission'));
      expect(calls, contains('requestExactAlarmsPermission'));
      expect(calls, contains('zonedSchedule'));
      expect(calls, contains('show'));
      expect(calls, contains('cancel'));
    },
  );
}

Jadwal _schedule({
  int? id,
  bool isAlarmActive = true,
  List<int> alarmMinutesList = const [10],
}) => Jadwal(
  id: id,
  mataKuliah: 'Basis Data',
  jamMulai: '08.00',
  jamSelesai: '09.40',
  ruangan: 'A101',
  dosen: 'Dosen',
  hari: 'Senin',
  isAlarmActive: isAlarmActive,
  alarmMinutesList: alarmMinutesList,
);
