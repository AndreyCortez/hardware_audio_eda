import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/workspace_provider.dart';
import 'providers/schematic_provider.dart';
import 'providers/audio_provider.dart';
import 'views/app_shell.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WorkspaceProvider()),
        ChangeNotifierProvider(create: (_) => SchematicProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
      ],
      child: const AudioEdaApp(),
    ),
  );
}

class AudioEdaApp extends StatelessWidget {
  const AudioEdaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio EDA Shell',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Colors.amber,
          surface: Color(0xFF252538),
          background: Color(0xFF14141E),
        ),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}
