# BASERENT — Complete Setup Guide (Mac Ventura)

## Prerequisites check
```bash
flutter --version      # need 3.0+
pod --version          # need 1.11+
xcode-select --version # need Xcode CLI tools
```
If CocoaPods is outdated: `sudo gem install cocoapods`
If Xcode CLI missing: `xcode-select --install`

---

## Step 1 — Copy your firebase_options.dart
```
cp /path/to/your/firebase_options.dart lib/firebase_options.dart
```

## Step 2 — Download fonts (one time)
```bash
bash assets/fonts/DOWNLOAD_FONTS.sh
```

## Step 3 — Install Flutter packages
```bash
flutter pub get
```

## Step 4 — Install iOS pods
```bash
cd ios && pod install && cd ..
```
If pod install fails: `cd ios && pod repo update && pod install && cd ..`

## Step 5 — Deploy Firestore rules & indexes (Firebase Console)
Upload these files in your Firebase Console:
- `firestore.rules`  → Firestore → Rules tab → paste & publish
- `firestore.indexes.json` → Firestore → Indexes tab → add each index
- `storage.rules` → Storage → Rules tab → paste & publish

Or use Firebase CLI (if installed):
```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

## Step 6 — Run the app
```bash
flutter run
```

---

## Stripe setup checklist
- [ ] Backend deployed on Render with `STRIPE_SECRET_KEY` env var set
- [ ] Flutter app has your Stripe **publishable** key in `main.dart`
- [ ] iOS: Stripe requires real device OR simulator iOS 13+
- [ ] The URL scheme `baserent` is registered in Info.plist (already done)

---

## Troubleshooting white screen

The app now shows the real error on screen instead of a white page.
For more detail run:
```bash
flutter run --verbose 2>&1 | grep -E "Error|error|Exception|FATAL|failed"
```

### Common fixes on Mac Ventura:

**"MissingPluginException" for image_picker or firebase:**
```bash
flutter clean && flutter pub get && cd ios && pod install && cd .. && flutter run
```

**Firestore "FAILED_PRECONDITION" error:**
→ You need to create composite indexes. Open the error link from the
  Flutter debug console — it takes you directly to the Firebase Console
  to create the index automatically.

**Stripe PaymentSheet not appearing:**
→ Stripe requires iOS 13+. Check your simulator: 
  Device → iOS version in Xcode must be 13.0 or higher.

**Pod install fails with "CDN: trunk" error:**
```bash
cd ios && pod repo remove trunk && pod setup && pod install && cd ..
```

**Build fails with "Command PhaseScriptExecution failed":**
```bash
flutter clean
rm -rf ios/Pods ios/Podfile.lock
cd ios && pod install && cd ..
flutter run
```
