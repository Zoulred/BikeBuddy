import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class RideTimerService {
  static const _kStartKey = 'ride_start_ts';
  static const _kAccumKey = 'ride_accum_ms';

  RideTimerService._internal();
  static final RideTimerService instance = RideTimerService._internal();

  SharedPreferences? _prefs;
  Timer? _ticker;

  int? _startTs; // milliseconds since epoch when running
  int _accumMs = 0; // accumulated milliseconds when paused

  late final StreamController<Duration> _elapsedController =
      StreamController<Duration>.broadcast(
        onListen: _ensureTicker,
        onCancel: _maybeStopTicker,
      );

  Stream<Duration> get elapsedStream => _elapsedController.stream;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _startTs = _prefs!.getInt(_kStartKey);
    _accumMs = _prefs!.getInt(_kAccumKey) ?? 0;
    _ensureTicker();
    _pushElapsed();
  }

  void _ensureTicker() {
    _ticker ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => _pushElapsed(),
    );
  }

  void _maybeStopTicker() {
    // If there are no listeners and the timer is not running, stop the ticker.
    if (!_elapsedController.hasListener && !isRunning) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _pushElapsed() {
    final elapsed = getElapsed();
    if (!_elapsedController.isClosed && _elapsedController.hasListener) {
      _elapsedController.add(elapsed);
    }
  }

  Duration getElapsed() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (_startTs != null) {
      return Duration(milliseconds: _accumMs + (nowMs - _startTs!));
    }
    return Duration(milliseconds: _accumMs);
  }

  bool get isRunning => _startTs != null;

  Future<void> start() async {
    if (isRunning) return;
    _startTs = DateTime.now().millisecondsSinceEpoch;
    await _prefs?.setInt(_kStartKey, _startTs!);
    _ensureTicker();
    _pushElapsed();
  }

  Future<void> pause() async {
    if (!isRunning) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _accumMs += (nowMs - (_startTs ?? nowMs));
    _startTs = null;
    await _prefs?.remove(_kStartKey);
    await _prefs?.setInt(_kAccumKey, _accumMs);
    _pushElapsed();
  }

  Future<void> stop() async {
    _startTs = null;
    _accumMs = 0;
    await _prefs?.remove(_kStartKey);
    await _prefs?.remove(_kAccumKey);
    _pushElapsed();
  }

  void dispose() {
    _ticker?.cancel();
    _elapsedController.close();
  }
}
