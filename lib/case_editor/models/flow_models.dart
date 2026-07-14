import 'dart:math';
import 'package:flutter/material.dart';

/// The two node families the FSM editor supports. Kept as an enum (rather
/// than relying on `is StateNode`) so validation logic (e.g. canConnect)
/// can compare kinds cheaply without runtime type checks.
enum NodeKind { state, action }

/// Fixed node footprint used consistently by node widgets, the edge
/// painter (for anchor points), and hit-testing during connection drags.
const double kNodeWidth = 176;
const double kNodeHeight = 84;
const double kGridSize = 24;

/// Generates a reasonably-unique id without pulling in the `uuid` package.
String generateId(String prefix) {
  final rand = Random();
  return '$prefix-${DateTime.now().microsecondsSinceEpoch}-${rand.nextInt(999999)}';
}

/// Snaps a raw canvas position to the nearest grid intersection.
Offset snapToGrid(Offset raw, {double gridSize = kGridSize}) {
  return Offset(
    (raw.dx / gridSize).round() * gridSize,
    (raw.dy / gridSize).round() * gridSize,
  );
}

/// Base type for anything placeable on the canvas. Deliberately mutable
/// (position/selected) since the controller mutates nodes in place during
/// high-frequency drag updates - cloning happens only at snapshot time for
/// undo/redo, not on every frame.
abstract class FlowNode {
  final String id;
  final NodeKind kind;
  Offset position;
  bool selected;

  FlowNode({
    required this.id,
    required this.kind,
    required this.position,
    this.selected = false,
  });

  /// Deep copy used when the controller captures an undo/redo snapshot.
  FlowNode clone();

  Map<String, dynamic> toJson();

  Rect get rect => Rect.fromLTWH(position.dx, position.dy, kNodeWidth, kNodeHeight);
}

class StateNode extends FlowNode {
  String name;
  IconData icon;
  int? timerSeconds;
  bool isTerminal;

  StateNode({
    required String id,
    required Offset position,
    required this.name,
    required this.icon,
    this.timerSeconds,
    this.isTerminal = false,
    bool selected = false,
  }) : super(id: id, kind: NodeKind.state, position: position, selected: selected);

  @override
  StateNode clone() => StateNode(
        id: id,
        position: position,
        name: name,
        icon: icon,
        timerSeconds: timerSeconds,
        isTerminal: isTerminal,
        selected: selected,
      );

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': 'state',
        'x': position.dx,
        'y': position.dy,
        'name': name,
        'iconCodePoint': icon.codePoint,
        'timerSeconds': timerSeconds,
        'isTerminal': isTerminal,
      };
}

class ActionNode extends FlowNode {
  String name;
  String category;
  IconData icon;
  int timeCostSeconds;
  int scoreImpact;
  bool isCritical;

  ActionNode({
    required String id,
    required Offset position,
    required this.name,
    required this.category,
    required this.icon,
    required this.timeCostSeconds,
    required this.scoreImpact,
    this.isCritical = false,
    bool selected = false,
  }) : super(id: id, kind: NodeKind.action, position: position, selected: selected);

  @override
  ActionNode clone() => ActionNode(
        id: id,
        position: position,
        name: name,
        category: category,
        icon: icon,
        timeCostSeconds: timeCostSeconds,
        scoreImpact: scoreImpact,
        isCritical: isCritical,
        selected: selected,
      );

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': 'action',
        'x': position.dx,
        'y': position.dy,
        'name': name,
        'category': category,
        'iconCodePoint': icon.codePoint,
        'timeCostSeconds': timeCostSeconds,
        'scoreImpact': scoreImpact,
        'isCritical': isCritical,
      };
}

/// A directional connection between two nodes. Always State<->Action;
/// validity is enforced by the controller, not here.
class FlowEdge {
  final String id;
  final String sourceId;
  final String targetId;
  final List<Offset> points; // intermediate points for custom routing
  final String? description; // optional description for the edge

  const FlowEdge({required this.id, required this.sourceId, required this.targetId, this.points = const [], this.description});

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceId': sourceId,
        'targetId': targetId,
        if (points.isNotEmpty) 'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
        if (description != null) 'description': description,
      };
}
