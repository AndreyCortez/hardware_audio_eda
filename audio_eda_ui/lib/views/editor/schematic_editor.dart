import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/schematic_provider.dart';
import '../../models/component_model.dart';

class SchematicEditor extends StatelessWidget {
  const SchematicEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final schematic = context.watch<SchematicProvider>();

    return GestureDetector(
      onTap: () => context.read<SchematicProvider>().selectComponent(null),
      child: Container(
        color: const Color(0xFF1B1B22),
        child: Stack(
          children: [
            CustomPaint(
              painter: _GridPainter(),
              size: Size.infinite,
            ),
            
            // Interaction Toolbar
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.undo, size: 20, color: Colors.white70), onPressed: () {}, tooltip: 'Undo'),
                    IconButton(icon: const Icon(Icons.redo, size: 20, color: Colors.white70), onPressed: () {}, tooltip: 'Redo'),
                    Container(width: 1, height: 24, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 8)),
                    IconButton(icon: const Icon(Icons.zoom_in, size: 20, color: Colors.white70), onPressed: () {}, tooltip: 'Zoom In'),
                    IconButton(icon: const Icon(Icons.zoom_out, size: 20, color: Colors.white70), onPressed: () {}, tooltip: 'Zoom Out'),
                  ],
                ),
              ),
            ),

            for (var comp in schematic.components)
              Positioned(
                // Position tracks the *center* of the 80x60 interaction box for seamless dragging
                left: comp.position.dx - 40,
                top: comp.position.dy - 30,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    context.read<SchematicProvider>().updateComponentPosition(
                      comp.id, 
                      comp.position + details.delta
                    );
                  },
                  onTap: () {
                    context.read<SchematicProvider>().selectComponent(comp.id);
                  },
                  child: _buildDetailedComponent(comp, schematic.selectedComponentId == comp.id),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedComponent(ComponentModel comp, bool isSelected) {
    return SizedBox(
      width: 80,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main Body Box
          Center(
            child: Container(
              width: 50,
              height: 30,
              decoration: BoxDecoration(
                color: isSelected ? Colors.amber.withOpacity(0.15) : const Color(0xFF2C2C38),
                border: Border.all(
                  color: isSelected ? Colors.amber : Colors.white24,
                  width: isSelected ? 2 : 1.5,
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: isSelected ? [const BoxShadow(color: Colors.amber, blurRadius: 4, spreadRadius: -2)] : [],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      comp.logicalName, 
                      style: TextStyle(
                        fontSize: 11, 
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.amber : Colors.white
                      )
                    ),
                    if (comp.spiceValue.isNotEmpty)
                      Text(comp.spiceValue, style: const TextStyle(fontSize: 8, color: Colors.white54)),
                  ],
                ),
              ),
            ),
          ),
          
          // Render Outwards Terminals (Pins)
          for (var t in comp.terminals)
            Positioned(
              left: 40 + t.relativePosition.dx - 4, // 40 is half width
              top: 30 + t.relativePosition.dy - 4,  // 30 is half height
              child: Tooltip(
                message: 'Pin: ${t.name}',
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 2)],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.5;
      
    const double gridSize = 20.0;
    
    // Draw dot grid matrix (Engineering standard)
    for (double i = 0; i < size.width; i += gridSize) {
      for (double j = 0; j < size.height; j += gridSize) {
        canvas.drawCircle(Offset(i, j), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
