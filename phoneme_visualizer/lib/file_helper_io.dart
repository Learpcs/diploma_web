import 'dart:typed_data';
import 'dart:io';

Future<Uint8List> readFileBytes(String path) async {
  return await File(path).readAsBytes();
} 