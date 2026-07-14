import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/flow_models.dart';
import '../models/palette_data.dart';

enum AutosaveStatus { idle, saving, saved, error }

/// Immutable-ish deep copy of editor state, used purely for undo/redo.
/// Cloning nodes here (not on every drag frame) keeps dragging cheap.
class _Snapshot {
  final Map<String, FlowNode> nodes;
  final List<FlowEdge> edges;
  _Snapshot(this.nodes, this.edges);

  factory _Snapshot.capture(Map<String, FlowNode> nodeLookup, List<FlowEdge> edgeList) {
    return _Snapshot(
      {for (final e in nodeLookup.entries) e.key: e.value.clone()},
      List<FlowEdge>.from(edgeList),
    );
  }
}

/// Single source of truth for the FSM case editor. A plain [ChangeNotifier]
/// so any number of widgets (canvas, toolbar, inspector panels) can listen
/// without prop-drilling callbacks everywhere.
class FlowEditorController extends ChangeNotifier {
  FlowEditorController({this.onAutosave});

  /// Called (debounced) whenever the graph changes, with a JSON-serializable
  /// snapshot. Wire this to a real backend/local-storage call; left as a
  /// hook here so the editor has zero hard dependency on persistence.
  final Future<void> Function(Map<String, dynamic> json)? onAutosave;

  /// Node-by-id lookup. Every mutation below checks this map FIRST before
  /// touching a node, exactly per the requirement: never assume a node
  /// referenced by an id still exists (it may have just been deleted by a
  /// concurrent action, an undo, or a stale drag callback).
  final Map<String, FlowNode> nodeLookup = {};
  final List<FlowEdge> edges = [];

  String? selectedNodeId;
  String? selectedEdgeId;

  final ValueNotifier<AutosaveStatus> autosaveStatus = ValueNotifier(AutosaveStatus.idle);

  final List<_Snapshot> _undoStack = [];
  final List<_Snapshot> _redoStack = [];
  static const int _maxHistory = 50;

  Timer? _autosaveDebounce;

  List<FlowNode> get nodes => nodeLookup.values.toList(growable: false);
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  FlowNode? nodeById(String id) => nodeLookup[id];

  // ---------------------------------------------------------------------
  // Node creation
  // ---------------------------------------------------------------------

  StateNode addNodeFromStateTemplate(StateTemplate template, Offset dropPosition) {
    _pushHistory();
    final node = StateNode(
      id: generateId('state'),
      position: snapToGrid(dropPosition),
      name: template.name,
      icon: template.icon,
      timerSeconds: template.defaultTimerSeconds,
      isTerminal: template.isTerminal,
    );
    nodeLookup[node.id] = node;
    _afterChange();
    return node;
  }

  ActionNode addNodeFromActionTemplate(ActionTemplate template, Offset dropPosition) {
    _pushHistory();
    final node = ActionNode(
      id: generateId('action'),
      position: snapToGrid(dropPosition),
      name: template.name,
      category: template.category,
      icon: template.icon,
      timeCostSeconds: template.timeCostSeconds,
      scoreImpact: template.scoreImpact,
      isCritical: template.isCritical,
    );
    nodeLookup[node.id] = node;
    _afterChange();
    return node;
  }

  // ---------------------------------------------------------------------
  // Node movement
  // ---------------------------------------------------------------------

  /// Called continuously while dragging. No history push here (that would
  /// flood the undo stack) - just a guarded, live position update.
  void moveNode(String id, Offset newPosition) {
    final node = nodeLookup[id];
    // Safety check: the parent node must exist in the lookup before we
    // touch its position. Without this, a node deleted mid-drag (e.g. via
    // a stray Delete keypress or an undo triggered from another tab) would
    // throw a null-check error here instead of silently no-op-ing.
    if (node == null) return;
    node.position = newPosition;
    notifyListeners();
  }

  /// Called once on drag end: snaps to grid and commits one history entry.
  void endMoveNode(String id) {
    final node = nodeLookup[id];
    if (node == null) return;
    _pushHistory();
    node.position = snapToGrid(node.position);
    _afterChange();
  }

  // ---------------------------------------------------------------------
  // Connections
  // ---------------------------------------------------------------------

  /// The core validation rule: connections are only ever State -> Action or
  /// Action -> State. Both endpoints must exist in the lookup - this is the
  /// same guard pattern as [moveNode], applied to edge creation.
  bool canConnect(String sourceId, String targetId) {
    if (sourceId == targetId) return false;
    final source = nodeLookup[sourceId];
    final target = nodeLookup[targetId];
    if (source == null || target == null) return false;
    if (source.kind == target.kind) return false; // blocks State->State, Action->Action
    final alreadyExists = edges.any((e) => e.sourceId == sourceId && e.targetId == targetId);
    return !alreadyExists;
  }

  bool addEdge(String sourceId, String targetId) {
    if (!canConnect(sourceId, targetId)) return false;
    _pushHistory();
    edges.add(FlowEdge(id: generateId('edge'), sourceId: sourceId, targetId: targetId));
    _afterChange();
    return true;
  }

  /// Add or update intermediate points and description for an existing edge.
  void addEdgePoints(String edgeId, List<Offset> points, String? description) {
    final index = edges.indexWhere((e) => e.id == edgeId);
    if (index == -1) return;
    _pushHistory();
    final old = edges[index];
    edges[index] = FlowEdge(
      id: old.id,
      sourceId: old.sourceId,
      targetId: old.targetId,
      points: points,
      description: description,
    );
    _afterChange();
  }

  void deleteEdge(String id) {
    if (!edges.any((e) => e.id == id)) return;
    _pushHistory();
    edges.removeWhere((e) => e.id == id);
    if (selectedEdgeId == id) selectedEdgeId = null;
    _afterChange();
  }

  // ---------------------------------------------------------------------
  // Deletion
  // ---------------------------------------------------------------------

  void deleteNode(String id) {
    if (!nodeLookup.containsKey(id)) return;
    _pushHistory();
    nodeLookup.remove(id);
    edges.removeWhere((e) => e.sourceId == id || e.targetId == id);
    if (selectedNodeId == id) selectedNodeId = null;
    _afterChange();
  }

  void deleteSelected() {
    if (selectedNodeId != null) {
      deleteNode(selectedNodeId!);
    } else if (selectedEdgeId != null) {
      deleteEdge(selectedEdgeId!);
    }
  }

  // ---------------------------------------------------------------------
  // Selection
  // ---------------------------------------------------------------------

  void selectNode(String? id) {
    selectedNodeId = id;
    selectedEdgeId = null;
    notifyListeners();
  }

  void selectEdge(String? id) {
    selectedEdgeId = id;
    selectedNodeId = null;
    notifyListeners();
  }

  void clearSelection() {
    if (selectedNodeId == null && selectedEdgeId == null) return;
    selectedNodeId = null;
    selectedEdgeId = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Undo / redo
  // ---------------------------------------------------------------------

  void _pushHistory() {
    _undoStack.add(_Snapshot.capture(nodeLookup, edges));
    if (_undoStack.length > _maxHistory) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final current = _Snapshot.capture(nodeLookup, edges);
    final previous = _undoStack.removeLast();
    _redoStack.add(current);
    _restore(previous);
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final current = _Snapshot.capture(nodeLookup, edges);
    final next = _redoStack.removeLast();
    _undoStack.add(current);
    _restore(next);
  }

  void _restore(_Snapshot snapshot) {
    nodeLookup
      ..clear()
      ..addAll(snapshot.nodes);
    edges
      ..clear()
      ..addAll(snapshot.edges);
    selectedNodeId = null;
    selectedEdgeId = null;
    notifyListeners();
    _scheduleAutosave();
  }

  // ---------------------------------------------------------------------
  // Autosave
  // ---------------------------------------------------------------------

  void _afterChange() {
    notifyListeners();
    _scheduleAutosave();
  }

  void _scheduleAutosave() {
    _autosaveDebounce?.cancel();
    autosaveStatus.value = AutosaveStatus.idle;
    _autosaveDebounce = Timer(const Duration(milliseconds: 800), () async {
      if (onAutosave == null) return;
      autosaveStatus.value = AutosaveStatus.saving;
      try {
        await onAutosave!(toJson());
        autosaveStatus.value = AutosaveStatus.saved;
      } catch (_) {
        autosaveStatus.value = AutosaveStatus.error;
      }
    });
  }

  Map<String, dynamic> toJson() => {
        'nodes': nodeLookup.values.map((n) => n.toJson()).toList(),
        'edges': edges.map((e) => e.toJson()).toList(),
      };

  // ---------------------------------------------------------------------
  // Fit to screen
  // ---------------------------------------------------------------------

  /// Computes the scale + translation needed to fit every node inside
  /// [viewportSize] with padding. Returns null if the canvas is empty.
  ({double scale, Offset translation})? computeFitTransform(
    Size viewportSize, {
    double padding = 96,
  }) {
    if (nodeLookup.isEmpty) return null;

    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;
    for (final node in nodeLookup.values) {
      minX = min(minX, node.position.dx);
      minY = min(minY, node.position.dy);
      maxX = max(maxX, node.position.dx + kNodeWidth);
      maxY = max(maxY, node.position.dy + kNodeHeight);
    }

    final contentWidth = (maxX - minX).clamp(1, double.infinity);
    final contentHeight = (maxY - minY).clamp(1, double.infinity);

    final scaleX = (viewportSize.width - padding * 2) / contentWidth;
    final scaleY = (viewportSize.height - padding * 2) / contentHeight;
    final scale = min(scaleX, scaleY).clamp(0.2, 1.5);

    final contentCenter = Offset(minX + contentWidth / 2, minY + contentHeight / 2);
    final viewportCenter = Offset(viewportSize.width / 2, viewportSize.height / 2);
    final translation = viewportCenter - (contentCenter * scale);

    return (scale: scale, translation: translation);
  }

  @override
  void dispose() {
    _autosaveDebounce?.cancel();
    autosaveStatus.dispose();
    super.dispose();
  }
}
