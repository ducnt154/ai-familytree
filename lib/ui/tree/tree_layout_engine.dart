import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import '../../data/models/person.dart';
import '../../data/models/relationship.dart';
import '../../data/models/relationship_kind.dart';

/// Bố cục cây top-down từ quan hệ [RelationshipKind.parentChild].
class TreeLayoutEngine {
  TreeLayoutEngine._();

  static const double nodeWidth = 128;
  static const double nodeHeight = 86;
  static const double vGap = 72;
  static const double hGap = 20;
  static const double forestGap = 48;
  static const double padding = 32;

  static TreeLayoutResult compute({
    required List<Person> persons,
    required List<Relationship> relationships,
  }) {
    if (persons.isEmpty) {
      return TreeLayoutResult(
        nodeRects: {},
        edges: const [],
        canvasSize: const Size(320, 200),
      );
    }

    final byId = {for (final p in persons) p.id: p};
    final children = <String, List<String>>{};
    final indegree = <String, int>{for (final p in persons) p.id: 0};

    for (final r in relationships) {
      if (r.kind != RelationshipKind.parentChild) continue;
      if (!byId.containsKey(r.fromPersonId) ||
          !byId.containsKey(r.toPersonId)) {
        continue;
      }
      children.putIfAbsent(r.fromPersonId, () => []).add(r.toPersonId);
      indegree[r.toPersonId] = (indegree[r.toPersonId] ?? 0) + 1;
    }

    for (final list in children.values) {
      list.sort();
    }

    var roots = persons
        .map((p) => p.id)
        .where((id) => (indegree[id] ?? 0) == 0)
        .toList()
      ..sort();

    if (roots.isEmpty) {
      roots = persons.map((p) => p.id).toList()..sort();
    }

    final generation = <String, int>{for (final p in persons) p.id: 0};
    final queue = <String>[...roots];
    var head = 0;
    while (head < queue.length) {
      final id = queue[head++];
      final g = generation[id] ?? 0;
      for (final child in children[id] ?? const <String>[]) {
        final nextGen = g + 1;
        final prev = generation[child] ?? 0;
        if (nextGen > prev) {
          generation[child] = nextGen;
        }
        indegree[child] = (indegree[child] ?? 1) - 1;
        if ((indegree[child] ?? 0) == 0) {
          queue.add(child);
        }
      }
    }

    final remaining = persons
        .map((p) => p.id)
        .where((id) => (indegree[id] ?? 0) > 0)
        .toList()
      ..sort();
    if (remaining.isNotEmpty) {
      for (final id in remaining) {
        generation[id] = 0;
      }
    }

    final rows = <int, List<String>>{};
    for (final id in byId.keys) {
      rows.putIfAbsent(generation[id] ?? 0, () => []).add(id);
    }
    for (final row in rows.values) {
      row.sort();
    }

    final sortedGenerations = rows.keys.toList()..sort();
    var maxRowWidth = nodeWidth;
    for (final g in sortedGenerations) {
      final count = rows[g]!.length;
      final rowW = count * nodeWidth + math.max(0, count - 1) * hGap;
      maxRowWidth = math.max(maxRowWidth, rowW);
    }

    final centers = <String, Offset>{};
    for (final g in sortedGenerations) {
      final ids = rows[g]!;
      final rowW = ids.length * nodeWidth + math.max(0, ids.length - 1) * hGap;
      final startX = (maxRowWidth - rowW) / 2 + nodeWidth / 2;
      final y = nodeHeight / 2 + g * (nodeHeight + vGap);
      for (var i = 0; i < ids.length; i++) {
        final x = startX + i * (nodeWidth + hGap);
        centers[ids[i]] = Offset(x, y);
      }
    }

    final totalHeight = sortedGenerations.length * nodeHeight +
        math.max(0, sortedGenerations.length - 1) * vGap;
    return _normalize(
      _LayoutBox(width: maxRowWidth, height: totalHeight, centers: centers),
      relationships,
    );
  }

  static TreeLayoutResult _normalize(
    _LayoutBox box,
    List<Relationship> relationships,
  ) {
    if (box.centers.isEmpty) {
      return TreeLayoutResult(
        nodeRects: {},
        edges: const [],
        canvasSize: Size(
          TreeLayoutEngine.padding * 2 + 200,
          TreeLayoutEngine.padding * 2 + 120,
        ),
      );
    }

    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    for (final o in box.centers.values) {
      minX = math.min(minX, o.dx - nodeWidth / 2);
      minY = math.min(minY, o.dy - nodeHeight / 2);
      maxX = math.max(maxX, o.dx + nodeWidth / 2);
      maxY = math.max(maxY, o.dy + nodeHeight / 2);
    }

    final shiftX = padding - minX;
    final shiftY = padding - minY;

    final rects = <String, Rect>{};
    final centersShifted = <String, Offset>{};
    for (final e in box.centers.entries) {
      final c = Offset(e.value.dx + shiftX, e.value.dy + shiftY);
      centersShifted[e.key] = c;
      rects[e.key] = Rect.fromCenter(
        center: c,
        width: nodeWidth,
        height: nodeHeight,
      );
    }

    final edges = _buildEdges(relationships, centersShifted);

    return TreeLayoutResult(
      nodeRects: rects,
      edges: edges,
      canvasSize: Size(
        maxX - minX + padding * 2,
        maxY - minY + padding * 2,
      ),
    );
  }

  static List<TreeEdge> _buildEdges(
    List<Relationship> relationships,
    Map<String, Offset> centers,
  ) {
    final list = <TreeEdge>[];
    for (final r in relationships) {
      if (r.kind != RelationshipKind.parentChild) continue;
      final a = centers[r.fromPersonId];
      final b = centers[r.toPersonId];
      if (a == null || b == null) continue;
      list.add(TreeEdge(fromId: r.fromPersonId, toId: r.toPersonId));
    }
    return list;
  }
}

class _LayoutBox {
  _LayoutBox({
    required this.width,
    required this.height,
    required this.centers,
  });
  final double width;
  final double height;
  final Map<String, Offset> centers;
}

class TreeEdge {
  const TreeEdge({required this.fromId, required this.toId});
  final String fromId;
  final String toId;
}

class TreeLayoutResult {
  TreeLayoutResult({
    required this.nodeRects,
    required this.edges,
    required this.canvasSize,
  });

  final Map<String, Rect> nodeRects;
  final List<TreeEdge> edges;
  final Size canvasSize;
}
