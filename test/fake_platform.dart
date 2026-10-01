import 'dart:async';

import 'package:chaos_alert/src/platform.dart';
import 'package:chaos_core/chaos_core.dart';

/// A platform that records what was scheduled and answers as told.
class FakePlatform implements AlarmPlatform {
  DateTime? nag;
  bool? chime;
  List<ScheduledRing> rings = [];
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

  @override
  Future<void> scheduleNag(DateTime? at, {required bool chime}) async {
    nag = at;
    this.chime = chime;
  }

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
