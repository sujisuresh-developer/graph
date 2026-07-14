import 'package:flutter/material.dart';
import '../models/palette_data.dart';
import 'node_widgets.dart';

class FlowPaletteSidebar extends StatefulWidget {
  const FlowPaletteSidebar({super.key});

  @override
  State<FlowPaletteSidebar> createState() => _FlowPaletteSidebarState();
}

class _FlowPaletteSidebarState extends State<FlowPaletteSidebar> {
  bool _statesExpanded = true;
  bool _actionsExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _CollapsibleSection(
            title: 'States',
            subtitle: 'Drag onto the canvas',
            expanded: _statesExpanded,
            onToggle: () => setState(() => _statesExpanded = !_statesExpanded),
            children: statePalette
                .map((t) => _StatePaletteItem(template: t))
                .toList(growable: false),
          ),
          const Divider(height: 1),
          _CollapsibleSection(
            title: 'Actions',
            subtitle: 'Drag onto the canvas',
            expanded: _actionsExpanded,
            onToggle: () => setState(() => _actionsExpanded = !_actionsExpanded),
            children: actionPalette
                .map((t) => _ActionPaletteItem(template: t))
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _CollapsibleSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  const _CollapsibleSection({
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.onToggle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E1E2D))),
                      Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF9A9AA8))),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B6B7B)),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(children: children),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _StatePaletteItem extends StatelessWidget {
  final StateTemplate template;
  const _StatePaletteItem({required this.template});

  @override
  Widget build(BuildContext context) {
    return Draggable<StateTemplate>(
      data: template,
      feedback: _DragPreview(icon: template.icon, label: template.name, color: StateNodeWidget.accent),
      childWhenDragging: Opacity(opacity: 0.35, child: _PaletteRow(icon: template.icon, label: template.name, color: StateNodeWidget.accent)),
      child: _PaletteRow(icon: template.icon, label: template.name, color: StateNodeWidget.accent),
    );
  }
}

class _ActionPaletteItem extends StatelessWidget {
  final ActionTemplate template;
  const _ActionPaletteItem({required this.template});

  @override
  Widget build(BuildContext context) {
    return Draggable<ActionTemplate>(
      data: template,
      feedback: _DragPreview(icon: template.icon, label: template.name, color: ActionNodeWidget.accent),
      childWhenDragging: Opacity(opacity: 0.35, child: _PaletteRow(icon: template.icon, label: template.name, color: ActionNodeWidget.accent)),
      child: _PaletteRow(icon: template.icon, label: template.name, color: ActionNodeWidget.accent),
    );
  }
}

class _PaletteRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PaletteRow({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F4F1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E1E2D), fontWeight: FontWeight.w500)),
          ),
          Icon(Icons.drag_indicator_rounded, size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}

class _DragPreview extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DragPreview({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}
