# Google Sign-In Error Fix Guide

## Current Issue
Error: `ApiException: 10` - Configuration Issue

## Debug Information
- **Package Name:** com.example.gohealth
- **Debug SHA-1:** 31:CA:B8:B8:7C:FD:06:31:93:67:B1:6C:F7:5B:A3:8B:8A:60:4F:7D
- **Project Number:** 845113946067
- **Android Client ID:** 845113946067-hvg4pfb2ncjicg8mh8en5ouckugkdbeh.apps.googleusercontent.com
- **Web Client ID:** 845113946067-ukaickbhgki6n6phesnacsa9b4sgc8hu.apps.googleusercontent.com

## URGENT STEPS TO FIX:

### 1. Firebase Console Setup
1. Go to https://console.firebase.google.com/
2. Select your project: **gohealth-app-demo**
3. Go to **Project Settings** (gear icon)
4. Scroll to **Your apps** section
5. If no Android app exists, click **Add app** → **Android**

### 2. Add Android App Configuration
- **Package name:** `com.example.gohealth`
- **App nickname:** GoHealth Android
- **Debug signing certificate SHA-1:** `31CAB8B87CFD063193676B1CF75BA38B8A604F7D`

### 3. Google Cloud Console (CRITICAL)
1. Go to https://console.cloud.google.com/
2. Select project with ID: **845113946067**
3. Go to **APIs & Services** → **Credentials**
4. Find OAuth 2.0 Client ID for Android
5. Make sure these settings are correct:
   - **Package name:** `com.example.gohealth`
   - **SHA-1 fingerprints:** `31:CA:B8:B8:7C:FD:06:31:93:67:B1:6C:F7:5B:A3:8B:8A:60:4F:7D`

### 4. Download New google-services.json
1. In Firebase Console → Project Settings
2. Scroll to **Your apps** → Android app
3. Click **google-services.json** to download
4. Replace the current file in `android/app/google-services.json`

## Alternative Quick Fix
If Firebase setup is complex, try this simpler configuration:

### Option A: Remove serverClientId
Already done in AuthService - using default configuration.

### Option B: Create Test Project
1. Create new Firebase project
2. Add Android app with package: `com.example.gohealth`
3. Add SHA-1: `31CAB8B87CFD063193676B1CF75BA38B8A604F7D`
4. Download google-services.json
5. Enable Google Sign-In in Authentication

## Verify Setup
After completing setup:
1. Clean build: `flutter clean`
2. Get dependencies: `flutter pub get`
3. Build: `flutter build apk --debug`
4. Test sign-in

## Common Issues
- **Wrong SHA-1:** Make sure SHA-1 in Firebase matches debug keystore
- **Wrong Package:** Verify package name matches in all places
- **Missing API Key:** Ensure google-services.json has valid API key
- **Client ID Mismatch:** Android client ID should be type 1, Web should be type 3

## Debug Commands
```bash
# Get SHA-1 fingerprint
cd android
./gradlew signingReport

# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --debug
```
