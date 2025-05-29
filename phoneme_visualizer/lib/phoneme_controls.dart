import 'package:flutter/material.dart';

class PhonemeControls extends StatelessWidget {
  final String audioFormat;
  final double chunkLength;
  final double energyThresh;
  final double fThresh;
  final double sfmThresh;
  final bool isRecording;
  final bool isRecorderInitialized;
  final TextEditingController chunkLengthController;
  final TextEditingController energyThreshController;
  final TextEditingController fThreshController;
  final TextEditingController sfmThreshController;
  final ValueChanged<String> onFormatChanged;
  final ValueChanged<double> onChunkLengthChanged;
  final ValueChanged<double> onEnergyThreshChanged;
  final ValueChanged<double> onFThreshChanged;
  final ValueChanged<double> onSfmThreshChanged;
  final VoidCallback onRecordPressed;
  final Widget Function({
    required String label,
    required double value,
    required double min,
    required double max,
    required double divisions,
    required TextEditingController controller,
    required void Function(double) onChanged,
    int decimals,
  }) buildSliderWithField;

  const PhonemeControls({
    super.key,
    required this.audioFormat,
    required this.chunkLength,
    required this.energyThresh,
    required this.fThresh,
    required this.sfmThresh,
    required this.isRecording,
    required this.isRecorderInitialized,
    required this.chunkLengthController,
    required this.energyThreshController,
    required this.fThreshController,
    required this.sfmThreshController,
    required this.onFormatChanged,
    required this.onChunkLengthChanged,
    required this.onEnergyThreshChanged,
    required this.onFThreshChanged,
    required this.onSfmThreshChanged,
    required this.onRecordPressed,
    required this.buildSliderWithField,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Audio Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Format:'),
            const SizedBox(width: 16),
            DropdownButton<String>(
              value: audioFormat,
              items: const [
                DropdownMenuItem(value: 'wav', child: Text('WAV')),
                DropdownMenuItem(value: 'ogg', child: Text('OGG')),
              ],
              onChanged: (v) { if (v != null) onFormatChanged(v); },
            ),
          ],
        ),
        const SizedBox(height: 16),
        buildSliderWithField(
          label: 'Chunk (ms)',
          value: chunkLength,
          min: 100,
          max: 2000,
          divisions: 38,
          controller: chunkLengthController,
          onChanged: onChunkLengthChanged,
          decimals: 0,
        ),
        const SizedBox(height: 32),
        const Text('Tweak Variables', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        buildSliderWithField(
          label: 'energy_thresh',
          value: energyThresh,
          min: 0.0,
          max: 1.0,
          divisions: 100,
          controller: energyThreshController,
          onChanged: onEnergyThreshChanged,
        ),
        buildSliderWithField(
          label: 'f_thresh',
          value: fThresh,
          min: 0.0,
          max: 1000.0,
          divisions: 1000,
          controller: fThreshController,
          onChanged: onFThreshChanged,
        ),
        buildSliderWithField(
          label: 'sfm_thresh',
          value: sfmThresh,
          min: 0.0,
          max: 1.0,
          divisions: 100,
          controller: sfmThreshController,
          onChanged: onSfmThreshChanged,
        ),
        const SizedBox(height: 32),
        Center(
          child: ElevatedButton.icon(
            icon: Icon(isRecording ? Icons.stop : Icons.mic),
            label: Text(isRecording ? 'Stop' : 'Record'),
            onPressed: !isRecorderInitialized ? null : onRecordPressed,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }
} 