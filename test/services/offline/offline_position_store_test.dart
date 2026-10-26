import 'dart:io';

import 'package:fleet_pulse_mobile/models/ids.dart';
import 'package:fleet_pulse_mobile/models/telemetry_ping.dart';
import 'package:fleet_pulse_mobile/services/offline/offline_position_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  final DateTime start = DateTime.utc(2026, 10, 21, 8);
  const DriverId courier = DriverId(7);
  const DriverId another = DriverId(8);
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
        await sut.add(courier, at(seconds));
      }

      expect(secondsOf(await sut.oldest(courier, 10)), <int>[10, 20, 30]);
      expect(secondsOf(await sut.oldest(courier, 2)), <int>[10, 20]);
    },
  );

  test('a position comes back exactly as it was kept', () async {
    final OfflinePositionStore sut = open();

    await sut.add(courier, at(10));

    expect((await sut.oldest(courier, 1)).single, at(10));
  });

  test('one moment is kept once', () async {
    final OfflinePositionStore sut = open();

    await sut.add(courier, at(10));
    await sut.add(courier, at(10));

    expect(await sut.count(), 1);
  });

  test('past its capacity the store forgets the oldest positions', () async {
    final OfflinePositionStore sut = open(capacity: 3);

    for (int seconds = 0; seconds < 5; seconds++) {
      await sut.add(courier, at(seconds));
    }

    expect(secondsOf(await sut.oldest(courier, 10)), <int>[2, 3, 4]);
  });

  test('positions recorded before a cutoff are discarded', () async {
    final OfflinePositionStore sut = open();

    for (final int seconds in <int>[0, 10, 20]) {
      await sut.add(courier, at(seconds));
    }

    expect(
      await sut.discardRecordedBefore(start.add(const Duration(seconds: 10))),
      1,
    );
    expect(secondsOf(await sut.oldest(courier, 10)), <int>[10, 20]);
  });

  test('remove deletes exactly the positions named', () async {
    final OfflinePositionStore sut = open();

    for (final int seconds in <int>[0, 10, 20]) {
      await sut.add(courier, at(seconds));
    }

    await sut.remove(courier, <TelemetryPing>[at(0), at(20)]);

    expect(secondsOf(await sut.oldest(courier, 10)), <int>[10]);
  });

  test('the positions survive the app closing', () async {
    await open().add(courier, at(10));
    await Hive.lazyBox<Map<dynamic, dynamic>>(boxName).close();

    expect(secondsOf(await open().oldest(courier, 10)), <int>[10]);
  });

  test('an entry that is not a position is dropped, not sent', () async {
    final OfflinePositionStore sut = open();
    await sut.add(courier, at(10));
    await Hive.lazyBox<Map<dynamic, dynamic>>(
      boxName,
    ).put('7:00000000000000001', <String, Object>{'latitude': 'north'});

    expect(secondsOf(await sut.oldest(courier, 10)), <int>[10]);
    expect(await sut.count(), 1);
  });
  test('one courier never gets another courier positions', () async {
    final OfflinePositionStore sut = open();

    await sut.add(courier, at(10));
    await sut.add(another, at(20));

    expect(secondsOf(await sut.oldest(courier, 10)), <int>[10]);
    expect(secondsOf(await sut.oldest(another, 10)), <int>[20]);
  });

  test('removing one courier batch leaves the other courier alone', () async {
    final OfflinePositionStore sut = open();

    await sut.add(courier, at(10));
    await sut.add(another, at(10));
    await sut.remove(courier, <TelemetryPing>[at(10)]);

    expect(await sut.oldest(courier, 10), isEmpty);
    expect(secondsOf(await sut.oldest(another, 10)), <int>[10]);
  });

  test('capacity and age apply across every courier on the phone', () async {
    final OfflinePositionStore sut = open(capacity: 2);

    await sut.add(courier, at(0));
    await sut.add(another, at(5));
    await sut.add(courier, at(10));

    expect(secondsOf(await sut.oldest(courier, 10)), <int>[10]);
    expect(secondsOf(await sut.oldest(another, 10)), <int>[5]);
    expect(
      await sut.discardRecordedBefore(start.add(const Duration(seconds: 6))),
      1,
    );
    expect(await sut.count(), 1);
  });

  test(
    'positions an older build kept without a courier are dropped, never sent',
    () async {
      final LazyBox<Map<dynamic, dynamic>> box =
          await Hive.openLazyBox<Map<dynamic, dynamic>>(boxName);
      await box.put('00000000000000001', <String, Object>{
        'latitude': -6.2,
        'longitude': 106.8,
        'recorded_at': start.toIso8601String(),
      });
      await box.close();

      final OfflinePositionStore sut = open();

      expect(await sut.count(), 0);
      expect(await sut.oldest(courier, 10), isEmpty);
    },
  );
}
