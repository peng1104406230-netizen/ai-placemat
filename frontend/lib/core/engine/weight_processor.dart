class StableWeightSample {
  const StableWeightSample({
    required this.grams,
    required this.stabilityNote,
  });

  final double grams;
  final String stabilityNote;
}

class WeightProcessor {
  WeightProcessor();

  final List<double> _recentWeights = <double>[];

  factory WeightProcessor.basic() {
    return WeightProcessor();
  }

  StableWeightSample process(double? rawWeightGram) {
    if (rawWeightGram == null) {
      return const StableWeightSample(
        grams: 0,
        stabilityNote: '暂无可解析重量，等待下一帧 manufacturer data。',
      );
    }

    if (rawWeightGram <= 0.5) {
      _recentWeights
        ..clear()
        ..add(0);
      return const StableWeightSample(
        grams: 0,
        stabilityNote: '当前空载，已重置 5 点平滑窗口。',
      );
    }

    _recentWeights.add(rawWeightGram);
    if (_recentWeights.length > 5) {
      _recentWeights.removeAt(0);
    }

    final double smoothedWeight =
        _recentWeights.reduce((double a, double b) => a + b) /
        _recentWeights.length;
    final double spread =
        _recentWeights.reduce((double a, double b) => a > b ? a : b) -
        _recentWeights.reduce((double a, double b) => a < b ? a : b);

    return StableWeightSample(
      grams: smoothedWeight,
      stabilityNote:
          spread <= 3 ? '重量流相对稳定，已做 5 点平滑。' : '重量波动较大，当前仍在做平滑处理。',
    );
  }
}
