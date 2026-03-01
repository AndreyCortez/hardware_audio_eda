import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum ComponentType { resistor, capacitor, diode, bjt_npn, bjt_pnp, potentiometer, power, ground, audio_in, audio_out }

class Terminal {
  final String id;
  final String componentId;
  final String name; // 'p', 'n', 'c', 'b', 'e'
  final Offset relativePosition;

  Terminal({
    required this.componentId,
    required this.name,
    required this.relativePosition,
  }) : id = const Uuid().v4();
}

class ComponentModel {
  final String id;
  final ComponentType type;
  String logicalName; // e.g. "R1", "C2"
  String spiceValue; // e.g. "10k", "0.1uF"
  Offset position;
  int rotationId; // 0, 1, 2, 3 (* 90 degrees)
  late List<Terminal> terminals;

  ComponentModel({
    String? id,
    required this.type,
    required this.logicalName,
    this.spiceValue = '',
    this.position = Offset.zero,
    this.rotationId = 0,
    List<Terminal>? customTerminals,
  }) : id = id ?? const Uuid().v4() {
    terminals = customTerminals ?? _generateDefaultTerminals();
  }

  List<Terminal> _generateDefaultTerminals() {
    switch (type) {
      case ComponentType.bjt_npn:
      case ComponentType.bjt_pnp:
        return [
          Terminal(componentId: id, name: 'c', relativePosition: const Offset(20, -20)),
          Terminal(componentId: id, name: 'b', relativePosition: const Offset(-20, 0)),
          Terminal(componentId: id, name: 'e', relativePosition: const Offset(20, 20)),
        ];
      case ComponentType.ground:
        return [
          Terminal(componentId: id, name: 'gnd', relativePosition: const Offset(0, -20)),
        ];
      default:
        // Two terminal components (Resistors, Capacitors, etc.)
        return [
          Terminal(componentId: id, name: 'p', relativePosition: const Offset(-30, 0)),
          Terminal(componentId: id, name: 'n', relativePosition: const Offset(30, 0)),
        ];
    }
  }
}
