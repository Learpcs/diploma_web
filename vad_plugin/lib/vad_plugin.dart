import 'vad_plugin_platform_interface.dart';

class VADPlugin {
  static Future<void> initVAD({
    required int sampleRate,
    required double energyThresh,
    required double fThresh,
    required double sfmThresh,
  }) async {
    await VADPluginPlatform.instance.initVAD(
      sampleRate: sampleRate,
      energyThresh: energyThresh,
      fThresh: fThresh,
      sfmThresh: sfmThresh,
    );
  }

  static Future<List<int>> detectVoice(List<double> audioData) async {
    return await VADPluginPlatform.instance.detectVoice(audioData);
  }
} 