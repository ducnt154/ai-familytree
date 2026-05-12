import 'package:hive_flutter/hive_flutter.dart';

import '../models/family_event.dart';
import '../models/family_tree_record.dart';
import '../models/person.dart';
import '../models/relationship.dart';
import 'adapters/family_event_adapter.dart';
import 'adapters/family_tree_record_adapter.dart';
import 'adapters/person_adapter.dart';
import 'adapters/relationship_adapter.dart';
import 'hive_type_ids.dart';

/// Hive boxes và phiên bản schema cho FamilyTree (offline-first).
///
/// Gọi [FamilyTreeHive.init] một lần trước [runApp].
class FamilyTreeHive {
  FamilyTreeHive._({
    required this.meta,
    required this.familyTrees,
    required this.persons,
    required this.relationships,
    required this.events,
    required this.personAvatarPaths,
  });

  static const String metaBoxName = 'familytree_meta';
  static const String familyTreesBoxName = 'family_trees';
  static const String personsBoxName = 'persons';
  static const String relationshipsBoxName = 'relationships';
  static const String eventsBoxName = 'family_events';
  static const String personAvatarsBoxName = 'person_avatars';

  static const String schemaVersionKey = 'schemaVersion';

  /// Phiên bản schema hiện tại (tăng khi cần migrate dữ liệu).
  static const int currentSchemaVersion = 2;

  final Box<dynamic> meta;
  final Box<FamilyTreeRecord> familyTrees;
  final Box<Person> persons;
  final Box<Relationship> relationships;
  final Box<FamilyEvent> events;

  /// personId → đường dẫn file avatar (absolute); tách khỏi [PersonAdapter] để tránh migrate binary.
  /// Dùng [Box] không generic để tương thích test/VM (tránh treo với `Box<String>`).
  final Box personAvatarPaths;

  static FamilyTreeHive? _instance;

  static FamilyTreeHive get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('FamilyTreeHive.init() chưa được gọi.');
    }
    return i;
  }

  /// [hivePath]: truyền thư mục tạm từ `flutter test` (tránh `Hive.initFlutter` / platform channel treo).
  static Future<FamilyTreeHive> init({String? hivePath}) async {
    if (_instance != null) return _instance!;

    if (hivePath != null) {
      Hive.init(hivePath);
    } else {
      await Hive.initFlutter();
    }
    _registerAdapters();

    final meta = await Hive.openBox<dynamic>(metaBoxName);
    await _runMigrations(meta);

    final familyTrees =
        await Hive.openBox<FamilyTreeRecord>(familyTreesBoxName);
    final persons = await Hive.openBox<Person>(personsBoxName);
    final relationships =
        await Hive.openBox<Relationship>(relationshipsBoxName);
    final events = await Hive.openBox<FamilyEvent>(eventsBoxName);
    final personAvatarPaths = await Hive.openBox(personAvatarsBoxName);

    final layer = FamilyTreeHive._(
      meta: meta,
      familyTrees: familyTrees,
      persons: persons,
      relationships: relationships,
      events: events,
      personAvatarPaths: personAvatarPaths,
    );
    _instance = layer;
    return layer;
  }

  static void _registerAdapters() {
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
  }

  static Future<void> _runMigrations(Box<dynamic> meta) async {
    var version = meta.get(schemaVersionKey, defaultValue: 0) as int;
    if (version == currentSchemaVersion) return;

    while (version < currentSchemaVersion) {
      final next = version + 1;
      await _migrateTo(meta, from: version, to: next);
      version = next;
      await meta.put(schemaVersionKey, version);
    }
  }

  /// Hook migrate theo từng bước; mở rộng khi thêm field/bảng mới.
  static Future<void> _migrateTo(
    Box<dynamic> meta, {
    required int from,
    required int to,
  }) async {
    if (from == 0 && to == 1) {
      // Bản đầu: không có dữ liệu legacy cần chuyển.
      return;
    }
    if (from == 1 && to == 2) {
      // Thêm box `family_events` — mở khi init, không cần chuyển dữ liệu cũ.
      return;
    }
    throw StateError('Chưa có migration Hive $from → $to');
  }

  /// Dùng trong test hoặc reset (đóng boxes và xóa singleton).
  static Future<void> resetForTesting() async {
    await Hive.close();
    _instance = null;
  }
}
