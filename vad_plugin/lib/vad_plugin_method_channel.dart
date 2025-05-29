import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'vad_plugin_platform_interface.dart';

/// An implementation of [VadPluginPlatform] that uses method channels.
class MethodChannelVadPlugin extends VadPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('vad_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
