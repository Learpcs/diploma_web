import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class VADPluginPlatform extends PlatformInterface {
  /// Constructs a VADPluginPlatform.
  VADPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static VADPluginPlatform _instance = VADPluginPlatform();

  /// The default instance of [VADPluginPlatform] to use.
  ///
  /// Defaults to [VADPluginPlatform].
  static VADPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VADPluginPlatform] when
  /// they register themselves.
  static set instance(VADPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> initVAD({
    required int sampleRate,
    required double energyThresh,
    required double fThresh,
    required double sfmThresh,
  }) {
    throw UnimplementedError('initVAD() has not been implemented.');
  }

  Future<List<int>> detectVoice(List<double> audioData) {
    throw UnimplementedError('detectVoice() has not been implemented.');
  }
}
