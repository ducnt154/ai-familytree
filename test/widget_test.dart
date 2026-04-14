import 'dart:io';

import 'package:familytree/data/hive/family_tree_hive.dart';
import 'package:familytree/data/repository/hive_family_tree_repository.dart';
import 'package:familytree/providers/family_tree_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke: MaterialApp', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: Text('ok'))));
    expect(find.text('ok'), findsOneWidget);
  });

  test('FamilyTreeController bootstrap (Hive + repo)', () async {
    await FamilyTreeHive.resetForTesting();
    final dir = Directory.systemTemp.createTempSync('familytree_ctrl_test_');
    await FamilyTreeHive.init(hivePath: dir.path);
    final repo = HiveFamilyTreeRepository(FamilyTreeHive.instance);
    final c = FamilyTreeController(repo);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(c.loading, isFalse);
  });
}
