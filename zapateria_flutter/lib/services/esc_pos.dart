final Map<int, int> _unicodeToCp437 = {
  // Lowercase Spanish
  0x00E1: 0xA0, // á
  0x00E9: 0x82, // é
  0x00ED: 0xA1, // í
  0x00F3: 0xA2, // ó
  0x00FA: 0xA3, // ú
  0x00FC: 0x81, // ü
  0x00F1: 0xA4, // ñ
  // Uppercase Spanish (only those that exist in CP437)
  0x00C9: 0x90, // É
  0x00D1: 0xA5, // Ñ
  0x00DC: 0x9A, // Ü
  // Spanish punctuation
  0x00BF: 0xA8, // ¿
  0x00A1: 0xAD, // ¡
  0x00BA: 0xA7, // º
  0x00AA: 0xA6, // ª
};

final Map<int, int> _accentFallback = {
  0x00C1: 0x41, // Á -> A
  0x00C9: 0x45, // É -> E
  0x00CD: 0x49, // Í -> I
  0x00D3: 0x4F, // Ó -> O
  0x00DA: 0x55, // Ú -> U
  0x00DC: 0x55, // Ü -> U
  0x00C7: 0x43, // Ç -> C
  0x00D1: 0x4E, // Ñ -> N
  0x00E1: 0x61, // á -> a
  0x00E9: 0x65, // é -> e
  0x00ED: 0x69, // í -> i
  0x00F3: 0x6F, // ó -> o
  0x00FA: 0x75, // ú -> u
  0x00FC: 0x75, // ü -> u
  0x00F1: 0x6E, // ñ -> n
  0x00C7: 0x43, // Ç -> C
  0x00E7: 0x63, // ç -> c
};

List<int> _encode(String s) {
  final out = <int>[];
  for (final code in s.codeUnits) {
    if (code < 128) {
      out.add(code);
    } else {
      out.add(_unicodeToCp437[code] ?? _accentFallback[code] ?? 0x3F);
    }
  }
  return out;
}

class EscPos {
  EscPos._();

  static const int alignLeft = 0;
  static const int alignCenter = 1;
  static const int alignRight = 2;

  static List<int> init80() => [
        0x1B, 0x40, // ESC @
        0x1D, 0x57, 0x40, 0x02, // GS W 64 2 (576 dots = 80mm)
        0x1B, 0x74, 0x00, // ESC t 0 (CP437)
      ];

  static List<int> setAlign(int a) => [0x1B, 0x61, a & 0xFF];

  static List<int> setBold(bool on) => [0x1B, 0x45, on ? 1 : 0];

  static List<int> setCharSize(int w, int h) =>
      [0x1D, 0x21, _sizeCode(w, h)];

  static List<int> feed(int lines) => [0x1B, 0x64, lines & 0xFF];

  static List<int> cut() => [0x1D, 0x56, 0x00];

  static List<int> text(String s) => _encode(s);

  static List<int> textLine(String s) => [..._encode(s), 0x0A];

  static List<int> barcode(String data) {
    final bytes = _encode(data);
    return [
      0x1D, 0x77, 0x02,       // GS w 2 (module width)
      0x1D, 0x68, 0x64,       // GS h 100 (height)
      0x1D, 0x66, 0x00,       // GS f 0 (HRI font)
      0x1D, 0x48, 0x02,       // GS H 2 (HRI below)
      0x1D, 0x6B, 0x49,       // GS k 73 (CODE128)
      bytes.length & 0xFF,    // data length
      ...bytes,
    ];
  }

  static int _sizeCode(int w, int h) {
    const widths = [0x00, 0x10, 0x20, 0x30, 0x40, 0x50, 0x60, 0x70];
    const heights = [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07];
    return widths[w.clamp(0, 7)] + heights[h.clamp(0, 7)];
  }
}
