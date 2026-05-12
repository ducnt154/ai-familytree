import 'dart:io';

import 'package:familytree/data/hive/adapters/family_event_adapter.dart';
import 'package:familytree/data/hive/adapters/family_tree_record_adapter.dart';
import 'package:familytree/data/hive/adapters/person_adapter.dart';
import 'package:familytree/data/hive/adapters/relationship_adapter.dart';
import 'package:familytree/data/hive/hive_type_ids.dart';
import 'package:familytree/data/models/family_event.dart';
import 'package:familytree/data/models/family_event_kind.dart';
import 'package:familytree/data/models/family_tree_record.dart';
import 'package:familytree/data/models/gender.dart';
import 'package:familytree/data/models/person.dart';
import 'package:familytree/data/models/relationship.dart';
import 'package:familytree/data/models/relationship_kind.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory dir;

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('familytree_hive_');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(FamilyTreeHiveTypeIds.familyTreeRecord)) {
      Hive.registerAdapter(FamilyTreeRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(FamilyTreeHiveTypeIds.person)) {
      Hive.registerAdapter(PersonAdapter());
    }
    if (!Hive.isAdapterRegistered(FamilyTreeHiveTypeIds.relationship)) {
      Hive.registerAdapter(RelationshipAdapter());
    }
    if (!Hive.isAdapterRegistered(FamilyTreeHiveTypeIds.familyEvent)) {
      Hive.registerAdapter(FamilyEventAdapter());
    }
  });

  tearDownAll(() async {
    await Hive.close();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  test('PersonAdapter roundtrip', () async {
    final now = DateTime.utc(2026, 4, 6, 12);
    final original = Person(
      id: 'p1',
      familyTreeId: 't1',
      displayName: 'Nguyễn A',
      birthDate: DateTime.utc(1990, 1, 2),
      deathDate: null,
      notes: 'ghi chú',
      createdAt: now,
      updatedAt: now,
    );
    final box = await Hive.openBox<Person>('p_test');
    await box.put('k', original);
    final read = box.get('k')!;
    expect(read.id, original.id);
    expect(read.familyTreeId, original.familyTreeId);
    expect(read.displayName, original.displayName);
    expect(read.birthDate, original.birthDate);
    expect(read.deathDate, original.deathDate);
    expect(read.notes, original.notes);
    expect(read.createdAt, original.createdAt);
    expect(read.updatedAt, original.updatedAt);
    await box.close();
  });

  test('PersonAdapter roundtrip với gender', () async {
    final now = DateTime.utc(2026, 4, 6, 12);
    final original = Person(
      id: 'p1',
      familyTreeId: 't1',
      displayName: 'Trần B',
      gender: Gender.female,
      birthDate: DateTime.utc(1990, 1, 2),
      deathDate: null,
      notes: null,
      createdAt: now,
      updatedAt: now,
    );
    final box = await Hive.openBox<Person>('p_test_g');
    await box.put('k', original);
    final read = box.get('k')!;
    expect(read.gender, Gender.female);
    await box.close();
  });

  test('PersonAdapter roundtrip với địa chỉ', () async {
    final now = DateTime.utc(2026, 4, 6, 12);
    final original = Person(
      id: 'p1',
      familyTreeId: 't1',
      displayName: 'Lê C',
      gender: Gender.male,
      birthDate: null,
      deathDate: null,
      notes: null,
      address: '1 Đường Lê Lợi, Q1, TP.HCM',
      createdAt: now,
      updatedAt: now,
    );
    final box = await Hive.openBox<Person>('p_test_addr');
    await box.put('k', original);
    final read = box.get('k')!;
    expect(read.address, original.address);
    await box.close();
  });

  test('RelationshipAdapter roundtrip', () async {
    final now = DateTime.utc(2026, 4, 6, 12);
    final original = Relationship(
      id: 'r1',
      familyTreeId: 't1',
      fromPersonId: 'a',
      toPersonId: 'b',
      kind: RelationshipKind.spouse,
      createdAt: now,
      updatedAt: now,
    );
    final box = await Hive.openBox<Relationship>('r_test');
    await box.put('k', original);
    final read = box.get('k')!;
    expect(read.id, original.id);
    expect(read.familyTreeId, original.familyTreeId);
    expect(read.fromPersonId, original.fromPersonId);
    expect(read.toPersonId, original.toPersonId);
    expect(read.kind, original.kind);
    expect(read.createdAt, original.createdAt);
    expect(read.updatedAt, original.updatedAt);
    await box.close();
  });

  test('FamilyTreeRecordAdapter roundtrip', () async {
    final now = DateTime.utc(2026, 4, 6, 12);
    final original = FamilyTreeRecord(
      id: 't1',
      name: 'Họ Nguyễn',
      createdAt: now,
      updatedAt: now,
    );
    final box = await Hive.openBox<FamilyTreeRecord>('ft_test');
    await box.put('k', original);
    final read = box.get('k')!;
    expect(read.id, original.id);
    expect(read.name, original.name);
    expect(read.createdAt, original.createdAt);
    expect(read.updatedAt, original.updatedAt);
    await box.close();
  });

  test('FamilyEventAdapter roundtrip', () async {
    final now = DateTime.utc(2026, 4, 6, 12);
    final original = FamilyEvent(
      id: 'e1',
      familyTreeId: 't1',
      personId: 'p1',
      eventKind: FamilyEventKind.birthday,
      eventDate: DateTime.utc(1990, 5, 12),
      notes: 'ghi chú',
      reminderEnabled: true,
      reminderDays: 3,
      createdAt: now,
      updatedAt: now,
    );
    final box = await Hive.openBox<FamilyEvent>('ev_test');
    await box.put('k', original);
    final read = box.get('k')!;
    expect(read.id, original.id);
    expect(read.familyTreeId, original.familyTreeId);
    expect(read.personId, original.personId);
    expect(read.eventKind, original.eventKind);
    expect(read.eventDate, original.eventDate);
    expect(read.notes, original.notes);
    expect(read.reminderEnabled, original.reminderEnabled);
    expect(read.reminderDays, original.reminderDays);
    expect(read.createdAt, original.createdAt);
    expect(read.updatedAt, original.updatedAt);
    await box.close();
  });

  test('typeIds không trùng', () {
    expect(
      {
        FamilyTreeHiveTypeIds.familyTreeRecord,
        FamilyTreeHiveTypeIds.person,
        FamilyTreeHiveTypeIds.relationship,
        FamilyTreeHiveTypeIds.familyEvent,
      }.length,
      4,
    );
  });
}
