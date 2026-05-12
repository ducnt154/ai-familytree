import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/models/family_event.dart';
import '../data/models/family_event_kind.dart';
import '../data/models/family_tree_record.dart';
import '../data/models/gender.dart';
import '../data/models/person.dart';
import '../data/models/relationship.dart';
import '../data/models/relationship_kind.dart';
import '../data/repository/family_tree_repository.dart';
import '../data/errors/storage_exception.dart';
import '../services/avatar_storage.dart';

/// Trạng thái app-level: cây đang chọn, thành viên & quan hệ, lỗi offline.
class FamilyTreeController extends ChangeNotifier {
  FamilyTreeController(this._repo) {
    _bootstrap();
  }

  final FamilyTreeRepository _repo;
  static const _uuid = Uuid();

  List<FamilyTreeRecord> _familyTrees = [];
  String? _activeTreeId;
  List<Person> _persons = [];
  List<Relationship> _relationships = [];
  List<FamilyEvent> _events = [];
  String? _lastError;
  bool _loading = true;

  List<FamilyTreeRecord> get familyTrees => List.unmodifiable(_familyTrees);
  String? get activeTreeId => _activeTreeId;
  FamilyTreeRecord? get activeTree {
    if (_activeTreeId == null) return null;
    try {
      return _familyTrees.firstWhere((t) => t.id == _activeTreeId);
    } catch (_) {
      return null;
    }
  }

  List<Person> get persons => List.unmodifiable(_persons);
  List<Relationship> get relationships => List.unmodifiable(_relationships);
  List<FamilyEvent> get events => List.unmodifiable(_events);
  String? get lastError => _lastError;
  bool get loading => _loading;

  Future<void> _bootstrap() async {
    await refreshTrees();
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  Future<void> refreshTrees() async {
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      _familyTrees = await _repo.listTrees();
      if (_activeTreeId != null &&
          !_familyTrees.any((t) => t.id == _activeTreeId)) {
        _activeTreeId = null;
      }
      _activeTreeId ??= _familyTrees.isNotEmpty ? _familyTrees.first.id : null;
      await _reloadActiveScope();
    } on StorageException catch (e) {
      _lastError = e.message;
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> selectTree(String? treeId) async {
    _activeTreeId = treeId;
    _lastError = null;
    notifyListeners();
    await _reloadActiveScope();
    notifyListeners();
  }

  Future<void> _reloadActiveScope() async {
    final id = _activeTreeId;
    if (id == null) {
      _persons = [];
      _relationships = [];
      _events = [];
      return;
    }
    try {
      _persons = await _repo.listPersons(id);
      _relationships = await _repo.listRelationships(id);
      _events = await _repo.listEvents(id);
    } on StorageException catch (e) {
      _lastError = e.message;
      _persons = [];
      _relationships = [];
      _events = [];
    } catch (e) {
      _lastError = e.toString();
      _persons = [];
      _relationships = [];
      _events = [];
    }
  }

  Future<void> createFamilyTree(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      _lastError = 'Tên cây gia phả không được để trống.';
      notifyListeners();
      return;
    }
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    final record = FamilyTreeRecord(
      id: id,
      name: trimmed,
      createdAt: now,
      updatedAt: now,
    );
    try {
      await _repo.upsertTree(record);
      await refreshTrees();
      await selectTree(id);
    } on StorageException catch (e) {
      _lastError = e.message;
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> addPerson({
    required String displayName,
    Gender? gender,
    DateTime? birthDate,
    DateTime? deathDate,
    String? notes,
    String? address,
    String? pickedAvatarTempPath,
  }) async {
    final treeId = _activeTreeId;
    if (treeId == null) {
      _lastError = 'Chưa có cây gia phả — tạo cây trước khi thêm thành viên.';
      notifyListeners();
      return;
    }
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      _lastError = 'Tên hiển thị không được để trống.';
      notifyListeners();
      return;
    }
    final now = DateTime.now().toUtc();
    final addr = address?.trim();
    final person = Person(
      id: _uuid.v4(),
      familyTreeId: treeId,
      displayName: trimmed,
      gender: gender,
      birthDate: birthDate,
      deathDate: deathDate,
      notes: notes,
      address: addr == null || addr.isEmpty ? null : addr,
      createdAt: now,
      updatedAt: now,
    );
    try {
      await _repo.upsertPerson(person);
      if (pickedAvatarTempPath != null && pickedAvatarTempPath.isNotEmpty) {
        final path = await AvatarStorage.persistPickedFile(
          personId: person.id,
          sourcePath: pickedAvatarTempPath,
        );
        await _repo.upsertPerson(person.copyWith(avatarLocalPath: path));
      }
      await _reloadActiveScope();
      notifyListeners();
    } on StorageException catch (e) {
      _lastError = e.message;
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> updatePerson(
    Person person, {
    String? pickedAvatarTempPath,
    bool removeAvatar = false,
  }) async {
    try {
      var next = person.copyWith(updatedAt: DateTime.now().toUtc());
      if (removeAvatar) {
        next = next.copyWith(clearAvatar: true);
      } else if (pickedAvatarTempPath != null &&
          pickedAvatarTempPath.isNotEmpty) {
        final path = await AvatarStorage.persistPickedFile(
          personId: person.id,
          sourcePath: pickedAvatarTempPath,
        );
        next = next.copyWith(avatarLocalPath: path);
      }
      await _repo.upsertPerson(next);
      await _reloadActiveScope();
      notifyListeners();
    } on StorageException catch (e) {
      _lastError = e.message;
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> removePerson(String personId) async {
    try {
      await _repo.deletePerson(personId);
      await _reloadActiveScope();
      notifyListeners();
    } on StorageException catch (e) {
      _lastError = e.message;
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> addRelationship({
    required String fromPersonId,
    required String toPersonId,
    required RelationshipKind kind,
  }) async {
    final treeId = _activeTreeId;
    if (treeId == null) {
      _lastError = 'Chưa có cây gia phả.';
      notifyListeners();
      return;
    }
    if (fromPersonId == toPersonId) {
      _lastError = 'Hai đầu quan hệ phải là hai người khác nhau.';
      notifyListeners();
      return;
    }
    final now = DateTime.now().toUtc();
    final rel = Relationship(
      id: _uuid.v4(),
      familyTreeId: treeId,
      fromPersonId: fromPersonId,
      toPersonId: toPersonId,
      kind: kind,
      createdAt: now,
      updatedAt: now,
    );
    try {
      await _repo.upsertRelationship(rel);
      await _reloadActiveScope();
      notifyListeners();
    } on StorageException catch (e) {
      _lastError = e.message;
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeRelationship(String relationshipId) async {
    try {
      await _repo.deleteRelationship(relationshipId);
      await _reloadActiveScope();
      notifyListeners();
    } on StorageException catch (e) {
      _lastError = e.message;
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> saveFamilyEvent({
    FamilyEvent? existing,
    required String personId,
    required FamilyEventKind kind,
    String? customTitle,
    required DateTime eventDate,
    bool isLunarDate = false,
    int? lunarYear,
    int? lunarMonth,
    int? lunarDay,
    bool lunarLeapMonth = false,
    bool repeatYearly = false,
    String? notes,
    required bool reminderEnabled,
    int? reminderDays,
  }) async {
    final treeId = _activeTreeId;
    if (treeId == null) {
      _lastError = 'Chưa có cây gia phả.';
      notifyListeners();
      return;
    }
    final now = DateTime.now().toUtc();
    final trimmed = notes?.trim();
    final titleTrim = customTitle?.trim();
    final rd = reminderEnabled ? (reminderDays ?? 1) : null;
    final event = FamilyEvent(
      id: existing?.id ?? _uuid.v4(),
      familyTreeId: treeId,
      personId: personId,
      eventKind: kind,
      customTitle: titleTrim == null || titleTrim.isEmpty ? null : titleTrim,
      eventDate: eventDate,
      isLunarDate: isLunarDate,
      lunarYear: isLunarDate ? lunarYear : null,
      lunarMonth: isLunarDate ? lunarMonth : null,
      lunarDay: isLunarDate ? lunarDay : null,
      lunarLeapMonth: isLunarDate ? lunarLeapMonth : false,
      repeatYearly: repeatYearly,
      notes: trimmed == null || trimmed.isEmpty ? null : trimmed,
      reminderEnabled: reminderEnabled,
      reminderDays: rd,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      await _repo.upsertEvent(event);
      await _reloadActiveScope();
      notifyListeners();
    } on StorageException catch (e) {
      _lastError = e.message;
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeFamilyEvent(String eventId) async {
    try {
      await _repo.deleteEvent(eventId);
      await _reloadActiveScope();
      notifyListeners();
    } on StorageException catch (e) {
      _lastError = e.message;
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteActiveTree() async {
    final id = _activeTreeId;
    if (id == null) return;
    try {
      await _repo.deleteTree(id);
      _activeTreeId = null;
      await refreshTrees();
    } on StorageException catch (e) {
      _lastError = e.message;
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }
}
