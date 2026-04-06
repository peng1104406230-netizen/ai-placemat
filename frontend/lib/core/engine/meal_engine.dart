import '../../models/meal_realtime_snapshot.dart';

class MealEngine {
  MealEngine({
    int maxPicksPerMinute = 8,
  }) : _maxPicksPerMinute = maxPicksPerMinute.clamp(3, 20);

  static const double _stableToleranceGram = 3.0;
  static const Duration _stableWindow = Duration(milliseconds: 800);
  static const double _idlePrepareThresholdGram = 10.0;
  static const Duration _idleToPreparingStableDuration = Duration(seconds: 3);
  static const double _minimumValidPickGram = 2.0;
  static const double _maximumValidPickGram = 200.0;
  static const double _idleChangeToleranceGram = 5.0;
  static const Duration _eatingIdleTimeout = Duration(minutes: 3);
  static const Duration _zeroToIdleDuration = Duration(seconds: 5);
  static const double _zeroWeightThresholdGram = 0.5;

  int _maxPicksPerMinute;
  String _status = 'idle';
  double? _stableCandidateWeight;
  DateTime? _stableCandidateStartedAt;
  double? _lastStableWeight;
  DateTime? _eatingStartedAt;
  DateTime? _zeroWeightStartedAt;
  DateTime? _lastValidPickAt;
  DateTime? _lastMeaningfulWeightChangeAt;
  final List<_PickEvent> _pickEvents = <_PickEvent>[];
  int _reminderCount = 0;
  bool _wasTooFast = false;
  double _totalPickGrams = 0;
  int _totalPickCount = 0;
  double _peakPickFrequency = 0;

  factory MealEngine.basic() {
    return MealEngine();
  }

  int get maxPicksPerMinute => _maxPicksPerMinute;

  void updateMaxPicksPerMinute(int maxPicksPerMinute) {
    _maxPicksPerMinute = maxPicksPerMinute.clamp(3, 20);
  }

  MealRealtimeSnapshot evaluate(double currentWeightGram) {
    final DateTime now = DateTime.now();

    _trackZeroWeight(currentWeightGram, now);
    _updateStableCandidate(currentWeightGram, now);
    _promoteStableCandidateIfNeeded(now);

    final int picksLast60s = _picksInLastMinute(now);
    final double avgPickGrams = _totalPickCount == 0
        ? 0
        : _totalPickGrams / _totalPickCount;
    final double avgPicksPerMinute = _averagePicksPerMinute(now);
    final double peakPickFrequency = _peakPickFrequency;
    final bool isTooFast =
        _status == 'eating' && picksLast60s > _maxPicksPerMinute;

    if (isTooFast && !_wasTooFast) {
      _reminderCount += 1;
    }
    _wasTooFast = isTooFast;

    return MealRealtimeSnapshot(
      status: _status,
      weightGram: currentWeightGram,
      rawWeightGram: currentWeightGram,
      avgSpeed: avgPicksPerMinute,
      peakSpeed: peakPickFrequency,
      isTooFast: isTooFast,
      reminderCount: _reminderCount,
      lastUpdatedAt: now,
      statusNote: _buildStatusNote(
        currentWeightGram: currentWeightGram,
        picksLast60s: picksLast60s,
      ),
      pickCountLast60s: picksLast60s,
      avgPickGrams: avgPickGrams,
      peakPickFrequency: peakPickFrequency,
    );
  }

  void _trackZeroWeight(double currentWeightGram, DateTime now) {
    if (currentWeightGram <= _zeroWeightThresholdGram) {
      _zeroWeightStartedAt ??= now;
      if (_zeroWeightStartedAt != null &&
          now.difference(_zeroWeightStartedAt!) >= _zeroToIdleDuration) {
        _resetMealSession(now);
      }
      return;
    }

    _zeroWeightStartedAt = null;
  }

  void _updateStableCandidate(double currentWeightGram, DateTime now) {
    if (_stableCandidateWeight == null ||
        (currentWeightGram - _stableCandidateWeight!).abs() >
            _stableToleranceGram) {
      _stableCandidateWeight = currentWeightGram;
      _stableCandidateStartedAt = now;
    }
  }

  void _promoteStableCandidateIfNeeded(DateTime now) {
    if (_stableCandidateWeight == null || _stableCandidateStartedAt == null) {
      return;
    }

    final Duration stableDuration =
        now.difference(_stableCandidateStartedAt!);
    final double stableWeight = _stableCandidateWeight!;

    if (_status == 'idle' &&
        stableWeight > _idlePrepareThresholdGram &&
        stableDuration >= _idleToPreparingStableDuration) {
      _status = 'preparing';
      _lastStableWeight = stableWeight;
      _lastMeaningfulWeightChangeAt = now;
      return;
    }

    if (stableDuration < _stableWindow) {
      return;
    }

    if (_lastStableWeight == null ||
        (stableWeight - _lastStableWeight!).abs() > _stableToleranceGram) {
      _onStableWeightChanged(
        previousStableWeight: _lastStableWeight,
        newStableWeight: stableWeight,
        timestamp: now,
      );
      _lastStableWeight = stableWeight;
    }

    _updateIdleByInactivity(now);
  }

  void _onStableWeightChanged({
    required double? previousStableWeight,
    required double newStableWeight,
    required DateTime timestamp,
  }) {
    if (previousStableWeight == null) {
      return;
    }

    final double absoluteChange = (newStableWeight - previousStableWeight).abs();
    if (absoluteChange >= _idleChangeToleranceGram) {
      _lastMeaningfulWeightChangeAt = timestamp;
    }

    if (_status != 'preparing' && _status != 'eating') {
      return;
    }

    final double netDecreaseGram = previousStableWeight - newStableWeight;
    final bool isValidPick =
        netDecreaseGram >= _minimumValidPickGram &&
        netDecreaseGram <= _maximumValidPickGram;

    if (!isValidPick) {
      return;
    }

    _registerValidPick(
      amountGram: netDecreaseGram,
      timestamp: timestamp,
    );

    if (_status == 'preparing') {
      _status = 'eating';
      _eatingStartedAt = timestamp;
    }
  }

  void _registerValidPick({
    required double amountGram,
    required DateTime timestamp,
  }) {
    _pickEvents.add(_PickEvent(timestamp: timestamp, amountGram: amountGram));
    _pickEvents.removeWhere(
      (_PickEvent event) =>
          timestamp.difference(event.timestamp) >
          const Duration(minutes: 10),
    );
    _lastValidPickAt = timestamp;
    _lastMeaningfulWeightChangeAt = timestamp;
    _totalPickCount += 1;
    _totalPickGrams += amountGram;
    final double currentFrequency = _picksInLastMinute(timestamp).toDouble();
    if (currentFrequency > _peakPickFrequency) {
      _peakPickFrequency = currentFrequency;
    }
  }

  void _updateIdleByInactivity(DateTime now) {
    if (_status != 'eating' || _lastValidPickAt == null) {
      return;
    }

    final bool pickTimedOut =
        now.difference(_lastValidPickAt!) >= _eatingIdleTimeout;
    final bool weightStayedQuiet =
        _lastMeaningfulWeightChangeAt != null &&
        now.difference(_lastMeaningfulWeightChangeAt!) >= _eatingIdleTimeout;

    if (pickTimedOut && weightStayedQuiet) {
      _resetMealSession(now);
    }
  }

  int _picksInLastMinute(DateTime now) {
    _pickEvents.removeWhere(
      (_PickEvent event) =>
          now.difference(event.timestamp) > const Duration(seconds: 60),
    );
    return _pickEvents.length;
  }

  double _averagePicksPerMinute(DateTime now) {
    if (_eatingStartedAt == null || _totalPickCount == 0) {
      return 0;
    }

    final double elapsedMinutes =
        now.difference(_eatingStartedAt!).inMilliseconds / 60000;
    if (elapsedMinutes <= 0) {
      return 0;
    }
    return _totalPickCount / elapsedMinutes;
  }

  void _resetMealSession(DateTime now) {
    _status = 'idle';
    _eatingStartedAt = null;
    _zeroWeightStartedAt = null;
    _lastValidPickAt = null;
    _lastMeaningfulWeightChangeAt = null;
    _reminderCount = 0;
    _wasTooFast = false;
    _totalPickGrams = 0;
    _totalPickCount = 0;
    _peakPickFrequency = 0;
    _pickEvents.clear();
    _lastStableWeight = null;
    _stableCandidateWeight = null;
    _stableCandidateStartedAt = now;
  }

  String _buildStatusNote({
    required double currentWeightGram,
    required int picksLast60s,
  }) {
    if (_status == 'idle') {
      return '当前处于 idle。秤重为 ${currentWeightGram.toStringAsFixed(0)}g；重量为 0 持续 5 秒会回到 idle。';
    }

    if (_status == 'preparing') {
      return '当前处于 preparing。重量需稳定在 ${_idlePrepareThresholdGram.toStringAsFixed(0)}g 以上并先等待有效夹菜；有效夹菜要求新稳定值相对前一稳定基线净减少 2-200g。';
    }

    return '当前处于 eating。过去 60 秒有效夹菜 $picksLast60s 次；超过 $_maxPicksPerMinute 次/分钟才会触发提醒。';
  }
}

class _PickEvent {
  const _PickEvent({
    required this.timestamp,
    required this.amountGram,
  });

  final DateTime timestamp;
  final double amountGram;
}
