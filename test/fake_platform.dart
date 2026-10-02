import 'dart:async';

import 'package:chaos_alert/src/platform.dart';
import 'package:chaos_core/chaos_core.dart';

/// A platform that records what was scheduled and answers as told.
class FakePlatform implements AlarmPlatform {
  List<DateTime> nags = [];
  bool? chime;
  final events = <PlatformEvent>[];
  List<ScheduledRing> rings = [];
  List<AwakeNotice> awake = [];
  int awakeCleared = 0;
  int stops = 0;
  final requested = <Permission>[];
  Map<Permission, bool> granted = {for (final p in Permission.values) p: true};
  List<Sound> inventory = [
    for (var i = 0; i < 3; i++) Sound(uri: 'alarm/$i', group: SoundGroup.alarm),
    for (var i = 0; i < 3; i++)
      Sound(uri: 'notification/$i', group: SoundGroup.notification),
    for (var i = 0; i < 20; i++)
      Sound(
        uri: 'song/$i',
        group: SoundGroup.song,
        length: const Duration(minutes: 3),
      ),
  ];
  Launch? initial;
  final _launches = StreamController<Launch>.broadcast();

  void launch(Launch launch) => _launches.add(launch);

  DateTime? get nag => nags.isEmpty ? null : nags.first;

  @override
  Future<void> scheduleNags(List<DateTime> nags, {required bool chime}) async {
    this.nags = nags;
    this.chime = chime;
  }

  @override
  Future<List<PlatformEvent>> drainEvents() async {
    final drained = List.of(events);
    events.clear();
    return drained;
  }

  @override
  Future<void> scheduleAwake(List<AwakeNotice> notices) async =>
      awake = notices;

  @override
  Future<void> clearAwakeNotice() async => awakeCleared++;

  @override
  Future<void> scheduleRings(List<ScheduledRing> rings) async =>
      this.rings = rings;

  @override
  Future<void> stopRinging() async => stops++;

  @override
  Future<List<Sound>> sounds() async => inventory;

  @override
  Future<Map<Permission, bool>> permissions() async => Map.of(granted);

  @override
  Future<void> request(Permission permission) async {
    requested.add(permission);
    granted[permission] = true;
  }

  @override
  Future<Launch?> initialLaunch() async => initial;

  @override
  Stream<Launch> get launches => _launches.stream;
}
