import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workspace_provider.dart';

class ActivityBar extends StatelessWidget {
  const ActivityBar({super.key});

  @override
  Widget build(BuildContext context) {
    final workspace = context.watch<WorkspaceProvider>();
    
    return Container(
      width: 50,
      color: const Color(0xFF181824),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildActivityIcon(
            context,
            icon: Icons.account_tree,
            index: 0,
            tooltip: 'Component Browser',
            isActive: workspace.activeSidebarIndex == 0 && workspace.isSidebarOpen,
            onTap: () => context.read<WorkspaceProvider>().setActiveSidebarIndex(0),
          ),
          _buildActivityIcon(
            context,
            icon: Icons.settings,
            index: 1,
            tooltip: 'Workspace Preferences',
            isActive: workspace.activeSidebarIndex == 1 && workspace.isSidebarOpen,
            onTap: () => context.read<WorkspaceProvider>().setActiveSidebarIndex(1),
          ),
          const Spacer(),
          _buildActivityIcon(
            context,
            icon: Icons.graphic_eq,
            index: -1,
            tooltip: 'Toggle Audio DSP Panel',
            isActive: workspace.isBottomPanelOpen,
            onTap: () => context.read<WorkspaceProvider>().toggleBottomPanel(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActivityIcon(BuildContext context, {
    required IconData icon, 
    required int index, 
    required String tooltip,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isActive ? Theme.of(context).colorScheme.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.white54,
            size: 28,
          ),
        ),
      ),
    );
  }
}
