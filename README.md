# Fall Detection System - Flutter App

A comprehensive Flutter mobile application for fall detection that alerts caregivers when a fall is detected using device sensors.

## Features

### For Persons Being Monitored
- ✅ **Real-time Fall Detection** - Sophisticated algorithm using accelerometer and gyroscope
- ✅ **False Alarm Protection** - 30-second countdown to cancel false detections
- ✅ **Manual SOS Button** - Emergency alert at the tap of a button
- ✅ **Location Sharing** - Automatic location sent to caregivers on fall detection
- ✅ **Monitoring Status** - Visual indicator of active/inactive monitoring
- ✅ **Alert History** - View all past alerts

### For Caregivers
- ✅ **Live Alert Dashboard** - Real-time notifications when fall is detected
- ✅ **Multiple Monitoring** - Monitor multiple persons simultaneously
- ✅ **Alert Acknowledgment** - Acknowledge and resolve alerts
- ✅ **Alert History** - Complete history of all alerts from monitored persons
- ✅ **Push Notifications** - Immediate alerts even when app is in background

## Technology Stack

- **Framework**: Flutter (Android & iOS)
- **Backend**: Firebase
  - Authentication (Email/Password)
  - Cloud Firestore (Real-time database)
  - Cloud Messaging (Push notifications)
- **Sensors**: sensors_plus package
- **Location**: geolocator package
- **State Management**: Provider
- **Local Storage**: shared_preferences

## Architecture

```
lib/
├── main.dart                   # App entry point
├── models/                     # Data models
│   ├── user_model.dart
│   └── alert_model.dart
├── services/                   # Business logic & backend
│   ├── fall_detection_service.dart
│   ├── auth_service.dart
│   ├── database_service.dart
│   └── notification_service.dart
├── screens/                    # UI screens
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── person_dashboard.dart
│   ├── caregiver_dashboard.dart
│   └── settings_screen.dart
├── widgets/                    # Reusable components
│   ├── custom_button.dart
│   ├── alert_card.dart
│   └── status_indicator.dart
└── utils/                      # Constants & themes
    ├── constants.dart
    └── theme.dart
```

## Getting Started

### Prerequisites

- Flutter SDK (3.0+)
- Dart SDK (3.0+)
- Android Studio / Xcode
- Firebase account
- Physical device (recommended for sensor testing)

### Installation

1. **Clone or navigate to the project**
   ```bash
   cd fall_detection_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase** (IMPORTANT!)
   - Follow the detailed instructions in [`FIREBASE_SETUP.md`](FIREBASE_SETUP.md)
   - This includes:
     - Creating Firebase project
     - Enabling Authentication, Firestore, and Cloud Messaging
     - Downloading configuration files
     - Setting up for both Android and iOS

4. **Run the app**
   ```bash
   flutter run
   ```

## Fall Detection Algorithm

The app uses a multi-stage detection algorithm:

1. **Free Fall Detection** - Monitors for sudden drop in acceleration (< 0.5g)
2. **Impact Detection** - Detects sudden spike in acceleration (> 3g)
3. **Orientation Change** - Confirms significant change in device orientation (> 60°)
4. **Countdown Protection** - 30-second user confirmation window to prevent false alarms

### Sensitivity Settings

Adjust these in `lib/utils/constants.dart`:
- `freeFallThreshold`: Lower = more sensitive
- `impactThreshold`: Lower = more sensitive
- `orientationChangeThreshold`: Lower = more sensitive
- `alertCountdownSeconds`: Countdown duration

## User Roles

### Person (Being Monitored)
- Registers with role "Person"
- Can start/stop fall detection monitoring
- Can send manual SOS alerts
- Can link caregivers to account
- Receives monitoring status updates

### Caregiver
- Registers with role "Caregiver"
- Monitors one or more persons
- Receives real-time fall alerts
- Can acknowledge and resolve alerts
- Views complete alert history

## Firebase Setup

### Required Firebase Services

1. **Authentication** - Email/Password sign-in
2. **Cloud Firestore** - Real-time database with collections:
   - `users` - User profiles and links
   - `alerts` - Fall alert records
   - `userTokens` - FCM device tokens

3. **Cloud Messaging** - Push notifications to caregivers

### Security Rules

See `FIREBASE_SETUP.md` for Firestore security rules that:
- Allow users to manage their own data
- Allow caregivers to read linked persons' alerts
- Protect sensitive information

## Permissions

### Android
- Internet access
- Location (fine & coarse)
- Background location
- Foreground service
- Notifications
- Wake lock
- Boot receiver

### iOS
- Location when in use
- Location always
- Motion sensors
- Background modes (location, fetch, remote notifications)

## Testing

### Testing Fall Detection

**⚠️ IMPORTANT: Test carefully to avoid device damage**

1. Use a soft surface (bed, couch)
2. Enable monitoring
3. Drop phone from waist height onto soft surface
4. Algorithm should detect free fall → impact → orientation change
5. Countdown dialog appears
6. Tap "I'm Okay" to cancel, or wait 30s for alert to send

### Testing Notifications

1. Create two accounts (Person & Caregiver)
2. Link them together
3. On Person device: trigger fall or manual SOS
4. On Caregiver device: verify alert notification appears

## Known Limitations

1. **Sensor Accuracy** - Basic algorithm may have false positives/negatives
2. **Background Processing** - iOS has stricter background limitations
3. **Push Notifications** - Requires backend server for production (Firebase Admin SDK)
4. **Location** - May not work indoors or with poor GPS signal

## Production Deployment Checklist

- [ ] Update Firebase security rules to production mode
- [ ] Implement Firebase Cloud Functions for push notifications
- [ ] Add machine learning model for better fall detection
- [ ] Implement emergency service integration
- [ ] Add phone call functionality
- [ ] Set up proper error tracking (Crashlytics)
- [ ] Conduct clinical validation of algorithm
- [ ] Add accessibility features
- [ ] Implement data encryption
- [ ] Create privacy policy and terms of service

## Troubleshooting

### Firebase Not Working
- Ensure `google-services.json` (Android) is in `android/app/`
- Ensure `GoogleService-Info.plist` (iOS) is added to Xcode project
- Check package name matches Firebase project configuration
- Run `flutter clean` and `flutter pub get`

### Sensors Not Detecting
- Test on physical device (emulators may not support sensors)
- Check device has accelerometer and gyroscope
- Verify permissions are granted
- Try adjusting sensitivity thresholds

### Location Not Working
- Grant location permissions
- Test outdoors for better GPS signal
- Check location services are enabled on device

## Contributing

This is a foundational implementation. Suggested improvements:

- Machine learning-based fall detection
- Integration with wearable devices
- Video call feature for emergencies
- Medical history and medication tracking
- Integration with emergency services (911/112)
- Multi-language support

## License

This project is provided as-is for educational and development purposes.

## Support

For issues or questions:
1. Check `FIREBASE_SETUP.md` for configuration help
2. Review Firebase Console for backend issues
3. Test on physical device with sensors enabled
4. Check Flutter doctor: `flutter doctor`

---

**⚠️ Medical Disclaimer**: This app is for demonstration purposes. Do not rely solely on this app for critical health monitoring without proper clinical validation and medical approval.
