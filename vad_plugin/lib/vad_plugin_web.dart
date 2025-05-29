import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'vad_plugin_platform_interface.dart';

class VADPluginWeb extends VADPluginPlatform {
  static void registerWith(Registrar registrar) {
    VADPluginPlatform.instance = VADPluginWeb();
  }

  @override
  Future<void> initVAD({
    required int sampleRate,
    required double energyThresh,
    required double fThresh,
    required double sfmThresh,
  }) async {
    // No initialization needed
    print('VAD initialized (always active)');
  }

  @override
  Future<List<int>> detectVoice(List<double> audioData) async {
    // Return all 1s (voice active) for the number of frames
    // Assuming 10ms frames at 16kHz, each frame is 160 samples
    final numFrames = (audioData.length / 160).ceil();
    return List.filled(numFrames, 1);
  }
} 