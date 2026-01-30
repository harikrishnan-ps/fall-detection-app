# Firebase Setup Instructions

Follow these steps to set up Firebase for your Fall Detection App on both Android and iOS.

## Prerequisites

- Google Account
- Flutter SDK installed
- Android Studio (for Android)
- Xcode (for iOS, macOS only)

---

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** or **"Create a project"**
3. Enter project name: `fall-detection-app` (or your preferred name)
4. Click **Continue**
5. (Optional) Enable Google Analytics
6. Click **Create project**
7. Wait for setup to complete, then click **Continue**

---

## Step 2: Enable Firebase Authentication

1. In Firebase Console, select your project
2. Click **Build** → **Authentication** in the left sidebar
3. Click **Get started**
4. Click on **Email/Password** under Sign-in providers
5. Toggle **Enable** switch
6. Click **Save**

---

## Step 3: Enable Cloud Firestore

1. In Firebase Console, click **Build** → **Firestore Database**
2. Click **Create database**
3. Select **Start in test mode** (for development)
   > **Note:** Change to production rules before deploying!
4. Choose a location (select closest to your users)
5. Click **Enable**

---

## Step 4: Enable Cloud Messaging

1. In Firebase Console, click **Build** → **Cloud Messaging**
2. Cloud Messaging is enabled by default
3. Note: You'll configure platform-specific settings below

---

## Step 5: Configure Android App

### 5.1 Register Android App

1. In Firebase Console, click the **Android icon** to add Android app
2. Enter Android package name: `com.example.fall_detection_app`
   - **Important:** This must match the `applicationId` in your `android/app/build.gradle`
3. (Optional) Enter app nickname: "Fall Detection Android"
4. Click **Register app**

### 5.2 Download google-services.json

1. Download the `google-services.json` file
2. Move it to: `fall_detection_app/android/app/google-services.json`

### 5.3 Configure Android Build Files

**File: `android/build.gradle`**

Add Google services plugin to dependencies:

```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

**File: `android/app/build.gradle`**

At the bottom of the file, add:

```gradle
apply plugin: 'com.google.gms.google-services'
```

Also update `minSdkVersion` in `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Changed from flutter.minSdkVersion
    }
}
```

### 5.4 Android Permissions

The permissions are already configured in `android/app/src/main/AndroidManifest.xml`.

---

## Step 6: Configure iOS App

### 6.1 Register iOS App

1. In Firebase Console, click the **iOS icon** to add iOS app
2. Enter iOS bundle ID: `com.example.fallDetectionApp`
   - **Important:** This must match the Bundle Identifier in Xcode
3. (Optional) Enter app nickname: "Fall Detection iOS"
4. Click **Register app**

### 6.2 Download GoogleService-Info.plist

1. Download the `GoogleService-Info.plist` file
2. Open Xcode: `open ios/Runner.xcworkspace`
3. Drag `GoogleService-Info.plist` into the Runner folder in Xcode
4. Make sure **"Copy items if needed"** is checked
5. Click **Finish**

### 6.3 Enable Push Notifications in Xcode

1. In Xcode, select **Runner** project
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **Push Notifications**
5. Add **Background Modes**
6. Check the following under Background Modes:
   - ✅ Location updates
   - ✅ Background fetch
   - ✅ Remote notifications

### 6.4 Update Info.plist

Open `ios/Runner/Info.plist` and add location permission descriptions (already configured in project).

---

## Step 7: Install Flutter Dependencies

Run the following command in your project directory:

```bash
cd fall_detection_app
flutter pub get
```

---

## Step 8: Initialize Firebase in Flutter

The initialization code is already included in `lib/main.dart`.

---

## Step 9: Configure Firestore Security Rules

1. Go to Firebase Console → **Firestore Database**
2. Click **Rules** tab
3. Replace with the following rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow caregivers to read person's data if they're linked
      allow read: if request.auth != null && 
                     request.auth.uid in resource.data.linkedUsers;
    }
    
    // Alerts
    match /alerts/{alertId} {
      // Person can create alerts
      allow create: if request.auth != null && 
                       request.auth.uid == request.resource.data.personId;
      
      // Person and linked caregivers can read alerts
      allow read: if request.auth != null && (
                     request.auth.uid == resource.data.personId ||
                     request.auth.uid in get(/databases/$(database)/documents/users/$(resource.data.personId)).data.linkedUsers
                  );
      
      // Linked caregivers can update alert status
      allow update: if request.auth != null &&
                       request.auth.uid in get(/databases/$(database)/documents/users/$(resource.data.personId)).data.linkedUsers;
    }
    
    // User tokens for FCM
    match /userTokens/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null;
    }
  }
}
```

4. Click **Publish**

---

## Step 10: Test Firebase Connection

Run the app:

```bash
flutter run
```

Check the console for Firebase initialization success message.

---

## Step 11: (Optional) Get FCM Server Key for Push Notifications

1. Go to Firebase Console
2. Click the **gear icon** → **Project settings**
3. Go to **Cloud Messaging** tab
4. Under **Cloud Messaging API (Legacy)**, note your **Server key**
   - You may need to enable Cloud Messaging API in Google Cloud Console

---

## Troubleshooting

### Android Issues

- **Build errors**: Run `flutter clean` and `flutter pub get`
- **Google services plugin error**: Ensure `google-services.json` is in `android/app/` folder
- **Multidex error**: Add `multiDexEnabled true` in `android/app/build.gradle`

### iOS Issues

- **Pod install errors**: 
  ```bash
  cd ios
  pod deintegrate
  pod install
  ```
- **GoogleService-Info.plist not found**: Ensure it's added to Xcode project, not just the folder
- **Code signing errors**: Configure your development team in Xcode

### Firebase Connection Issues

- Verify package name (Android) and bundle ID (iOS) match Firebase configuration
- Check `google-services.json` and `GoogleService-Info.plist` are in correct locations
- Ensure Firebase is initialized in `main.dart` before `runApp()`

---

## Next Steps

Once Firebase is configured:

1. ✅ Test user registration
2. ✅ Test login functionality
3. ✅ Test Firestore read/write
4. ✅ Test push notifications
5. ✅ Deploy to physical devices for sensor testing

---

## Security Notes

> [!CAUTION]
> Before production deployment:
> - Update Firestore rules from test mode to production rules
> - Enable App Check for additional security
> - Set up proper authentication flows
> - Review and minimize permissions
> - Enable Google Analytics for monitoring

