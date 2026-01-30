class AppConstants {
  // Fall Detection Thresholds
  static const double freeFallThreshold = 0.5; // g-force
  static const double impactThreshold = 3.0; // g-force
  static const int freeFallDurationMs = 100; // milliseconds
  static const double orientationChangeThreshold = 60.0; // degrees
  
  // Countdown Timer
  static const int alertCountdownSeconds = 30;
  
  // Monitoring
  static const int sensorUpdateIntervalMs = 100;
  static const String monitoringChannelId = 'fall_detection_monitoring';
  static const String monitoringChannelName = 'Fall Detection Monitoring';
  static const String alertChannelId = 'fall_alerts';
  static const String alertChannelName = 'Fall Alerts';
  
  // User Roles
  static const String rolePerson = 'person';
  static const String roleCaregiver = 'caregiver';
  
  // Alert Status
  static const String alertStatusPending = 'pending';
  static const String alertStatusAcknowledged = 'acknowledged';
  static const String alertStatusResolved = 'resolved';
  static const String alertStatusCancelled = 'cancelled';
  
  // Firestore Collections
  static const String usersCollection = 'users';
  static const String alertsCollection = 'alerts';
  static const String userTokensCollection = 'userTokens';
  
  // Shared Preferences Keys
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyMonitoringEnabled = 'monitoring_enabled';
  static const String keyDetectionSensitivity = 'detection_sensitivity';
  static const String keyNotificationSound = 'notification_sound';
  
  // Location
  static const double defaultLatitude = 0.0;
  static const double defaultLongitude = 0.0;
  
  // Messages
  static const String fallDetectedMessage = 'Fall detected! Are you okay?';
  static const String alertSentMessage = 'Alert sent to caregivers';
  static const String alertCancelledMessage = 'Alert cancelled';
}
