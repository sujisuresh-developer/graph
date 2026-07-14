import 'package:flutter/material.dart';
import 'case_editor/case_editor_page.dart';

void main() => runApp(const CaseEditorApp());

class CaseEditorApp extends StatelessWidget {
  const CaseEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Case Editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Arial',
        useMaterial3: true,
      ),
      home: const CaseEditorPage(),
    );
  }
}