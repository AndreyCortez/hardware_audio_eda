import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import '../providers/workspace_provider.dart';
import 'activity_bar.dart';
import 'editor/schematic_editor.dart';
import 'sidebar/component_browser.dart';
import 'sidebar/properties_inspector.dart';
import 'panels/audio_simulation_panel.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final ResizableController _hController = ResizableController();
  final ResizableController _vController = ResizableController();

  @override
  void dispose() {
    _hController.dispose();
    _vController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workspace = context.watch<WorkspaceProvider>();

    return Scaffold(
      body: Row(
        children: [
          const ActivityBar(),
          Expanded(
            child: ResizableContainer(
              direction: Axis.horizontal,
              controller: _hController,
              children: [
                if (workspace.isSidebarOpen)
                  ResizableChild(
                    size: const ResizableSize.pixels(300),
                    child: Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: workspace.activeSidebarIndex == 0 
                          ? const ComponentBrowser() 
                          : const Center(child: Text('System Preferences')),
                    ),
                  ),
                ResizableChild(
                  size: const ResizableSize.expand(),
                  child: ResizableContainer(
                    direction: Axis.vertical,
                    controller: _vController,
                    children: [
                      // Center Canvas Area
                      ResizableChild(
                        size: const ResizableSize.expand(),
                        child: Row(
                          children: [
                            // Canvas
                            const Expanded(
                              child: SchematicEditor(),
                            ),
                            // Right Dockable Inspector
                            if (workspace.isRightPanelOpen)
                              Container(
                                width: 280,
                                decoration: const BoxDecoration(
                                  border: Border(left: BorderSide(color: Colors.white12)),
                                ),
                                child: const PropertiesInspector(),
                              )
                          ],
                        ),
                      ),
                      // Bottom Audio DSP Panel
                      if (workspace.isBottomPanelOpen)
                        const ResizableChild(
                          size: ResizableSize.pixels(300),
                          child: AudioSimulationPanel(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
