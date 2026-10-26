import 'dart:io';

import 'package:clock/clock.dart';
import 'package:fleet_pulse_mobile/models/delivery_proof_draft.dart';
import 'package:fleet_pulse_mobile/models/ids.dart';
import 'package:fleet_pulse_mobile/services/storage/proof_draft_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  const DriverId courier = DriverId(7);
  const DriverId another = DriverId(8);
  const OrderId job = OrderId(5);
  final DateTime now = DateTime.utc(2026, 10, 22, 8);
  late Directory directory;
  late String boxName;
  int boxes = 0;

  ProofDraftStore open() => new ProofDraftStore.withOpener(
    () => Hive.openBox<Map<dynamic, dynamic>>(boxName),
  );

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('proof_drafts');
    Hive.init(directory.path);
  });

  setUp(() => boxName = 'drafts_${boxes++}');

  tearDown(() => Hive.deleteBoxFromDisk(boxName));

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('a photo and a signature survive the app closing', () async {
    await withClock(new Clock.fixed(now), () async {
      final ProofDraftStore first = open();
      await first.keepPhoto(courier, job, 'https://storage.test/p.jpg');
      await first.keepSignature(courier, job, 'data:image/png;base64,AAAA');
      await Hive.box<Map<dynamic, dynamic>>(boxName).close();

      expect(
        await open().read(courier, job),
        const DeliveryProofDraft(
          photoUrl: 'https://storage.test/p.jpg',
          signature: 'data:image/png;base64,AAAA',
        ),
      );
    });
  });

  test('another courier never reads the proof of this courier', () async {
    final ProofDraftStore sut = open();

    await sut.keepPhoto(courier, job, 'https://storage.test/p.jpg');

    expect(await sut.read(another, job), const DeliveryProofDraft());
  });

  test('a proof older than a day is dropped', () async {
    final ProofDraftStore sut = open();

    await withClock(
      new Clock.fixed(now),
      () => sut.keepPhoto(courier, job, 'https://storage.test/p.jpg'),
    );

    expect(
      await withClock(
        new Clock.fixed(now.add(const Duration(hours: 25))),
        () => sut.read(courier, job),
      ),
      const DeliveryProofDraft(),
    );
  });

  test('a forgotten proof is gone', () async {
    final ProofDraftStore sut = open();

    await sut.keepSignature(courier, job, 'data:image/png;base64,AAAA');
    await sut.forget(courier, job);

    expect(await sut.read(courier, job), const DeliveryProofDraft());
  });
}
