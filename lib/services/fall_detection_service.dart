import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../utils/constants.dart';

enum FallDetectionState {
  idle,
  monitoring,
  freeFallDetected,
  impactDetected,
  fallConfirmed,
  countdownActive,
}

class FallDetectionService extends ChangeNotifier {
  FallDetectionState _state = FallDetectionState.idle;
  FallDetectionState get state => _state;

  bool _isMonitoring = false;
  bool get isMonitoring => _isMonitoring;

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  DateTime? _freeFallStartTime;
  bool _freeFallDetected = false;
  bool _impactDetected = false;
  double _orientationChange = 0.0;

  Timer? _countdownTimer;
  int _countdownSeconds = AppConstants.alertCountdownSeconds;
  int get countdownSeconds => _countdownSeconds;

  Function()? onFallConfirmed;
  Function()? onAlertCancelled;

  // Start monitoring for falls
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _state = FallDetectionState.monitoring;
    _resetDetectionState();
    notifyListeners();

    // Subscribe to accelerometer
    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: Duration(milliseconds: AppConstants.sensorUpdateIntervalMs),
    ).listen(_onAccelerometerData);

    // Subscribe to gyroscope
    _gyroscopeSubscription = gyroscopeEventStream(
      samplingPeriod: Duration(milliseconds: AppConstants.sensorUpdateIntervalMs),
    ).listen(_onGyroscopeData);

    debugPrint('Fall detection monitoring started');
  }

  // Stop monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _state = FallDetectionState.idle;
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _countdownTimer?.cancel();
    _resetDetectionState();
    notifyListeners();

    debugPrint('Fall detection monitoring stopped');
  }

  // Process accelerometer data
  void _onAccelerometerData(AccelerometerEvent event) {
    if (!_isMonitoring) return;

    // Calculate total acceleration magnitude
    double totalAcceleration = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    // Normalize to g-force (9.8 m/s² = 1g)
    double gForce = totalAcceleration / 9.8;

    // Detect free fall (sudden drop in acceleration)
    if (gForce < AppConstants.freeFallThreshold) {
      if (!_freeFallDetected) {
        _freeFallStartTime = DateTime.now();
        _freeFallDetected = true;
        _state = FallDetectionState.freeFallDetected;
        notifyListeners();
        debugPrint('Free fall detected: ${gForce.toStringAsFixed(2)}g');
      }
    } else {
      // Check if free fall duration was sufficient
      if (_freeFallDetected && _freeFallStartTime != null) {
        int freeFallDuration = DateTime.now().difference(_freeFallStartTime!).inMilliseconds;
        
        if (freeFallDuration < AppConstants.freeFallDurationMs) {
          // Free fall too short, reset
          _freeFallDetected = false;
          _freeFallStartTime = null;
        }
      }
    }

    // Detect impact (sudden high acceleration)
    if (_freeFallDetected && gForce > AppConstants.impactThreshold) {
      _impactDetected = true;
      _state = FallDetectionState.impactDetected;
      notifyListeners();
      debugPrint('Impact detected: ${gForce.toStringAsFixed(2)}g');
      
      // Check if we should confirm the fall
      _checkFallConfirmation();
    }
  }

  // Process gyroscope data for orientation change
  void _onGyroscopeData(GyroscopeEvent event) {
    if (!_isMonitoring || !_impactDetected) return;

    // Calculate total rotation (simplified)
    double totalRotation = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    // Accumulate orientation change (in degrees)
    _orientationChange += totalRotation * (180 / pi) * 
        (AppConstants.sensorUpdateIntervalMs / 1000);

    debugPrint('Orientation change: ${_orientationChange.toStringAsFixed(2)}°');
  }

  // Check if fall should be confirmed
  void _checkFallConfirmation() {
    // Add a small delay to allow orientation change to accumulate
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_freeFallDetected && 
          _impactDetected && 
          _orientationChange > AppConstants.orientationChangeThreshold) {
        _confirmFall();
      } else {
        // False positive - reset
        debugPrint('False positive - resetting detection state');
        _resetDetectionState();
      }
    });
  }

  // Confirm fall and start countdown
  void _confirmFall() {
    _state = FallDetectionState.fallConfirmed;
    notifyListeners();
    debugPrint('Fall confirmed! Starting countdown...');
    
    _startCountdown();
  }

  // Start countdown timer
  void _startCountdown() {
    _countdownSeconds = AppConstants.alertCountdownSeconds;
    _state = FallDetectionState.countdownActive;
    notifyListeners();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownSeconds--;
      notifyListeners();

      if (_countdownSeconds <= 0) {
        timer.cancel();
        _triggerAlert();
      }
    });
  }

  // Cancel the alert during countdown
  void cancelAlert() {
    _countdownTimer?.cancel();
    _state = FallDetectionState.monitoring;
    _resetDetectionState();
    notifyListeners();
    
    debugPrint('Alert cancelled by user');
    onAlertCancelled?.call();
  }

  // Trigger the alert (send to caregivers)
  void _triggerAlert() {
    debugPrint('Alert triggered - notifying caregivers');
    onFallConfirmed?.call();
    
    // Reset and continue monitoring
    _state = FallDetectionState.monitoring;
    _resetDetectionState();
    notifyListeners();
  }

  // Reset detection state
  void _resetDetectionState() {
    _freeFallDetected = false;
    _impactDetected = false;
    _freeFallStartTime = null;
    _orientationChange = 0.0;
    _countdownSeconds = AppConstants.alertCountdownSeconds;
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
