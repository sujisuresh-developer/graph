import 'package:flutter/material.dart';
import '../state/flow_editor_controller.dart';
import '../state/flow_viewport_controller.dart';

class EditorToolbar extends StatelessWidget {
  final FlowEditorController controller;
  final FlowViewportController viewportController;

  const EditorToolbar({super.key, required this.controller, required this.viewportController});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE3E1DC))),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_tree_outlined, color: Color(0xFF2F6BFF)),
          const SizedBox(width: 10),
          const Text('Case Editor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E1E2D))),
          const SizedBox(width: 24),
          Expanded(
            child: Row(
              children: [
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) {
                    return Row(
                      children: [
                        _ToolbarButton(icon: Icons.undo_rounded, tooltip: 'Undo (Ctrl+Z)', enabled: controller.canUndo, onTap: controller.undo),
                        _ToolbarButton(icon: Icons.redo_rounded, tooltip: 'Redo (Ctrl+Shift+Z)', enabled: controller.canRedo, onTap: controller.redo),
                        _ToolbarButton(
                          icon: Icons.delete_outline_rounded,
                          tooltip: 'Delete selected (Del)',
                          enabled: controller.selectedNodeId != null || controller.selectedEdgeId != null,
                          onTap: controller.deleteSelected,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 8),
                Container(width: 1, height: 26, color: const Color(0xFFE3E1DC)),
                const SizedBox(width: 8),
                _ToolbarButton(icon: Icons.zoom_out_rounded, tooltip: 'Zoom out', enabled: true, onTap: viewportController.zoomOut),
                _ToolbarButton(icon: Icons.zoom_in_rounded, tooltip: 'Zoom in', enabled: true, onTap: viewportController.zoomIn),
                _ToolbarButton(icon: Icons.fit_screen_rounded, tooltip: 'Fit to screen', enabled: true, onTap: viewportController.fitToScreen),
                const Spacer(),
                ValueListenableBuilder<AutosaveStatus>(
                  valueListenable: controller.autosaveStatus,
                  builder: (context, status, _) => _AutosaveIndicator(status: status),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  const _ToolbarButton({required this.icon, required this.tooltip, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 20),
        color: enabled ? const Color(0xFF1E1E2D) : const Color(0xFFCFCDC7),
        onPressed: enabled ? onTap : null,
      ),
    );
  }
}

class _AutosaveIndicator extends StatelessWidget {
  final AutosaveStatus status;
  const _AutosaveIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;
    late final IconData icon;

    switch (status) {
      case AutosaveStatus.idle:
        label = 'All changes saved';
        color = const Color(0xFF9A9AA8);
        icon = Icons.cloud_done_outlined;
        break;
      case AutosaveStatus.saving:
        label = 'Saving...';
        color = const Color(0xFFF2A93B);
        icon = Icons.cloud_sync_outlined;
        break;
      case AutosaveStatus.saved:
        label = 'Saved';
        color = const Color(0xFF34C759);
        icon = Icons.cloud_done_outlined;
        break;
      case AutosaveStatus.error:
        label = 'Save failed';
        color = const Color(0xFFE5484D);
        icon = Icons.cloud_off_outlined;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
