import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

class AudioProvider extends ChangeNotifier {
  PlatformFile? _dryAudioFile;
  Uint8List? _wetAudioBytes;
  
  bool _isProcessing = false;
  String _processLog = "> Waiting for engine start...\n";

  // Audio Players for A/B comparison
  final AudioPlayer _dryPlayer = AudioPlayer();
  final AudioPlayer _wetPlayer = AudioPlayer();
  
  bool _isPlayingDry = false;
  bool _isPlayingWet = false;

  PlatformFile? get dryAudioFile => _dryAudioFile;
  Uint8List? get wetAudioBytes => _wetAudioBytes;
  bool get isProcessing => _isProcessing;
  String get processLog => _processLog;
  bool get isPlayingDry => _isPlayingDry;
  bool get isPlayingWet => _isPlayingWet;

  AudioProvider() {
    _dryPlayer.onPlayerStateChanged.listen((state) {
      _isPlayingDry = state == PlayerState.playing;
      notifyListeners();
    });
    _wetPlayer.onPlayerStateChanged.listen((state) {
      _isPlayingWet = state == PlayerState.playing;
      notifyListeners();
    });
  }

  void log(String message) {
    _processLog += "> $message\n";
    notifyListeners();
  }

  Future<void> pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    
    if (result != null) {
      _dryAudioFile = result.files.first;
      log("Loaded DRY Audio: ${_dryAudioFile!.name}");
      // Load into dry player
      if (_dryAudioFile!.bytes != null) {
          await _dryPlayer.setSourceBytes(_dryAudioFile!.bytes!);
      }
      notifyListeners();
    }
  }

  Future<void> runSpiceSimulation(String netlist) async {
    if (_dryAudioFile == null || _dryAudioFile!.bytes == null) {
      log("ERROR: No WAV file selected to process.");
      return;
    }

    _isProcessing = true;
    _wetAudioBytes = null;
    log("Parsing netlist and initializing Ngspice constraints...");
    notifyListeners();

    try {
      var request = http.MultipartRequest('POST', Uri.parse('http://localhost:8000/simulate'));
      request.fields['netlist'] = netlist;
      request.files.add(http.MultipartFile.fromBytes(
        'audio',
        _dryAudioFile!.bytes!,
        filename: _dryAudioFile!.name,
      ));

      log("Uploading ${request.files.first.length} bytes to Python Backend...");
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        log("SUCCESS: Simulation complete. Generated Output WAV.");
        _wetAudioBytes = response.bodyBytes;
        await _wetPlayer.setSourceBytes(_wetAudioBytes!);
      } else {
        log("SPICE ERROR [${response.statusCode}]: ${response.body}");
      }
    } catch (e) {
      log("NETWORK ERROR: Cannot reach backend container. $e");
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void toggleDry() async {
    if (_isPlayingDry) {
      await _dryPlayer.pause();
    } else {
      await _wetPlayer.pause(); // Mute other track for solo A/B
      await _dryPlayer.resume();
    }
  }

  void toggleWet() async {
    if (_wetAudioBytes == null) return;
    
    if (_isPlayingWet) {
      await _wetPlayer.pause();
    } else {
      await _dryPlayer.pause(); // Mute other track for solo A/B
      await _wetPlayer.resume();
    }
  }
}
