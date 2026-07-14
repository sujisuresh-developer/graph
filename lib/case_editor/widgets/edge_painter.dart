import 'package:flutter/material.dart';
import '../models/flow_models.dart';

/// Ephemeral state for an in-progress connection drag (from a node's output
/// handle to wherever the pointer currently is). Not part of the committed
/// graph - purely a rendering hint for the live preview line.
class PendingEdge {
  final String sourceId;
  final Offset currentPosition;
  const PendingEdge({required this.sourceId, required this.currentPosition});
}

/// Renders every committed edge as an animated dashed bezier curve with an
/// arrowhead, plus (optionally) one pending edge being dragged live.
/// Wrapped by [AnimatedFlowEdges] which supplies the looping dash-phase.
class FlowEdgePainter extends CustomPainter {
  final Map<String, FlowNode> nodeLookup;
  final List<FlowEdge> edges;
  final String? selectedEdgeId;
  final double dashPhase; // 0..1, animates to create the "flowing" effect
  final PendingEdge? pendingEdge;

  FlowEdgePainter({
    required this.nodeLookup,
    required this.edges,
    required this.dashPhase,
    this.selectedEdgeId,
    this.pendingEdge,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      final source = nodeLookup[edge.sourceId];
      final target = nodeLookup[edge.targetId];
      // Safety check mirrored from the controller: an edge may briefly
      // reference a node that was just deleted (e.g. mid-frame during a
      // batched update) - skip rendering it instead of crashing.
      if (source == null || target == null) continue;

      final isSelected = edge.id == selectedEdgeId;
      _drawEdge(
        canvas,
        start: Offset(source.position.dx + kNodeWidth / 2, source.position.dy + kNodeHeight),
        end: Offset(target.position.dx + kNodeWidth / 2, target.position.dy),
        color: isSelected ? const Color(0xFF2F6BFF) : const Color(0xFFB9B4C7),
        strokeWidth: isSelected ? 3 : 2.2,
      );
    }

    if (pendingEdge != null) {
      final source = nodeLookup[pendingEdge!.sourceId];
      if (source != null) {
        _drawEdge(
          canvas,
          start: Offset(source.position.dx + kNodeWidth / 2, source.position.dy + kNodeHeight),
          end: pendingEdge!.currentPosition,
          color: const Color(0xFF9A9AA8),
          strokeWidth: 2,
          arrow: false,
        );
      }
    }
  }

  void _drawEdge(
    Canvas canvas, {
    required Offset start,
    required Offset end,
    required Color color,
    required double strokeWidth,
    bool arrow = true,
  }) {
    final dy = (end.dy - start.dy).abs().clamp(40, 160);
    final control1 = Offset(start.dx, start.dy + dy / 2);
    final control2 = Offset(end.dx, end.dy - dy / 2);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(control1.dx, control1.dy, control2.dx, control2.dy, end.dx, end.dy);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    _drawDashedPath(canvas, path, paint, dashPhase);

    if (arrow) {
      _drawArrowHead(canvas, path, color);
    }
  }

  /// Draws [path] as a dash-dot pattern whose start offset is animated by
  /// [phase] (0..1), producing the "flowing" look of professional workflow
  /// editors without needing a shader or a third-party package.
  void _drawDashedPath(Canvas canvas, Path path, Paint paint, double phase) {
    const dashLength = 8.0;
    const gapLength = 6.0;
    const cycle = dashLength + gapLength;

    for (final metric in path.computeMetrics()) {
      final total = metric.length;
      double distance = -(phase * cycle);
      while (distance < total) {
        final segStart = distance.clamp(0.0, total);
        final segEnd = (distance + dashLength).clamp(0.0, total);
        if (segEnd > segStart) {
          canvas.drawPath(metric.extractPath(segStart, segEnd), paint);
        }
        distance += cycle;
      }
    }
  }

  void _drawArrowHead(Canvas canvas, Path path, Color color) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.last;
    final tangent = metric.getTangentForOffset(metric.length);
    if (tangent == null) return;

    const arrowSize = 9.0;
    final dir = tangent.vector;
    final tip = tangent.position;
    final base = tip - dir * arrowSize;
    final normal = Offset(-dir.dy, dir.dx);

    final arrowPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + normal.dx * arrowSize * 0.5, base.dy + normal.dy * arrowSize * 0.5)
      ..lineTo(base.dx - normal.dx * arrowSize * 0.5, base.dy - normal.dy * arrowSize * 0.5)
      ..close();

    canvas.drawPath(arrowPath, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant FlowEdgePainter oldDelegate) => true;
}

/// Looping [AnimationController] wrapper that drives [FlowEdgePainter]'s
/// dash-phase so every edge appears to flow continuously, similar to
/// React Flow / Node-RED's animated edges.
class AnimatedFlowEdges extends StatefulWidget {
  final Map<String, FlowNode> nodeLookup;
  final List<FlowEdge> edges;
  final String? selectedEdgeId;
  final PendingEdge? pendingEdge;
  final Size canvasSize;

  const AnimatedFlowEdges({
    super.key,
    required this.nodeLookup,
    required this.edges,
    required this.canvasSize,
    this.selectedEdgeId,
    this.pendingEdge,
  });

  @override
  State<AnimatedFlowEdges> createState() => _AnimatedFlowEdgesState();
}

class _AnimatedFlowEdgesState extends State<AnimatedFlowEdges> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: widget.canvasSize,
            painter: FlowEdgePainter(
              nodeLookup: widget.nodeLookup,
              edges: widget.edges,
              dashPhase: _controller.value,
              selectedEdgeId: widget.selectedEdgeId,
              pendingEdge: widget.pendingEdge,
            ),
          );
        },
      ),
    );
  }
}

/// Faint dot-grid background so users can visually judge grid-snap
/// alignment while dragging nodes.
class GridBackgroundPainter extends CustomPainter {
  const GridBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFE4E1DB);
    for (double x = 0; x < size.width; x += kGridSize) {
      for (double y = 0; y < size.height; y += kGridSize) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
