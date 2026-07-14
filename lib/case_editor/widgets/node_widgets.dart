import 'package:flutter/material.dart';
import '../models/flow_models.dart';

/// Shared visual shell for both node types - keeps the two node widgets
/// consistent (size, selection ring, shadow) while letting each customize
/// its accent color and content.
class NodeCard extends StatelessWidget {
  final bool selected;
  final Color accentColor;
  final Widget child;

  const NodeCard({
    super.key,
    required this.selected,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kNodeWidth,
      height: kNodeHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? accentColor : const Color(0xFFE3E1DC),
          width: selected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(selected ? 0.14 : 0.06),
            blurRadius: selected ? 16 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: double.infinity,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                bottomLeft: Radius.circular(13),
              ),
            ),
          ),
          Expanded(child: Padding(padding: const EdgeInsets.all(10), child: child)),
        ],
      ),
    );
  }
}

/// Small circular handle used to start a connection drag. Rendered as a
/// separate, non-overlapping hit area from the node body so the gesture
/// arena never has to arbitrate between "move node" and "start connection".
class ConnectorHandle extends StatelessWidget {
  final Color color;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;

  const ConnectorHandle({
    super.key,
    required this.color,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: MouseRegion(
        cursor: SystemMouseCursors.precise,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)],
          ),
        ),
      ),
    );
  }
}

typedef NodeGestureCallback = void Function(String nodeId);
typedef NodeConnectStartCallback = void Function(String nodeId, Offset contentPosition);
typedef NodeConnectUpdateCallback = void Function(Offset contentPosition);
typedef NodeConnectEndCallback = void Function(Offset contentPosition);

class StateNodeWidget extends StatelessWidget {
  final StateNode node;
  final bool selected;
  final NodeGestureCallback onTap;
  final void Function(String id, Offset contentPosition, Offset grabOffset) onDragStart;
  final void Function(String id, Offset contentPosition, Offset grabOffset) onDragUpdate;
  final NodeGestureCallback onDragEnd;
  final Offset Function(Offset global) toContentPosition;
  final NodeConnectStartCallback onConnectStart;
  final NodeConnectUpdateCallback onConnectUpdate;
  final NodeConnectEndCallback onConnectEnd;

  const StateNodeWidget({
    super.key,
    required this.node,
    required this.selected,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.toContentPosition,
    required this.onConnectStart,
    required this.onConnectUpdate,
    required this.onConnectEnd,
  });

  static const Color accent = Color(0xFF2F6BFF);

  @override
  Widget build(BuildContext context) {
    Offset grabOffset = Offset.zero;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => onTap(node.id),
          onPanStart: (d) {
            final contentPos = toContentPosition(d.globalPosition);
            grabOffset = contentPos - node.position;
            onDragStart(node.id, contentPos, grabOffset);
          },
          onPanUpdate: (d) {
            final contentPos = toContentPosition(d.globalPosition);
            onDragUpdate(node.id, contentPos, grabOffset);
          },
          onPanEnd: (_) => onDragEnd(node.id),
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: NodeCard(
              selected: selected,
              accentColor: accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(node.icon, size: 18, color: accent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          node.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E1E2D)),
                        ),
                      ),
                      if (node.isTerminal)
                        const Icon(Icons.stop_circle_outlined, size: 15, color: Color(0xFF9A9AA8)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.category_outlined, size: 12, color: Color(0xFF9A9AA8)),
                      const SizedBox(width: 4),
                      const Text('State', style: TextStyle(fontSize: 10, color: Color(0xFF9A9AA8))),
                      const Spacer(),
                      if (node.timerSeconds != null) ...[
                        const Icon(Icons.timer_outlined, size: 12, color: Color(0xFF9A9AA8)),
                        const SizedBox(width: 3),
                        Text('${node.timerSeconds}s', style: const TextStyle(fontSize: 10, color: Color(0xFF9A9AA8))),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Output connector - bottom-center, slightly overflowing the card.
        Positioned(
          bottom: -8,
          left: kNodeWidth / 2 - 8,
          child: ConnectorHandle(
            color: accent,
            onPanStart: (d) => onConnectStart(node.id, toContentPosition(d.globalPosition)),
            onPanUpdate: (d) => onConnectUpdate(toContentPosition(d.globalPosition)),
            onPanEnd: (d) => onConnectEnd(toContentPosition(d.globalPosition)),
          ),
        ),
      ],
    );
  }
}

class ActionNodeWidget extends StatelessWidget {
  final ActionNode node;
  final bool selected;
  final NodeGestureCallback onTap;
  final void Function(String id, Offset contentPosition, Offset grabOffset) onDragStart;
  final void Function(String id, Offset contentPosition, Offset grabOffset) onDragUpdate;
  final NodeGestureCallback onDragEnd;
  final Offset Function(Offset global) toContentPosition;
  final NodeConnectStartCallback onConnectStart;
  final NodeConnectUpdateCallback onConnectUpdate;
  final NodeConnectEndCallback onConnectEnd;

  const ActionNodeWidget({
    super.key,
    required this.node,
    required this.selected,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.toContentPosition,
    required this.onConnectStart,
    required this.onConnectUpdate,
    required this.onConnectEnd,
  });

  static const Color accent = Color(0xFF8B6BF0);

  @override
  Widget build(BuildContext context) {
    late Offset grabOffset;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => onTap(node.id),
          onPanStart: (d) {
            final contentPos = toContentPosition(d.globalPosition);
            grabOffset = contentPos - node.position;
            onDragStart(node.id, contentPos, grabOffset);
          },
          onPanUpdate: (d) {
            final contentPos = toContentPosition(d.globalPosition);
            onDragUpdate(node.id, contentPos, grabOffset);
          },
          onPanEnd: (_) => onDragEnd(node.id),
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: NodeCard(
              selected: selected,
              accentColor: accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(node.icon, size: 18, color: accent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          node.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E1E2D)),
                        ),
                      ),
                      if (node.isCritical)
                        const Icon(Icons.priority_high_rounded, size: 15, color: Color(0xFFE5484D)),
                    ],
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          node.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: Color(0xFF9A9AA8)),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.timer_outlined, size: 12, color: Color(0xFF9A9AA8)),
                      const SizedBox(width: 3),
                      Text('${node.timeCostSeconds}s', style: const TextStyle(fontSize: 10, color: Color(0xFF9A9AA8))),
                      const SizedBox(width: 6),
                      Icon(
                        node.scoreImpact >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        size: 12,
                        color: node.scoreImpact >= 0 ? const Color(0xFF34C759) : const Color(0xFFE5484D),
                      ),
                      Text(
                        '${node.scoreImpact}',
                        style: TextStyle(
                          fontSize: 10,
                          color: node.scoreImpact >= 0 ? const Color(0xFF34C759) : const Color(0xFFE5484D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Input connector - top-center. Dropping an edge here (from a State's
        // output handle) is also allowed since drop detection uses the whole
        // node rect, but the visual dot communicates directionality.
        Positioned(
          top: -8,
          left: kNodeWidth / 2 - 8,
          child: IgnorePointer(
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: accent, width: 2.5),
              ),
            ),
          ),
        ),
        // Output connector - bottom-center, for Action -> State connections.
        Positioned(
          bottom: -8,
          left: kNodeWidth / 2 - 8,
          child: ConnectorHandle(
            color: accent,
            onPanStart: (d) => onConnectStart(node.id, toContentPosition(d.globalPosition)),
            onPanUpdate: (d) => onConnectUpdate(toContentPosition(d.globalPosition)),
            onPanEnd: (d) => onConnectEnd(toContentPosition(d.globalPosition)),
          ),
        ),
      ],
    );
  }
}
