class ParserReading {
  const ParserReading({
    required this.offset,
    required this.width,
    required this.rawBytes,
    required this.rawValue,
    required this.weightGram,
    required this.label,
  });

  final int offset;
  final int width;
  final List<int> rawBytes;
  final int rawValue;
  final double weightGram;
  final String label;

  String get rawHex => rawBytes
      .map((int byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
}

class ParsedWeightResult {
  const ParsedWeightResult({
    required this.parserStrategy,
    required this.weightGram,
    required this.confidence,
    required this.notes,
    required this.readings,
  });

  final String parserStrategy;
  final double? weightGram;
  final double confidence;
  final String notes;
  final List<ParserReading> readings;
}

class ManufacturerDataParser {
  const ManufacturerDataParser();

  static const String strategyName = 'bhManufacturerData';
  static const int _weightOffset = 8;
  static const int _weightWidth = 2;

  factory ManufacturerDataParser.bh() {
    return const ManufacturerDataParser();
  }

  ParsedWeightResult parse(List<int> manufacturerData) {
    if (manufacturerData.length < _weightOffset + _weightWidth) {
      return const ParsedWeightResult(
        parserStrategy: strategyName,
        weightGram: null,
        confidence: 0,
        notes: '当前 manufacturer data 长度不足，无法解析 BH 重量。',
        readings: <ParserReading>[],
      );
    }

    final List<int> rawBytes = manufacturerData.sublist(
      _weightOffset,
      _weightOffset + _weightWidth,
    );
    final int rawValue = (rawBytes[0] << 8) | rawBytes[1];
    final double weightGram = rawValue.toDouble();

    return ParsedWeightResult(
      parserStrategy: strategyName,
      weightGram: weightGram,
      confidence: 0.98,
      notes: 'BH 重量已按 manufacturer data bytes[8..9] 正式解析。',
      readings: <ParserReading>[
        ParserReading(
          offset: _weightOffset,
          width: _weightWidth,
          rawBytes: rawBytes,
          rawValue: rawValue,
          weightGram: weightGram,
          label: 'BH manufacturer bytes[8..9]',
        ),
      ],
    );
  }
}
