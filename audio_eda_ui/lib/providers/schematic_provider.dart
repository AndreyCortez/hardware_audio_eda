import 'package:flutter/material.dart';
import '../models/component_model.dart';
import '../models/wire_connection.dart';

class SchematicProvider extends ChangeNotifier {
  final List<ComponentModel> _components = [];
  final List<WireConnection> _wires = [];

  List<ComponentModel> get components => _components;
  List<WireConnection> get wires => _wires;

  String? _selectedComponentId;
  String? get selectedComponentId => _selectedComponentId;

  ComponentModel? get _selectedComponent {
    try {
      return _components.firstWhere((c) => c.id == _selectedComponentId);
    } catch (_) {
      return null;
    }
  }

  void addComponent(ComponentType type, Offset position) {
    String prefix = type.name.substring(0, 1).toUpperCase();
    if (type == ComponentType.ground) prefix = 'GND';

    final comp = ComponentModel(
      type: type,
      logicalName: '$prefix${_components.length + 1}',
      position: position,
    );
    _components.add(comp);
    notifyListeners();
  }

  void updateComponentPosition(String id, Offset newPos) {
    final idx = _components.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _components[idx].position = newPos;
      notifyListeners();
    }
  }

  void selectComponent(String? id) {
    _selectedComponentId = id;
    notifyListeners();
  }
}
