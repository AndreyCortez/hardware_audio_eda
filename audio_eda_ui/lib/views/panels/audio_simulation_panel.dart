import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/workspace_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/schematic_provider.dart';
import '../../utils/spice_compiler.dart';

class AudioSimulationPanel extends StatelessWidget {
  const AudioSimulationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    var audioProv = context.watch<AudioProvider>();
    
    return Container(
      color: const Color(0xFF1E1E2C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.black26,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.terminal, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('TERMINAL & AUDIO DSP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, letterSpacing: 1.1)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.clear_all, size: 18, color: Colors.white54), onPressed: () {}, tooltip: 'Clear Console'),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.white54), 
                      onPressed: () => context.read<WorkspaceProvider>().toggleBottomPanel(), 
                      tooltip: 'Close Panel'
                    ),
                  ],
                )
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.white12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('NgSpice Subprocess Log', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'monospace')),
                        const SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            reverse: true,
                            child: SelectableText(
                              audioProv.processLog, 
                              style: const TextStyle(color: Colors.white54, fontSize: 13, fontFamily: 'monospace'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: audioProv.isProcessing || audioProv.dryAudioFile == null ? null : () {
                            final schematic = context.read<SchematicProvider>();
                            final netlist = SpiceCompiler.compileNetlist(
                              schematic.components, 
                              schematic.wires
                            );
                            audioProv.runSpiceSimulation(netlist);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            disabledBackgroundColor: Colors.white10,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 50),
                            elevation: 4,
                          ),
                          icon: audioProv.isProcessing 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.grey, strokeWidth: 2)) 
                            : const Icon(Icons.play_arrow, size: 28),
                          label: Text(audioProv.isProcessing ? 'COMPUTING SPICE...' : 'RUN SIMULATION', 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2, color: audioProv.isProcessing ? Colors.grey : Colors.black)),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Waveform Comparison (A/B)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await context.read<AudioProvider>().pickAudioFile();
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white24),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.audio_file, size: 18),
                              label: Text(audioProv.dryAudioFile != null ? audioProv.dryAudioFile!.name : 'Carregar Input (.wav)', style: const TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(child: _buildWaveformTrack('DRY (INSTRUMENTO LIMPO)', Colors.blueGrey, audioProv.dryAudioFile != null, audioProv.isPlayingDry, () => audioProv.toggleDry())),
                        const SizedBox(height: 16),
                        Expanded(child: _buildWaveformTrack('WET (OVERDRIVE SPICE)', Colors.amber, audioProv.wetAudioBytes != null, audioProv.isPlayingWet, () => audioProv.toggleWet())),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformTrack(String title, Color color, bool isLoaded, bool isPlaying, VoidCallback onPlayToggle) {
    return Container(
      decoration: BoxDecoration(
        color: isLoaded ? Colors.black38 : Colors.black12,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isLoaded ? color.withOpacity(0.5) : Colors.white12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 11, color: isLoaded ? color : Colors.white30, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Row(
                children: [
                  IconButton(
                    icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 28),
                    color: isLoaded ? color : Colors.white12,
                    onPressed: isLoaded ? onPlayToggle : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.volume_up, size: 18, color: isLoaded ? Colors.grey : Colors.white12),
                ],
              )
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: isLoaded 
              ? List.generate(120, (index) {
                  double heightFactor = (index % 12 == 0) ? 0.9 : 0.2 + ((index * 7) % 5) * 0.12;
                  if (title.contains('WET')) heightFactor *= 1.4;
                  if (heightFactor > 1.0) heightFactor = 1.0;
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: 3,
                    height: 45 * heightFactor,
                    decoration: BoxDecoration(
                      color: isPlaying ? color : color.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                })
              : [const Text('NO AUDIO DATA', style: TextStyle(color: Colors.white24, letterSpacing: 2, fontSize: 12))],
            ),
          )
        ],
      ),
    );
  }
}
