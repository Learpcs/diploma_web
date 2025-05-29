import 'package:flutter/material.dart';

class PhonemeSequence extends StatelessWidget {
  final List<String> phonemes;
  final String mode; // 'IPA' or 'ARPABET'
  final bool isRecording;
  final double recordingProgress; // 0.0 to 1.0
  final VoidCallback onClear;

  const PhonemeSequence({
    super.key,
    required this.phonemes,
    required this.isRecording,
    required this.recordingProgress,
    required this.onClear,
    this.mode = 'ARPABET',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Phoneme Log',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.clear_all),
                onPressed: onClear,
                tooltip: 'Clear Phoneme Log',
              ),
            ],
          ),
          if (isRecording) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: recordingProgress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 4),
            Text(
              'Recording: ${(recordingProgress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: phonemes.length,
              itemBuilder: (context, index) {
                // Group phonemes by 10 for better readability
                if (index % 10 == 0) {
                  final endIndex = (index + 10 < phonemes.length) ? index + 10 : phonemes.length;
                  final phonemeGroup = phonemes.sublist(index, endIndex);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        ...phonemeGroup.map((phoneme) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            phoneme,
                            style: const TextStyle(fontSize: 18),
                          ),
                        )).toList(),
                        if (endIndex == phonemes.length) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              mode,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
} 