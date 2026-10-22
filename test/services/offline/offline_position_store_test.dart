import 'dart:io';

import 'package:fleet_pulse_mobile/models/telemetry_ping.dart';
import 'package:fleet_pulse_mobile/services/offline/offline_position_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  final DateTime start = DateTime.utc(2026, 10, 21, 8);
  late Directory directory;
  late String boxName;
  int boxes = 0;

  TelemetryPing at(int seconds) => new TelemetryPing(
    latitude: -6.2,
    longitude: 106.8,
    recordedAt: start.add(new Duration(seconds: seconds)),
    speedKmh: 12.5,
  );

  OfflinePositionStore open({int capacity = 5}) =>
      new OfflinePositionStore.withOpener(
        () => Hive.openLazyBox<Map<dynamic, dynamic>>(boxName),
        capacity: capacity,
      );

  List<int> secondsOf(List<TelemetryPing> pings) => <int>[
    for (final TelemetryPing ping in pings)
      ping.recordedAt.difference(start).inSeconds,
  ];

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('offline_positions');
    Hive.init(directory.path);
  });

  setUp(() => boxName = 'positions_${boxes++}');

  tearDown(() => Hive.deleteBoxFromDisk(boxName));

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'positions come back oldest first, whatever order they were kept in',
    () async {
      final OfflinePositionStore sut = open();

      for (final int seconds in <int>[30, 10, 20]) {
        await sut.add(at(seconds));
      }

      expect(secondsOf(await sut.oldest(10)), <int>[10, 20, 30]);
      expect(secondsOf(await sut.oldest(2)), <int>[10, 20]);
    },
  );

  test('a position comes back exactly as it was kept', () async {
    final OfflinePositionStore sut = open();

    await sut.add(at(10));

    expect((await sut.oldest(1)).single, at(10));
  });

  test('one moment is kept once', () async {
    final OfflinePositionStore sut = open();

    await sut.add(at(10));
    await sut.add(at(10));

    expect(await sut.count(), 1);
  });

  test('past its capacity the store forgets the oldest positions', () async {
    final OfflinePositionStore sut = open(capacity: 3);

    for (int seconds = 0; seconds < 5; seconds++) {
      await sut.add(at(seconds));
    }

    expect(secondsOf(await sut.oldest(10)), <int>[2, 3, 4]);
  });

  test('positions recorded before a cutoff are discarded', () async {
    final OfflinePositionStore sut = open();

    for (final int seconds in <int>[0, 10, 20]) {
      await sut.add(at(seconds));
    }

    expect(
      await sut.discardRecordedBefore(start.add(const Duration(seconds: 10))),
      1,
    );
    expect(secondsOf(await sut.oldest(10)), <int>[10, 20]);
  });

  test('remove deletes exactly the positions named', () async {
    final OfflinePositionStore sut = open();

    for (final int seconds in <int>[0, 10, 20]) {
      await sut.add(at(seconds));
    }

    await sut.remove(<TelemetryPing>[at(0), at(20)]);

    expect(secondsOf(await sut.oldest(10)), <int>[10]);
  });

  test('the positions survive the app closing', () async {
    await open().add(at(10));
    await Hive.lazyBox<Map<dynamic, dynamic>>(boxName).close();

    expect(secondsOf(await open().oldest(10)), <int>[10]);
  });

  test('an entry that is not a position is dropped, not sent', () async {
    final OfflinePositionStore sut = open();
    await sut.add(at(10));
    await Hive.lazyBox<Map<dynamic, dynamic>>(
      boxName,
    ).put('00000000000000001', <String, Object>{'latitude': 'north'});

    expect(secondsOf(await sut.oldest(10)), <int>[10]);
    expect(await sut.count(), 1);
  });
}
