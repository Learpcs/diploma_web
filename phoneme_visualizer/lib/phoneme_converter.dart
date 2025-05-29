class PhonemeConverter {
  static final Map<String, String> arpabetToIpa = {
    'AA': 'ɑ', 'AE': 'æ', 'AH': 'ʌ', 'AO': 'ɔ', 'AW': 'aʊ', 'AY': 'aɪ',
    'B': 'b', 'CH': 'tʃ', 'D': 'd', 'DH': 'ð', 'EH': 'ɛ', 'ER': 'ɝ',
    'EY': 'eɪ', 'F': 'f', 'G': 'g', 'HH': 'h', 'IH': 'ɪ', 'IY': 'i',
    'JH': 'dʒ', 'K': 'k', 'L': 'l', 'M': 'm', 'N': 'n', 'NG': 'ŋ',
    'OW': 'oʊ', 'OY': 'ɔɪ', 'P': 'p', 'R': 'r', 'S': 's', 'SH': 'ʃ',
    'T': 't', 'TH': 'θ', 'UH': 'ʊ', 'UW': 'u', 'V': 'v', 'W': 'w',
    'Y': 'j', 'Z': 'z', 'ZH': 'ʒ'
  };

  static final Map<String, String> ipaToArpabet = {
    'ɑ': 'AA', 'æ': 'AE', 'ʌ': 'AH', 'ɔ': 'AO', 'aʊ': 'AW', 'aɪ': 'AY',
    'b': 'B', 'tʃ': 'CH', 'd': 'D', 'ð': 'DH', 'ɛ': 'EH', 'ɝ': 'ER',
    'eɪ': 'EY', 'f': 'F', 'g': 'G', 'h': 'HH', 'ɪ': 'IH', 'i': 'IY',
    'dʒ': 'JH', 'k': 'K', 'l': 'L', 'm': 'M', 'n': 'N', 'ŋ': 'NG',
    'oʊ': 'OW', 'ɔɪ': 'OY', 'p': 'P', 'r': 'R', 's': 'S', 'ʃ': 'SH',
    't': 'T', 'θ': 'TH', 'ʊ': 'UH', 'u': 'UW', 'v': 'V', 'w': 'W',
    'j': 'Y', 'z': 'Z', 'ʒ': 'ZH'
  };

  // Map of phoneme IDs to ARPABET symbols
  static final Map<String, String> idToArpabet = {
    '0': 'AA', '1': 'AE', '2': 'AH', '3': 'AO', '4': 'AW', '5': 'AY',
    '6': 'B', '7': 'CH', '8': 'D', '9': 'DH', '10': 'EH', '11': 'ER',
    '12': 'EY', '13': 'F', '14': 'G', '15': 'HH', '16': 'IH', '17': 'IY',
    '18': 'JH', '19': 'K', '20': 'L', '21': 'M', '22': 'N', '23': 'NG',
    '24': 'OW', '25': 'OY', '26': 'P', '27': 'R', '28': 'S', '29': 'SH',
    '30': 'T', '31': 'TH', '32': 'UH', '33': 'UW', '34': 'V', '35': 'W',
    '36': 'Y', '37': 'Z', '38': 'ZH'
  };

  static List<String> convertPhonemes(List<String> phonemes, String targetMode) {
    if (targetMode == 'ID') {
      // Convert from any format to ID
      return phonemes.map((p) {
        // If it's already an ID, return as is
        if (idToArpabet.values.contains(p)) {
          return idToArpabet.entries.firstWhere((e) => e.value == p).key;
        }
        // If it's IPA, convert to ARPABET first
        if (ipaToArpabet.containsKey(p)) {
          final arpabet = ipaToArpabet[p]!;
          return idToArpabet.entries.firstWhere((e) => e.value == arpabet).key;
        }
        // If it's already an ID number, return as is
        return p;
      }).toList();
    } else if (targetMode == 'ARPABET') {
      // Convert from any format to ARPABET
      return phonemes.map((p) {
        // If it's an ID, convert to ARPABET
        if (idToArpabet.containsKey(p)) {
          return idToArpabet[p]!;
        }
        // If it's IPA, convert to ARPABET
        if (ipaToArpabet.containsKey(p)) {
          return ipaToArpabet[p]!;
        }
        // If it's already ARPABET, return as is
        return p;
      }).toList();
    } else if (targetMode == 'IPA') {
      // Convert from any format to IPA
      return phonemes.map((p) {
        // If it's an ID, convert to ARPABET then to IPA
        if (idToArpabet.containsKey(p)) {
          final arpabet = idToArpabet[p]!;
          return arpabetToIpa[arpabet] ?? p;
        }
        // If it's ARPABET, convert to IPA
        if (arpabetToIpa.containsKey(p)) {
          return arpabetToIpa[p]!;
        }
        // If it's already IPA, return as is
        return p;
      }).toList();
    }
    return phonemes; // Return unchanged if mode is not recognized
  }
} 