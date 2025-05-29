import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'phoneme_sequence.dart';
import 'phoneme_controls.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'file_helper.dart';
import 'phoneme_converter.dart';
import 'package:vad_plugin/vad_plugin.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';

void main() {
  runApp(const PhonemeVisualizerApp());
}

class PhonemeSequence {
  final List<int> phonemeIds;

  PhonemeSequence({required this.phonemeIds});

  factory PhonemeSequence.fromJson(String jsonStr) {
    try {
      final match = RegExp(r'"phoneme_sequence"\s*:\s*\[(.*?)\]').firstMatch(jsonStr);
      if (match != null) {
        final phonemeIds = match.group(1)?.split(',').map((id) => int.parse(id.trim())).toList() ?? [];
        return PhonemeSequence(phonemeIds: phonemeIds);
      }
    } catch (e) {
      print('Error parsing phoneme sequence: $e');
    }
    return PhonemeSequence(phonemeIds: []);
  }
}

class PhonemeVisualizerApp extends StatelessWidget {
  const PhonemeVisualizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phoneme Visualizer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PhonemeVisualizerPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PhonemeVisualizerPage extends StatefulWidget {
  const PhonemeVisualizerPage({super.key});

  @override
  State<PhonemeVisualizerPage> createState() => _PhonemeVisualizerPageState();
}

class _PhonemeVisualizerPageState extends State<PhonemeVisualizerPage> {
  final List<String> _phonemes = [];
  double _chunkLength = 1000; // ms
  double _energyThresh = 0.15;
  double _fThresh = 200.0;
  double _sfmThresh = 0.30;
  double _multiplier = 1.0; // New multiplier value
  String _currentMode = 'ARPABET'; // 'ARPABET' or 'IPA'
  bool _showSettings = true; // Toggle for settings panel
  double _recordingProgress = 0.0;
  Timer? _progressTimer;
  DateTime? _chunkStartTime;

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  Timer? _chunkTimer;
  bool _isSending = false;
  bool _isVoiceDetected = false;

  final TextEditingController _chunkLengthController = TextEditingController();
  final TextEditingController _energyThreshController = TextEditingController();
  final TextEditingController _fThreshController = TextEditingController();
  final TextEditingController _sfmThreshController = TextEditingController();
  final TextEditingController _multiplierController = TextEditingController();

  String _recordingPath = 'audio.wav';

  @override
  void initState() {
    super.initState();
    // Set more sensitive initial thresholds
    _energyThresh = 0.15;  // Lower energy threshold
    _fThresh = 200.0;      // Lower frequency threshold
    _sfmThresh = 0.30;     // Lower spectral flatness threshold
    
    _chunkLengthController.text = _chunkLength.toStringAsFixed(0);
    _energyThreshController.text = _energyThresh.toStringAsFixed(2);
    _fThreshController.text = _fThresh.toStringAsFixed(2);
    _sfmThreshController.text = _sfmThresh.toStringAsFixed(2);
    _multiplierController.text = _multiplier.toStringAsFixed(2);
    _initRecorder();
    _initVAD();
  }

  Future<void> _initRecorder() async {
    final isAvailable = await _recorder.hasPermission();
    setState(() {
      _isRecorderInitialized = isAvailable;
    });
  }

  Future<void> _initVAD() async {
    try {
      print('Initializing VAD with parameters:');
      print('  sampleRate: 16000');
      print('  energyThresh: $_energyThresh');
      print('  fThresh: $_fThresh');
      print('  sfmThresh: $_sfmThresh');
      
      await VADPlugin.initVAD(
        sampleRate: 16000,
        energyThresh: _energyThresh,
        fThresh: _fThresh,
        sfmThresh: _sfmThresh,
      );
      print('VAD initialized successfully');
    } catch (e) {
      print('Error initializing VAD: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing VAD: $e')),
      );
    }
  }

  @override
  void dispose() {
    _chunkLengthController.dispose();
    _energyThreshController.dispose();
    _fThreshController.dispose();
    _sfmThreshController.dispose();
    _multiplierController.dispose();
    _chunkTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) return;
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission denied')));
      return;
    }

    setState(() {
      _isRecording = true;
      _recordingProgress = 0.0;
      _chunkStartTime = DateTime.now();
      _isVoiceDetected = true;
    });

    print('Starting recording...');
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        numChannels: 1,
        sampleRate: 16000,
        bitRate: 128000,
      ),
      path: _recordingPath,
    );
    print('Recording started successfully');

    // Start progress timer
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_chunkStartTime != null) {
        final elapsed = DateTime.now().difference(_chunkStartTime!).inMilliseconds;
        final progress = (elapsed / _chunkLength).clamp(0.0, 1.0);
        setState(() {
          _recordingProgress = progress;
        });
      }
    });

    // Start periodic chunk sending
    _chunkTimer = Timer.periodic(Duration(milliseconds: _chunkLength.toInt()), (_) async {
      if (_isRecording) {
        print('Chunk timer triggered - processing audio chunk');
        try {
          // Stop the current recording
          final path = await _recorder.stop();
          print('Recording stopped, got path: $path');

          if (path != null) {
            print('Sending audio chunk from path: $path');
            
            // For web, fetch the blob data
            if (kIsWeb) {
              try {
                final response = await http.get(Uri.parse(path));
                if (response.statusCode == 200) {
                  final bytes = response.bodyBytes;
                  print('Read ${bytes.length} bytes from blob');
                  
                  if (bytes.length > 44) {  // Only send if we have actual audio data
                    await _sendAudioChunk(force: true, bytesOverride: bytes);
                  } else {
                    print('Chunk too small, skipping');
                  }
                } else {
                  print('Failed to fetch blob data: ${response.statusCode}');
                }
              } catch (e) {
                print('Error fetching blob data: $e');
              }
            } else {
              // For non-web platforms
              final bytes = await File(path).readAsBytes();
              print('Read ${bytes.length} bytes from file');
              
              if (bytes.length > 44) {
                await _sendAudioChunk(force: true, bytesOverride: bytes);
              } else {
                print('Chunk too small, skipping');
              }
            }
          } else {
            print('No path received from recorder stop()');
          }

          // Start a new recording
          print('Starting new recording...');
          await _recorder.start(
            const RecordConfig(
              encoder: AudioEncoder.wav,
              numChannels: 1,
              sampleRate: 16000,
              bitRate: 128000,
            ),
            path: _recordingPath,
          );
          print('New recording started successfully');
        } catch (e) {
          print('Error in chunk processing: $e');
        }
        _chunkStartTime = DateTime.now(); // Reset chunk start time
      }
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecorderInitialized) return;
    final path = await _recorder.stop();
    _chunkTimer?.cancel();
    _progressTimer?.cancel();
    setState(() {
      _isRecording = false;
      _recordingProgress = 0.0;
      _chunkStartTime = null;
    });
    if (path != null) {
      await _sendAudioChunk(force: true, pathOverride: path);
    }
  }

  Future<Uint8List?> _readRecordingBytes(String path) async {
    try {
      if (kIsWeb) {
        // On web, path is a blob URL, so fetch it
        final response = await http.get(Uri.parse(path));
        return response.bodyBytes;
      } else {
        // On mobile/desktop, use helper
        return await readFileBytes(path);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _sendAudioChunk({bool force = false, Uint8List? bytesOverride, String? pathOverride}) async {
    if (_isSending && !force) {
      print('Already sending, skipping...');
      return;
    }

    setState(() { 
      _isSending = true;
      _isVoiceDetected = true;
    });

    try {
      Uint8List bytes;
      if (bytesOverride != null) {
        print('Using provided bytes override');
        bytes = bytesOverride;
      } else if (pathOverride != null) {
        print('Reading bytes from path: $pathOverride');
        bytes = await File(pathOverride).readAsBytes();
      } else {
        print('No audio data available');
        setState(() { _isSending = false; });
        return;
      }

      print('Audio data size: ${bytes.length} bytes');

      // Skip if audio data is too small (just a header)
      if (bytes.length <= 44) {  // WAV header is 44 bytes
        print('Audio data too small (only header): ${bytes.length} bytes');
        setState(() { _isSending = false; });
        return;
      }

      // Convert audio data to float32 list
      final audioData = bytes.buffer.asFloat32List();
      print('Audio data length: ${audioData.length} samples');

      // Always send to server for phoneme detection
      print('Sending audio to server for phoneme detection...');
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:8000/phoneme-sequence'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'audio.wav',
          contentType: MediaType('audio', 'wav'),
        ),
      );

      print('Sending request to server...');
      final response = await request.send();
      print('Received response from server: ${response.statusCode}');
      
      final responseBody = await response.stream.bytesToString();
      print('Response body: $responseBody');

      if (response.statusCode == 200) {
        final phonemeSequence = PhonemeSequence.fromJson(responseBody);
        if (phonemeSequence.phonemeIds.isNotEmpty) {
          setState(() {
            // Convert the new phoneme IDs to the current display mode
            final newPhonemes = phonemeSequence.phonemeIds
                .map((id) => id.toString())
                .toList();
            final convertedPhonemes = PhonemeConverter.convertPhonemes(newPhonemes, _currentMode);
            _phonemes.addAll(convertedPhonemes);
          });
          print('Received phoneme sequence: ${phonemeSequence.phonemeIds}');
          print('Converted to $_currentMode: ${_phonemes.sublist(_phonemes.length - phonemeSequence.phonemeIds.length)}');
        } else {
          print('Received empty phoneme sequence');
        }
      } else {
        print('Error from server: ${response.statusCode} - $responseBody');
      }
    } catch (e, stackTrace) {
      print('Error processing audio: $e');
      print('Stack trace: $stackTrace');
    } finally {
      setState(() { _isSending = false; });
    }
  }

  Future<void> _pickAndSendAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
        withData: kIsWeb, // Required for web
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        Uint8List? bytes;
        
        if (kIsWeb) {
          bytes = file.bytes;
        } else if (file.path != null) {
          bytes = await File(file.path!).readAsBytes();
        }

        if (bytes != null) {
          await _sendAudioChunk(force: true, bytesOverride: bytes);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  void _toggleMode() {
    setState(() {
      // Cycle through modes: ID → ARPABET → IPA → ID
      switch (_currentMode) {
        case 'ID':
          _currentMode = 'ARPABET';
          break;
        case 'ARPABET':
          _currentMode = 'IPA';
          break;
        case 'IPA':
          _currentMode = 'ID';
          break;
        default:
          _currentMode = 'ID';
      }
      
      // Convert existing phonemes to the new mode
      final convertedPhonemes = PhonemeConverter.convertPhonemes(_phonemes, _currentMode);
      _phonemes.clear();
      _phonemes.addAll(convertedPhonemes);
    });
  }

  void _clearPhonemes() {
    setState(() {
      _phonemes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phoneme Visualizer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _pickAndSendAudioFile,
            tooltip: 'Attach Audio File',
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: _toggleMode,
            tooltip: 'Toggle Mode',
          ),
          IconButton(
            icon: Icon(_showSettings ? Icons.settings : Icons.settings_outlined),
            onPressed: () => setState(() => _showSettings = !_showSettings),
            tooltip: 'Toggle Settings',
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isVoiceDetected ? Icons.mic : Icons.mic_off,
                        color: _isVoiceDetected ? Colors.green : Colors.red,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isVoiceDetected ? 'Voice Detected' : 'No Voice',
                        style: TextStyle(
                          color: _isVoiceDetected ? Colors.green : Colors.red,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PhonemeVisualizer(
                    phonemes: _phonemes,
                    mode: _currentMode,
                    isRecording: _isRecording,
                    recordingProgress: _recordingProgress,
                    onClear: _clearPhonemes,
                  ),
                ),
              ],
            ),
          ),
          if (_showSettings)
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSliderWithField(
                        label: 'Multiplier',
                        value: _multiplier,
                        min: 0.1,
                        max: 5.0,
                        divisions: 49,
                        controller: _multiplierController,
                        onChanged: _updateMultiplier,
                        decimals: 2,
                      ),
                      const SizedBox(height: 16),
                      PhonemeControls(
                        audioFormat: 'wav',
                        chunkLength: _chunkLength,
                        energyThresh: _energyThresh,
                        fThresh: _fThresh,
                        sfmThresh: _sfmThresh,
                        isRecording: _isRecording,
                        isRecorderInitialized: _isRecorderInitialized,
                        chunkLengthController: _chunkLengthController,
                        energyThreshController: _energyThreshController,
                        fThreshController: _fThreshController,
                        sfmThreshController: _sfmThreshController,
                        onFormatChanged: (_) {},
                        onChunkLengthChanged: (v) => setState(() => _chunkLength = v),
                        onEnergyThreshChanged: (v) async {
                          setState(() => _energyThresh = v);
                          await _initVAD();
                        },
                        onFThreshChanged: (v) async {
                          setState(() => _fThresh = v);
                          await _initVAD();
                        },
                        onSfmThreshChanged: (v) async {
                          setState(() => _sfmThresh = v);
                          await _initVAD();
                        },
                        onRecordPressed: !_isRecorderInitialized
                            ? () {}
                            : _isRecording
                                ? () { _stopRecording(); }
                                : () { _startRecording(); },
                        buildSliderWithField: _buildSliderWithField,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliderWithField({
    required String label,
    required double value,
    required double min,
    required double max,
    required double divisions,
    required TextEditingController controller,
    required void Function(double) onChanged,
    int decimals = 2,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions.toInt(),
                label: value.toStringAsFixed(decimals),
                onChanged: (v) {
                  onChanged(v);
                  controller.text = v.toStringAsFixed(decimals);
                },
              ),
            ),
            SizedBox(
              width: 70,
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: label,
                  isDense: true,
                ),
                onSubmitted: (_) => _updateSliderFromText(controller, onChanged, min, max),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _updateSliderFromText(TextEditingController controller, void Function(double) onChanged, double min, double max) {
    final value = double.tryParse(controller.text);
    if (value != null && value >= min && value <= max) {
      onChanged(value);
    }
  }

  void _updateMultiplier(double value) {
    setState(() {
      _multiplier = value;
      _multiplierController.text = value.toStringAsFixed(2);
      
      // Update all threshold values based on multiplier
      _energyThresh = 0.15 * value;
      _fThresh = 200.0 * value;
      _sfmThresh = 0.30 * value;
      
      // Update controller texts
      _energyThreshController.text = _energyThresh.toStringAsFixed(2);
      _fThreshController.text = _fThresh.toStringAsFixed(2);
      _sfmThreshController.text = _sfmThresh.toStringAsFixed(2);
    });
    
    // Reinitialize VAD with new threshold values
    _initVAD();
  }
}

class PhonemeVisualizer extends StatelessWidget {
  final List<String> phonemes;
  final String mode;
  final bool isRecording;
  final double recordingProgress;
  final VoidCallback onClear;

  const PhonemeVisualizer({
    super.key,
    required this.phonemes,
    required this.mode,
    required this.isRecording,
    required this.recordingProgress,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Phonemes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClear,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: phonemes.map((phoneme) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            phoneme,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isRecording)
          LinearProgressIndicator(
            value: recordingProgress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
      ],
    );
  }
}
