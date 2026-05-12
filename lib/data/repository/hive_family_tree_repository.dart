import 'package:hive/hive.dart';

import '../../services/avatar_storage.dart';
import '../errors/storage_exception.dart';
import '../hive/family_tree_hive.dart';
import '../models/family_event.dart';
import '../models/family_tree_record.dart';
import '../models/person.dart';
import '../models/relationship.dart';
import 'family_tree_repository.dart';

/// Triển khai [FamilyTreeRepository] trên Hive ([FamilyTreeHive]).
class HiveFamilyTreeRepository implements FamilyTreeRepository {
  HiveFamilyTreeRepository(this._hive);

  final FamilyTreeHive _hive;

  Box<FamilyTreeRecord> get _trees => _hive.familyTrees;
  Box<Person> get _persons => _hive.persons;
  Box<Relationship> get _relationships => _hive.relationships;
  Box<FamilyEvent> get _events => _hive.events;
  Box get _avatarPaths => _hive.personAvatarPaths;

  static int _dateOrdinal(DateTime d) =>
      d.year * 10000 + d.month * 100 + d.day;

  Person _withAvatar(Person p) {
    final path = _avatarPaths.get(p.id) as String?;
    if (path == null || path.isEmpty) return p;
    return p.copyWith(avatarLocalPath: path);
  }

  Future<void> _purgeAvatarForPerson(String personId) async {
    final path = _avatarPaths.get(personId) as String?;
    await AvatarStorage.deleteFileIfExists(path);
    await _avatarPaths.delete(personId);
  }

  @override
  Future<List<FamilyTreeRecord>> listTrees() async {
    try {
      final list = _trees.values.toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    } catch (e, st) {
      Error.throwWithStackTrace(
        StorageException('Không đọc được danh sách cây gia phả (offline).', e),
        st,
      );
    }
  }

  @override
  Future<FamilyTreeRecord?> getTree(String id) async {
    try {
      return _trees.get(id);
    } catch (e, st) {
      Error.throwWithStackTrace(
        StorageException('Không đọc được cây gia phả.', e),
        st,
      );
    }
  }

  @override
  Future<void> upsertTree(FamilyTreeRecord record) async {
    try {
      await _trees.put(record.id, record);
    } catch (e, st) {
      Error.throwWithStackTrace(
        StorageException('Không lưu được cây gia phả.', e),
        st,
      );
    }
  }

  @override
  Future<void> deleteTree(String id) async {
    try {
      await _deleteEventsForTree(id);
      await _deleteRelationshipsForTree(id);
      await _deletePersonsForTree(id);
      await _trees.delete(id);
    } catch (e, st) {
      Error.throwWithStackTrace(
        StorageException('Không xóa được cây gia phả.', e),
        st,
      );
    }
  }

  Future<void> _deletePersonsForTree(String familyTreeId) async {
    final keys = <dynamic>[];
    for (final key in _persons.keys) {
      final p = _persons.get(key);
      if (p != null && p.familyTreeId == familyTreeId) {
        keys.add(key);
      }
    }
    for (final key in keys) {
      await _purgeAvatarForPerson(key as String);
    }
    await _persons.deleteAll(keys);
  }

  Future<void> _deleteEventsForTree(String familyTreeId) async {
    final keys = <dynamic>[];
    for (final key in _events.keys) {
      final e = _events.get(key);
      if (e != null && e.familyTreeId == familyTreeId) {
        keys.add(key);
      }
    }
    await _events.deleteAll(keys);
  }

  Future<void> _deleteRelationshipsForTree(String familyTreeId) async {
    final keys = <dynamic>[];
    for (final key in _relationships.keys) {
      final r = _relationships.get(key);
      if (r != null && r.familyTreeId == familyTreeId) {
        keys.add(key);
      }
    }
    await _relationships.deleteAll(keys);
  }

  @override
  Future<List<Person>> listPersons(String familyTreeId) async {
    try {
      final list = _persons.values
          .where((p) => p.familyTreeId == familyTreeId)
          .map(_withAvatar)
          .toList();
      list.sort((a, b) => a.displayName.compareTo(b.displayName));
      return list;
    } catch (e, st) {
      Error.throwWithStackTrace(
        StorageException('Không đọc được danh sách thành viên.', e),
        st,
      );
    }
  }

  @override
  Future<Person?> getPerson(String id) async {
    try {
      final p = _persons.get(id);
      return p == null ? null : _withAvatar(p);
    } catch (e, st) {
      Error.throwWithStackTrace(
        StorageException('Không đọc được thành viên.', e),
        st,
      );
    }
  }

  @override
  Future<void> upsertPerson(Person person) async {
    try {
      final previousPath = _avatarPaths.get(person.id) as String?;
      final incoming = person.avatarLocalPath;
      if (previousPath != null && previousPath.isNotEmpty) {
        if (incoming == null || incoming.isEmpty) {
          await AvatarStorage.deleteFileIfExists(previousPath);
        } else if (incoming != previousPath) {
          await AvatarStorage.deleteFileIfExists(previousPath);
        }
      }
      final stored = person.copyWith(avatarLocalPath: null);
      await _persons.put(person.id, stored);
      if (incoming != null && incoming.isNotEmpty) {
        await _avatarPaths.put(person.id, incoming);
      } else {
        await _avatarPaths.delete(person.id);
      }
    } catch (e, st) {
      Error.throwWithStackTrace(
        StorageException('Không lưu được thành viên.', e),
        st,
      );
    }
  }

  @override
  Future<void> deletePerson(String id) async {
    try {
      await _deleteEventsForPerson(id);
      await _deleteRelationshipsForPerson(id);
      await _purgeAvatarForPerson(id);
      await _persons.delete(id);
    } catch (e, st) {
      Error.throwWithStackTrace(
        StorageException('Không xóa được thành viên.', e),
        st,
      );
    }
  }

  Future<void> _deleteEventsForPerson(String personId) async {
    final keys = <dynamic>[];
    for (final key in _events.keys) {
      final e = _events.get(key);
      if (e != null && e.personId == personId) {
        keys.add(key);
      }
    }
    await _events.deleteAll(keys);
  }

  Future<void> _deleteRelationshipsForPerson(String personId) async {
    final keys = <dynamic>[];
    for (final key in _relationships.keys) {
      final r = _relationships.get(key);
      if (r != null &&
          (r.fromPersonId == personId || r.toPersonId == personId)) {
        keys.add(key);
      }
    }
    await _relationships.deleteAll(keys);
  }

  @override
  Future<List<Relationship>> listRelationships(String familyTreeId) async {
    try {
      final list = _relationships.values
          .where((r) => r.familyTreeId == familyTreeId)
          .toList();
      list.sort((a, b) => a.id.compareTo(b.id));
      return list;
    } catch (e, st) {
      Error.throwWithStackTrace(
        StorageException('Không đọc được danh sách quan hệ.', e),
        st,
      );
    }
  }

  @override
  Future<Relationship?> getRelationship(String id) async {
    try {
      return _relationships.get(id);
    } catch (e, st) {
      Error.throwWithStackTrace(
        StorageException('Không đọc được quan hệ.', e),
        st,
      );
    }
  }

  @override
  Future<void> upsertRelationship(Relationship relationship) async {
    try {
      await _relationships.put(relationship.id, relationship);
    } catch (e, st) {
      Error.throwWithStackTrace(
        StorageException('Không lưu được quan hệ.', e),
        st,
      );
    }
  }

  @override
  Future<void> deleteRelationship(String id) async {
    try {
      await _relationships.delete(id);
    } catch (e, st) {
      Error.throwWithStackTrace(
        StorageException('Không xóa được quan hệ.', e),
        st,
      );
    }
  }

  @override
  Future<List<FamilyEvent>> listEvents(String familyTreeId) async {
    try {
      final list = _events.values
          .where((e) => e.familyTreeId == familyTreeId)
          .toList();
      list.sort((a, b) {
        final cmp = _dateOrdinal(a.eventDate).compareTo(_dateOrdinal(b.eventDate));
        if (cmp != 0) return cmp;
        return a.id.compareTo(b.id);
      });
      return list;
    } catch (e, st) {
      Error.throwWithStackTrace(
        StorageException('Không đọc được danh sách sự kiện.', e),
        st,
      );
    }
  }

  @override
  Future<List<FamilyEvent>> listUpcomingEvents(
    String familyTreeId, {
    int withinDays = 30,
  }) async {
    try {
      final all = await listEvents(familyTreeId);
      final now = DateTime.now();
      final todayOrd = _dateOrdinal(now);
      final end = now.add(Duration(days: withinDays));
      final endOrd = _dateOrdinal(end);
      return all
          .where((e) {
            final o = _dateOrdinal(e.eventDate);
            return o >= todayOrd && o <= endOrd;
          })
          .toList();
    } catch (e, st) {
      Error.throwWithStackTrace(
        StorageException('Không đọc được sự kiện sắp tới.', e),
        st,
      );
    }
  }

  @override
  Future<FamilyEvent?> getEvent(String id) async {
    try {
      return _events.get(id);
    } catch (e, st) {
      Error.throwWithStackTrace(
        StorageException('Không đọc được sự kiện.', e),
        st,
      );
    }
  }

  @override
  Future<void> upsertEvent(FamilyEvent event) async {
    try {
      await _events.put(event.id, event);
    } catch (e, st) {
      Error.throwWithStackTrace(
        StorageException('Không lưu được sự kiện.', e),
        st,
      );
    }
  }

  @override
  Future<void> deleteEvent(String id) async {
    try {
      await _events.delete(id);
    } catch (e, st) {
      Error.throwWithStackTrace(
        StorageException('Không xóa được sự kiện.', e),
        st,
      );
    }
  }
}
