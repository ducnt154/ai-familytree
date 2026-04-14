import '../models/family_tree_record.dart';
import '../models/person.dart';
import '../models/relationship.dart';

/// Trừu tượng CRUD cây gia phả, thành viên và quan hệ (offline-first).
abstract class FamilyTreeRepository {
  Future<List<FamilyTreeRecord>> listTrees();

  Future<FamilyTreeRecord?> getTree(String id);

  Future<void> upsertTree(FamilyTreeRecord record);

  Future<void> deleteTree(String id);

  Future<List<Person>> listPersons(String familyTreeId);

  Future<Person?> getPerson(String id);

  Future<void> upsertPerson(Person person);

  Future<void> deletePerson(String id);

  Future<List<Relationship>> listRelationships(String familyTreeId);

  Future<Relationship?> getRelationship(String id);

  Future<void> upsertRelationship(Relationship relationship);

  Future<void> deleteRelationship(String id);
}
