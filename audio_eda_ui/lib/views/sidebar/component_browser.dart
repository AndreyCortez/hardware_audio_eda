import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/schematic_provider.dart';
import '../../models/component_model.dart';
import '../../utils/spice_compiler.dart';

class ComponentBrowser extends StatelessWidget {
  const ComponentBrowser({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.black12,
          child: const Text('EXPLORER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              _buildCategoryTitle('Passive Components'),
              _buildAdder(context, 'Resistor', Icons.show_chart, ComponentType.resistor),
              _buildAdder(context, 'Capacitor', Icons.battery_charging_full, ComponentType.capacitor),
              
              const SizedBox(height: 12),
              _buildCategoryTitle('Active Semiconductors'),
              _buildAdder(context, 'Diode (1N4148)', Icons.arrow_right_alt, ComponentType.diode),
              _buildAdder(context, 'NPN BJT (2N3904)', Icons.memory, ComponentType.bjt_npn),
              
              const SizedBox(height: 12),
              _buildCategoryTitle('Routing & Power'),
              _buildAdder(context, 'Ground', Icons.keyboard_capslock_outlined, ComponentType.ground),
              _buildAdder(context, 'Audio Input (WAV)', Icons.music_note, ComponentType.audio_in),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white12)),
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
            ),
            icon: const Icon(Icons.bolt, size: 24),
            onPressed: () {
              final schematic = context.read<SchematicProvider>();
              final netlist = SpiceCompiler.compileNetlist(
                schematic.components, 
                schematic.wires
              );
              showDialog(
                context: context, 
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF1B1B22),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white24)),
                  title: const Row(
                    children: [
                      Icon(Icons.terminal, color: Colors.amber),
                      SizedBox(width: 8),
                      Text('SPICE Netlist (.cir)', style: TextStyle(color: Colors.white, fontSize: 18)),
                    ],
                  ),
                  content: Container(
                    width: 500,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(netlist, style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 13)),
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: Colors.amber)))
                  ]
                )
              );
            },
            label: const Text('GENERATE NETLIST', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    );
  }

  Widget _buildAdder(BuildContext context, String label, IconData icon, ComponentType type) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: const BorderSide(color: Colors.white12)),
      child: InkWell(
        onTap: () {
          context.read<SchematicProvider>().addComponent(type, const Offset(300, 300));
        },
        borderRadius: BorderRadius.circular(6),
        hoverColor: Colors.white10,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.amberAccent),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
              const Icon(Icons.add, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
