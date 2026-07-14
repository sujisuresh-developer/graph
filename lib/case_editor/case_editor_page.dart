import 'dart:convert';
import 'package:flutter/material.dart';
import 'state/flow_editor_controller.dart';
import 'state/flow_viewport_controller.dart';
import 'widgets/editor_toolbar.dart';
import 'widgets/flow_canvas.dart';
import 'widgets/palette_sidebar.dart';

class CaseEditorPage extends StatefulWidget {
  const CaseEditorPage({super.key});

  @override
  State<CaseEditorPage> createState() => _CaseEditorPageState();
}

class _CaseEditorPageState extends State<CaseEditorPage> {
  late final FlowEditorController _controller;
  final FlowViewportController _viewportController = FlowViewportController();

  @override
  void initState() {
    super.initState();
    _controller = FlowEditorController(onAutosave: _handleAutosave);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Wire this to your real backend (REST/Firebase/Supabase/etc). Left as a
  /// stub that just logs the payload so the editor works standalone.
  Future<void> _handleAutosave(Map<String, dynamic> json) async {
    await Future.delayed(const Duration(milliseconds: 350));
    debugPrint('Case autosaved: ${jsonEncode(json)}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4F1),
      body: Column(
        children: [
          EditorToolbar(controller: _controller, viewportController: _viewportController),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: FlowCanvas(controller: _controller, viewportController: _viewportController),
                ),
                const SizedBox(
                  width: 300,
                  child: FlowPaletteSidebar(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
