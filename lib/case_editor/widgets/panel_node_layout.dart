import 'package:flutter/material.dart';
import '../models/flow_models.dart';

/// Helper to layout nodes inside a side panel.
class PanelNodeWrapper extends StatelessWidget {
  final FlowNode node;
  final int index;
  final bool isStatePanel;
  final Widget child;

  const PanelNodeWrapper({
    super.key,
    required this.node,
    required this.index,
    required this.isStatePanel,
    required this.child,
  });

  /// Computes the offset for a node inside a panel.
  /// Nodes are stacked vertically with a fixed spacing.
  static Offset computePanelOffset(int index, bool isStatePanel) {
    const double panelTopMargin = 20.0;
    const double verticalSpacing = 20.0;
    // Panels have a fixed width; nodes keep their original dimensions.
    final double y = panelTopMargin + index * (kNodeHeight + verticalSpacing);
    // X is 0 for left panel, or the panel width placeholder for right.
    // The caller will translate the panel container horizontally.
    return Offset(0, y);
  }

  @override
  Widget build(BuildContext context) {
    final offset = computePanelOffset(index, isStatePanel);
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: child,
    );
  }
}
