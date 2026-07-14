import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/flow_models.dart';
import '../models/palette_data.dart';
import '../state/flow_editor_controller.dart';
import '../state/flow_viewport_controller.dart';
import 'edge_painter.dart';
import 'node_widgets.dart';

/// Large virtual canvas size the graph lives in. InteractiveViewer pans/
/// zooms within this - it does not need to match the visible viewport.
const double kCanvasWidth = 6000;
const double kCanvasHeight = 4000;

class FlowCanvas extends StatefulWidget {
  final FlowEditorController controller;
  final FlowViewportController? viewportController;

  const FlowCanvas({super.key, required this.controller, this.viewportController});

  @override
  State<FlowCanvas> createState() => _FlowCanvasState();
}

class _FlowCanvasState extends State<FlowCanvas> {
  final TransformationController _transformController = TransformationController();
  final GlobalKey _contentKey = GlobalKey();
  final FocusNode _focusNode = FocusNode();

  PendingEdge? _pendingEdge;

  @override
  void initState() {
    super.initState();
    // Start roughly centered so nodes dropped near the origin are visible.
    _transformController.value = Matrix4.identity()
      ..translate(-kCanvasWidth / 2 + 400, -kCanvasHeight / 2 + 300);

    widget.viewportController?.attach(
      zoomIn: () => _zoomBy(1.2),
      zoomOut: () => _zoomBy(1 / 1.2),
      fitToScreen: _fitToScreen,
      reset: _resetView,
    );
  }

  @override
  void dispose() {
    widget.viewportController?.detach();
    _transformController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Converts a global (screen) pointer position into a position within the
  /// canvas's content space, correctly accounting for the current pan/zoom
  /// transform - this is what makes drag/drop and node dragging behave
  /// correctly at any zoom level.
  Offset _toContentPosition(Offset global) {
    final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return global;
    return box.globalToLocal(global);
  }

  void _zoomBy(double factor) {
    final matrix = _transformController.value.clone();
    final newScale = (matrix.getMaxScaleOnAxis() * factor).clamp(0.2, 2.5);
    final currentScale = matrix.getMaxScaleOnAxis();
    matrix.scale(newScale / currentScale);
    _transformController.value = matrix;
  }

  void _fitToScreen() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final fit = widget.controller.computeFitTransform(renderBox.size);
    if (fit == null) return;
    _transformController.value = Matrix4.identity()
      ..translate(fit.translation.dx, fit.translation.dy)
      ..scale(fit.scale);
  }

  void _resetView() {
    _transformController.value = Matrix4.identity()
      ..translate(-kCanvasWidth / 2 + 400, -kCanvasHeight / 2 + 300);
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final isDeleteKey = event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace;
    final isCtrlOrCmd = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;

    if (isDeleteKey) {
      widget.controller.deleteSelected();
    } else if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyZ) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        widget.controller.redo();
      } else {
        widget.controller.undo();
      }
    } else if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyY) {
      widget.controller.redo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        _handleKeyEvent(event);
        return KeyEventResult.handled;
      },
      child: DragTarget<Object>(
        onWillAcceptWithDetails: (details) => details.data is StateTemplate || details.data is ActionTemplate,
        onAcceptWithDetails: (details) {
          final dropContentPos = _toContentPosition(details.offset) - const Offset(kNodeWidth / 2, kNodeHeight / 2);
          final data = details.data;
          if (data is StateTemplate) {
            widget.controller.addNodeFromStateTemplate(data, dropContentPos);
          } else if (data is ActionTemplate) {
            widget.controller.addNodeFromActionTemplate(data, dropContentPos);
          }
          _focusNode.requestFocus();
        },
        builder: (context, candidateData, rejectedData) {
          return GestureDetector(
            onTap: () {
              widget.controller.clearSelection();
              _focusNode.requestFocus();
            },
            child: Container(
              color: const Color(0xFFF6F4F1),
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.2,
                maxScale: 2.5,
                boundaryMargin: const EdgeInsets.all(2000),
                constrained: false,
                child: SizedBox(
                  width: kCanvasWidth,
                  height: kCanvasHeight,
                  child: ListenableBuilder(
                    listenable: widget.controller,
                    builder: (context, _) {
                      return Stack(
                        key: _contentKey,
                        clipBehavior: Clip.none,
                        children: [
                          const Positioned.fill(
                            child: CustomPaint(painter: GridBackgroundPainter()),
                          ),
                          Positioned.fill(
                            child: AnimatedFlowEdges(
                              nodeLookup: widget.controller.nodeLookup,
                              edges: widget.controller.edges,
                              canvasSize: const Size(kCanvasWidth, kCanvasHeight),
                              selectedEdgeId: widget.controller.selectedEdgeId,
                              pendingEdge: _pendingEdge,
                            ),
                          ),
                          for (final node in widget.controller.nodes) _buildNode(node),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNode(FlowNode node) {
    final selected = node.id == widget.controller.selectedNodeId;

    if (node is StateNode) {
      return Positioned(
        left: node.position.dx,
        top: node.position.dy,
        child: StateNodeWidget(
          node: node,
          selected: selected,
          onTap: widget.controller.selectNode,
          toContentPosition: _toContentPosition,
          onDragStart: (id, pos, grab) => widget.controller.selectNode(id),
          onDragUpdate: (id, pos, grab) => widget.controller.moveNode(id, pos - grab),
          onDragEnd: widget.controller.endMoveNode,
          onConnectStart: _startConnection,
          onConnectUpdate: _updateConnection,
          onConnectEnd: _endConnection,
        ),
      );
    }

    if (node is ActionNode) {
      return Positioned(
        left: node.position.dx,
        top: node.position.dy,
        child: ActionNodeWidget(
          node: node,
          selected: selected,
          onTap: widget.controller.selectNode,
          toContentPosition: _toContentPosition,
          onDragStart: (id, pos, grab) => widget.controller.selectNode(id),
          onDragUpdate: (id, pos, grab) => widget.controller.moveNode(id, pos - grab),
          onDragEnd: widget.controller.endMoveNode,
          onConnectStart: _startConnection,
          onConnectUpdate: _updateConnection,
          onConnectEnd: _endConnection,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _startConnection(String sourceId, Offset contentPosition) {
    setState(() => _pendingEdge = PendingEdge(sourceId: sourceId, currentPosition: contentPosition));
  }

  void _updateConnection(Offset contentPosition) {
    if (_pendingEdge == null) return;
    setState(() => _pendingEdge = PendingEdge(sourceId: _pendingEdge!.sourceId, currentPosition: contentPosition));
  }

  void _endConnection(Offset contentPosition) {
    final pending = _pendingEdge;
    setState(() => _pendingEdge = null);
    if (pending == null) return;

    // Hit-test every node's rect to find a drop target under the pointer.
    for (final node in widget.controller.nodes) {
      if (node.id == pending.sourceId) continue;
      if (node.rect.contains(contentPosition)) {
        widget.controller.addEdge(pending.sourceId, node.id);
        return;
      }
    }
  }
}
