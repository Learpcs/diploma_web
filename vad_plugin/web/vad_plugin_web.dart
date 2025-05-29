import 'dart:async';
import 'dart:js_util';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:vad_plugin/vad_plugin.dart';
import 'package:js/js.dart';

@JS('VAD')
class VADJS {
  external VADJS(int sampleRate, double energyThresh, double fThresh, double sfmThresh);
  external List<int> detectVoice(List<double> audioData);
}

@JS()
@anonymous
class VADModule {
  external VADJS VAD(int sampleRate, double energyThresh, double fThresh, double sfmThresh);
}

class VADPluginWeb extends VADPluginPlatform {
  static VADModule? _vadModule;
  static VADJS? _vad;

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
    if (_vadModule == null) {
      // Load the WASM module
      final module = await promiseToFuture<dynamic>(
        callMethod(globalThis, 'import', ['assets/vad_wasm.js'])
      );
      _vadModule = module as VADModule;
    }

    // Initialize VAD with parameters
    _vad = _vadModule!.VAD(sampleRate, energyThresh, fThresh, sfmThresh);
  }

  @override
  Future<List<int>> detectVoice(List<double> audioData) async {
    if (_vad == null) {
      throw StateError('VAD not initialized. Call initVAD first.');
    }
    return _vad!.detectVoice(audioData);
  }
} 