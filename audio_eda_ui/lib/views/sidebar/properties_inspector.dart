import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/schematic_provider.dart';

class PropertiesInspector extends StatelessWidget {
  const PropertiesInspector({super.key});

  @override
  Widget build(BuildContext context) {
    // This watches the SchematicProvider for the selected component.
    final schematic = context.watch<SchematicProvider>();
    // Try to find the component. If not selected, return a placeholder.
    // Provider doesn't expose `selectedComponent` as a getter nicely yet, so we find it.
    final compId = schematic.selectedComponentId;
    final comp = compId != null ? schematic.components.where((c) => c.id == compId).firstOrNull : null;

    if (comp == null) {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        child: const Center(
          child: Text('No Node Selected\nClick on a Canvas Component', 
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white24, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.black12,
            child: const Text('PROPERTIES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildField('Designator', comp.logicalName),
                const SizedBox(height: 16),
                _buildField('Type', comp.type.name.toUpperCase()),
                const SizedBox(height: 16),
                _buildField('Value / Model', comp.spiceValue.isEmpty ? 'Default' : comp.spiceValue),
                const SizedBox(height: 16),
                const Text('Rotation', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.rotate_left, color: Colors.amber), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.rotate_right, color: Colors.amber), onPressed: () {}),
                  ],
                ),
                const Divider(height: 32, color: Colors.white12),
                const Text('Terminals (Pins)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                ...comp.terminals.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.circle, size: 8, color: Colors.blueAccent),
                          const SizedBox(width: 8),
                          Text('Pin ${t.name.toUpperCase()}', style: const TextStyle(fontSize: 13, color: Colors.white60)),
                        ],
                      ),
                      Text('(${t.relativePosition.dx.toInt()}, ${t.relativePosition.dy.toInt()})', 
                        style: const TextStyle(fontSize: 12, color: Colors.amber, fontFamily: 'monospace')),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black26,
            border: Border.all(color: Colors.white12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(val, style: const TextStyle(fontSize: 14, color: Colors.white)),
        ),
      ],
    );
  }
}
