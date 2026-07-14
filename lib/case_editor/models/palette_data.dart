import 'package:flutter/material.dart';

/// A lightweight blueprint shown in the sidebar. When dragged onto the
/// canvas, the controller clones this into a real [StateNode] with a fresh
/// id and drop position - the template itself never changes.
class StateTemplate {
  final String name;
  final IconData icon;
  final bool isTerminal;
  final int? defaultTimerSeconds;

  const StateTemplate({
    required this.name,
    required this.icon,
    this.isTerminal = false,
    this.defaultTimerSeconds,
  });
}

/// Same idea as [StateTemplate] but for action nodes.
class ActionTemplate {
  final String name;
  final String category;
  final IconData icon;
  final int timeCostSeconds;
  final int scoreImpact;
  final bool isCritical;

  const ActionTemplate({
    required this.name,
    required this.category,
    required this.icon,
    required this.timeCostSeconds,
    required this.scoreImpact,
    this.isCritical = false,
  });
}

/// Predefined state nodes available in the "States" sidebar section.
const List<StateTemplate> statePalette = [
  StateTemplate(name: 'Patient Arrival', icon: Icons.local_hospital_outlined, defaultTimerSeconds: 60),
  StateTemplate(name: 'Initial Assessment', icon: Icons.fact_check_outlined, defaultTimerSeconds: 120),
  StateTemplate(name: 'Diagnosis', icon: Icons.biotech_outlined, defaultTimerSeconds: 180),
  StateTemplate(name: 'Treatment', icon: Icons.medical_services_outlined, defaultTimerSeconds: 240),
  StateTemplate(name: 'Recovery', icon: Icons.favorite_outline, defaultTimerSeconds: 180),
  StateTemplate(name: 'Critical Condition', icon: Icons.warning_amber_rounded, defaultTimerSeconds: 60),
  StateTemplate(name: 'Death', icon: Icons.dangerous_outlined, isTerminal: true),
  StateTemplate(name: 'Success', icon: Icons.check_circle_outline, isTerminal: true),
];

/// Predefined action nodes available in the "Actions" sidebar section.
const List<ActionTemplate> actionPalette = [
  ActionTemplate(name: 'History', category: 'Assessment', icon: Icons.history_edu_outlined, timeCostSeconds: 60, scoreImpact: 2),
  ActionTemplate(name: 'Physical Examination', category: 'Assessment', icon: Icons.accessibility_new_outlined, timeCostSeconds: 90, scoreImpact: 3),
  ActionTemplate(name: 'ECG', category: 'Diagnostics', icon: Icons.monitor_heart_outlined, timeCostSeconds: 120, scoreImpact: 4),
  ActionTemplate(name: 'Chest X-Ray', category: 'Diagnostics', icon: Icons.image_outlined, timeCostSeconds: 480, scoreImpact: 3),
  ActionTemplate(name: 'Laboratory', category: 'Diagnostics', icon: Icons.science_outlined, timeCostSeconds: 300, scoreImpact: 3),
  ActionTemplate(name: 'Medication', category: 'Treatment', icon: Icons.medication_outlined, timeCostSeconds: 30, scoreImpact: 5),
  ActionTemplate(name: 'Procedure', category: 'Treatment', icon: Icons.healing_outlined, timeCostSeconds: 60, scoreImpact: 6),
  ActionTemplate(name: 'Oxygen', category: 'Treatment', icon: Icons.air_outlined, timeCostSeconds: 30, scoreImpact: 3),
  ActionTemplate(name: 'Intubation', category: 'Critical', icon: Icons.airline_seat_flat_outlined, timeCostSeconds: 60, scoreImpact: 8, isCritical: true),
  ActionTemplate(name: 'CPR', category: 'Critical', icon: Icons.monitor_heart, timeCostSeconds: 120, scoreImpact: 10, isCritical: true),
];
