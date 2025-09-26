# Authsignal Flutter SDK Test App

A simple test app to validate Authsignal Flutter SDK functionality including device credentials (trusted device authentication) and WhatsApp OTP.

## Quick Setup

### 1. Prerequisites
- Flutter SDK installed
- iOS Simulator or Android emulator running
- Node.js (for test backend)

### 2. Install & Run

```bash
# 1. Install Flutter dependencies
cd test_app
flutter pub get

# 2. Start test backend (in new terminal)
npm install
npm start

# 3. Run Flutter app
flutter run
```

## Testing Device Credentials (Trusted Device)

### Step 1: Initialize App
1. Open the Flutter app
2. Enter any User ID (e.g., `test_user_123`)
3. Click **"Initialize"**

### Step 2: Add Device Credential
1. Click **"Add Credential"**
2. App will register this device for authentication
3. Note the credential ID in the output

### Step 3: Test Authentication Flow
1. Click **"Verify Device"**
2. This simulates the complete trusted device authentication:
   - Backend creates a challenge
   - App receives the challenge token
   - Device performs authentication
   - Returns verification result

✅ **Success**: You'll see "Device verification successful!" with a verification token

## Testing WhatsApp OTP

### Step 1: Send OTP
1. Enter a phone number (e.g., `+1234567890`)
2. Click **"Start WhatsApp Challenge"**
3. Check the output for challenge details

### Step 2: Verify OTP
1. Enter the OTP code received (for testing, any code works)
2. Click **"Verify WhatsApp OTP"**

✅ **Success**: You'll see verification result with token

## What This Tests

### Device Credentials ✅
- Device registration and credential management
- Challenge token handling
- Trusted device authentication flow
- Public key cryptography integration

### WhatsApp OTP ✅
- WhatsApp challenge initiation
- OTP verification process
- Token validation

### Integration ✅
- Flutter ↔ Native SDK communication
- Backend API integration
- Real Authsignal API calls

## Configuration

The app is pre-configured with test credentials. For production use:

1. Update `lib/main.dart` with your Authsignal credentials:
   - Tenant ID
   - Base URL
   - API Secret Key (backend only)

2. Update backend URL in `main.dart` if using external backend