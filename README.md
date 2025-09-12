
# Attendance Tracker (BunkMate)

This is a basic Flutter app to help track college attendance for lectures and help me maintain 80% attendance.

---

## 🚀 Project Setup & Usage

### 1. Clone the Repository
```sh
git clone "https://github.com/HarshilD05/Attendance_Tracker.git"
cd Attendance_Tracker
```

### 2. Create Platform Folders (if missing)
If you don't see `android/`, `ios/`, or `web/` folders, run:
```sh
flutter create . --platforms [ios|android|windows|macos|linux|web]
```
This will generate all necessary platform folders.

### 3. Install Dependencies
```sh
flutter pub get
```

### 4. Test the Build on Web
```sh
flutter run -d chrome
```
This will launch the app in your browser.

### 5. Run the App on Android (Debug Mode)
Connect your Android device (with USB debugging enabled) or use an emulator:
```sh
flutter run -d android
```

### 6. Build the Final APK for Android
```sh
flutter build apk --release
```
The APK will be generated in `build/app/outputs/flutter-apk/app-release.apk`.

### 7. Build for iOS (on macOS only)
```sh
flutter build ios --release
```
You can then open the iOS project in Xcode for further steps.

---

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Flutter Codelabs](https://docs.flutter.dev/get-started/codelab)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
