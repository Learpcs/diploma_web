import 'package:flutter_test/flutter_test.dart';
import 'package:vad_plugin/vad_plugin.dart';
import 'package:vad_plugin/vad_plugin_platform_interface.dart';
import 'package:vad_plugin/vad_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockVadPluginPlatform
    with MockPlatformInterfaceMixin
    implements VadPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final VadPluginPlatform initialPlatform = VadPluginPlatform.instance;

  test('$MethodChannelVadPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelVadPlugin>());
  });

  test('getPlatformVersion', () async {
    VadPlugin vadPlugin = VadPlugin();
    MockVadPluginPlatform fakePlatform = MockVadPluginPlatform();
    VadPluginPlatform.instance = fakePlatform;

    expect(await vadPlugin.getPlatformVersion(), '42');
  });
}
