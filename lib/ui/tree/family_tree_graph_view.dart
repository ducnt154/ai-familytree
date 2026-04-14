import 'dart:io' show File;
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/person.dart';
import '../../providers/family_tree_controller.dart';
import '../../services/map_navigation.dart';
import '../maps/person_address_map_page.dart';
import 'tree_layout_engine.dart';

/// Trang cây: zoom/pan ([InteractiveViewer]), layout top-down, chạm nút → bottom sheet chi tiết.
class FamilyTreeGraphView extends StatefulWidget {
  const FamilyTreeGraphView({super.key});

  @override
  State<FamilyTreeGraphView> createState() => _FamilyTreeGraphViewState();

  static void _openDetail(BuildContext context, Person person) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => PersonDetailSheet(person: person),
    );
  }
}

class _FamilyTreeGraphViewState extends State<FamilyTreeGraphView> {
  final TransformationController _transform = TransformationController();

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _zoomBy(double factor) {
    final m = _transform.value.clone();
    final current = m.getMaxScaleOnAxis();
    final next = (current * factor).clamp(0.35, 3.5);
    final ratio = next / current;
    _transform.value = m..scale(ratio);
  }

  void _fitToScreen(Size canvasSize, Size viewportSize) {
    final vpW = viewportSize.width.isFinite && viewportSize.width > 0
        ? viewportSize.width
        : canvasSize.width;
    final vpH = viewportSize.height.isFinite && viewportSize.height > 0
        ? viewportSize.height
        : canvasSize.height;
    final scaleX = vpW / canvasSize.width;
    final scaleY = vpH / canvasSize.height;
    final scale = math.min(3.5, math.max(0.35, math.min(scaleX, scaleY)));
    final dx = (vpW - canvasSize.width * scale) / 2;
    final dy = (vpH - canvasSize.height * scale) / 2;
    _transform.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyTreeController>(
      builder: (context, ctrl, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFFDF6F1),
          body: _GraphTab(
            transform: _transform,
            onZoomIn: () => _zoomBy(1.15),
            onZoomOut: () => _zoomBy(1 / 1.15),
            onFitScreen: _fitToScreen,
          ),
        );
      },
    );
  }
}

class _GraphTab extends StatelessWidget {
  const _GraphTab({
    required this.transform,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitScreen,
  });

  final TransformationController transform;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final void Function(Size canvasSize, Size viewportSize) onFitScreen;

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyTreeController>(
      builder: (context, ctrl, _) {
        if (ctrl.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (ctrl.activeTreeId == null) {
          return Center(
            child: Text(
              'Chưa có cây gia phả — tạo cây ở tab Home.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          );
        }
        if (ctrl.persons.isEmpty) {
          return Center(
            child: Text(
              'Chưa có thành viên — thêm từ tab Add khi sẵn sàng.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          );
        }

        final layout = TreeLayoutEngine.compute(
          persons: ctrl.persons,
          relationships: ctrl.relationships,
        );

        final byId = {for (final p in ctrl.persons) p.id: p};

        return Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final maxW = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : layout.canvasSize.width;
                final maxH = constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : layout.canvasSize.height;
                return InteractiveViewer(
                  transformationController: transform,
                  minScale: 0.35,
                  maxScale: 3.5,
                  boundaryMargin: const EdgeInsets.all(160),
                  constrained: false,
                  child: SizedBox(
                    width: math.max(layout.canvasSize.width, maxW),
                    height: math.max(layout.canvasSize.height, maxH),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CustomPaint(
                          size: layout.canvasSize,
                          painter: _TreeEdgesPainter(
                            layout: layout,
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.55),
                          ),
                        ),
                        ...layout.nodeRects.entries.map((e) {
                          final person = byId[e.key];
                          if (person == null) return const SizedBox.shrink();
                          return Positioned(
                            left: e.value.left,
                            top: e.value.top,
                            width: e.value.width,
                            height: e.value.height,
                            child: _PersonNodeChip(
                              person: person,
                              onTap: () => FamilyTreeGraphView._openDetail(
                                  context, person),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
            Positioned(
              left: 14,
              bottom: 24,
              child: _LeftZoomControls(
                onZoomIn: onZoomIn,
                onZoomOut: onZoomOut,
                onFitScreen: () =>
                    onFitScreen(layout.canvasSize, MediaQuery.sizeOf(context)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LeftZoomControls extends StatelessWidget {
  const _LeftZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitScreen,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitScreen;

  @override
  Widget build(BuildContext context) {
    Widget btn({
      required IconData icon,
      required VoidCallback onPressed,
    }) {
      return Material(
        color: Colors.white,
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: IconButton(
          icon: Icon(icon, color: Colors.black87),
          onPressed: onPressed,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(icon: Icons.add, onPressed: onZoomIn),
        const SizedBox(height: 10),
        btn(icon: Icons.remove, onPressed: onZoomOut),
        const SizedBox(height: 10),
        btn(icon: Icons.fit_screen, onPressed: onFitScreen),
      ],
    );
  }
}

class _TreeEdgesPainter extends CustomPainter {
  _TreeEdgesPainter({
    required this.layout,
    required this.color,
  });

  final TreeLayoutResult layout;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centers = <String, Offset>{};
    for (final e in layout.nodeRects.entries) {
      final r = e.value;
      centers[e.key] = Offset(r.center.dx, r.center.dy);
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    for (final edge in layout.edges) {
      final a = centers[edge.fromId];
      final b = centers[edge.toId];
      if (a == null || b == null) continue;
      final from = Offset(a.dx, a.dy + TreeLayoutEngine.nodeHeight / 2);
      final to = Offset(b.dx, b.dy - TreeLayoutEngine.nodeHeight / 2);
      final midY = (from.dy + to.dy) / 2;
      final p = Path()
        ..moveTo(from.dx, from.dy)
        ..lineTo(from.dx, midY)
        ..lineTo(to.dx, midY)
        ..lineTo(to.dx, to.dy);
      canvas.drawPath(p, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TreeEdgesPainter oldDelegate) {
    return oldDelegate.layout.canvasSize != layout.canvasSize ||
        oldDelegate.layout.edges.length != layout.edges.length ||
        oldDelegate.color != color;
  }
}

class _PersonNodeChip extends StatelessWidget {
  const _PersonNodeChip({
    required this.person,
    required this.onTap,
  });

  final Person person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AvatarCircle(person: person),
              const SizedBox(height: 8),
              Text(
                person.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onSurface,
                      height: 1.1,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.person});
  final Person person;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasFile = !kIsWeb &&
        person.avatarLocalPath != null &&
        File(person.avatarLocalPath!).existsSync();
    if (hasFile) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: FileImage(File(person.avatarLocalPath!)),
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: scheme.primary.withValues(alpha: 0.12),
      foregroundColor: scheme.primary,
      child: const Icon(Icons.person, size: 18),
    );
  }
}

/// Khung chi tiết thành viên (scaffold trong bottom sheet).
class PersonDetailSheet extends StatelessWidget {
  const PersonDetailSheet({super.key, required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.paddingOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!kIsWeb &&
              person.avatarLocalPath != null &&
              File(person.avatarLocalPath!).existsSync())
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(person.avatarLocalPath!),
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          Text(
            person.displayName,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.badge_outlined,
            label: 'ID',
            value: person.id,
          ),
          if (person.birthDate != null)
            _DetailRow(
              icon: Icons.cake_outlined,
              label: 'Sinh',
              value: _formatDate(person.birthDate!),
            ),
          if (person.deathDate != null)
            _DetailRow(
              icon: Icons.close,
              label: 'Mất',
              value: _formatDate(person.deathDate!),
            ),
          if (person.notes != null && person.notes!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                person.notes!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          if (person.address != null && person.address!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.place_outlined,
              label: 'Địa chỉ',
              value: person.address!.trim(),
            ),
            const SizedBox(height: 12),
            _MapsActionsRow(person: person),
          ],
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}

bool get _canEmbedGoogleMap =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

class _MapsActionsRow extends StatelessWidget {
  const _MapsActionsRow({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    final addr = person.address!.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () async {
            final ok = await openGoogleMapsExternal(addr);
            if (!context.mounted) return;
            if (!ok) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Không mở được liên kết bản đồ.')),
              );
            }
          },
          icon: const Icon(Icons.map_outlined),
          label: const Text('Mở Google Maps'),
        ),
        if (_canEmbedGoogleMap) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PersonAddressMapPage(
                    title: person.displayName,
                    address: addr,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.map),
            label: const Text('Xem bản đồ trong app'),
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                SelectableText(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
