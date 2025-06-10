# Google Sign-In Setup Instructions

## SHA-1 Fingerprints

**Debug SHA-1:** 31:CA:B8:B8:7C:FD:06:31:93:67:B1:6C:F7:5B:A3:8B:8A:60:4F:7D

## Firebase Console Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (create one if you don't have it)
3. Go to **Project Settings** (gear icon)
4. Scroll down to **Your apps** section
5. Click on the Android app (com.example.gohealth) or add if not exists
6. In **App details**, add the SHA-1 fingerprint:
   - Click "Add fingerprint"
   - Paste: `31:CA:B8:B8:7C:FD:06:31:93:67:B1:6C:F7:5B:A3:8B:8A:60:4F:7D`
   - Click "Save"

## Enable Google Sign-In

1. In Firebase Console, go to **Authentication**
2. Click **Sign-in method** tab
3. Enable **Google** provider
4. Add your email as test user if needed

## Download google-services.json

1. In Project Settings, download the **google-services.json** file
2. Replace the existing file in android/app/google-services.json

## Google Cloud Console Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select the same project
3. Go to **APIs & Services** > **Credentials**
4. Click **+ CREATE CREDENTIALS** > **OAuth 2.0 Client IDs**
5. Choose **Android** application type
6. Name: "GoHealth Android"
7. Package name: `com.example.gohealth`
8. SHA-1: `31:CA:B8:B8:7C:FD:06:31:93:67:B1:6C:F7:5B:A3:8B:8A:60:4F:7D`
9. Click **Create**

## Update Environment Variables

Update your .env file with the client ID from Google Cloud Console:

```
GOOGLE_WEB_CLIENT_ID=your_web_client_id_here.apps.googleusercontent.com
```

## Test the Setup

After completing all steps above, run:

```bash
flutter clean
flutter pub get
flutter run
```
