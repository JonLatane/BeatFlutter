# BeatScratch for Flutter

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

BeatScratch is a cross-platform music app combining readable musical notation with looping features. It supports Android, iOS, web, and macOS platforms using Flutter with platform-specific audio backends (FluidSynth on Android, AudioKit on iOS/macOS, MIDI.js for web).

## Working Effectively

### Prerequisites and Setup
- Install Flutter SDK: Use the official Flutter installation guide for your OS or `snap install flutter --classic` on Linux
- Install Protobuf 3: `sudo apt-get install protobuf-compiler` on Ubuntu/Debian
- **CRITICAL EXTERNAL DEPENDENCY**: Clone FlutterMidiCommand to `../FlutterMidiCommand` relative to this repo. The build will fail without this local dependency.
- Install platform-specific tools:
  - Android: Android Studio and SDK
  - iOS/macOS: Xcode and command line tools
  - Web: Chrome for testing

### Initial Setup Commands
```bash
# Install protobuf (Ubuntu/Debian)
sudo apt-get install protobuf-compiler

# Get the required external dependency (CRITICAL - build fails without this)
cd .. && git clone https://github.com/InvisibleWrench/FlutterMidiCommand.git

# Return to project and get dependencies
cd BeatFlutter
flutter pub get
```

### Validation Commands
```bash
# Verify all build scripts are executable
ls -la build-release*
# Should show: build-release, build-release-all, build-release-android, 
#              build-release-ios, build-release-macos, build-release-web

# Verify protobuf files exist (should show ~2800 total lines)
wc -l lib/generated/protos/*.dart

# Verify external dependency is available
ls -la ../FlutterMidiCommand/
```

### Build and Test Process

#### Core Development Commands
- `flutter pub get` - Install dependencies
- `flutter analyze` - Run static analysis (ALWAYS run before committing)
- `flutter test --coverage` - Run unit tests and generate coverage
- `flutter test` - Run unit tests only

#### Protobuf Generation (Optional)
- `./build-protos` - Generate Dart/Swift/JS protobuf classes
- **NOTE**: Generated protobuf files are already committed. Only run if proto files change or protobuf tools are installed.
- Requires: `protoc-gen-dart`, `protoc-gen-swift`, and `protoc-gen-js` plugins

#### Platform-Specific Builds

**NEVER CANCEL builds - they can take 15-45 minutes. ALWAYS set timeouts to 60+ minutes.**

##### Development/Debug Builds
- `flutter run` - Run on connected device/emulator
- `flutter run -d chrome` - Run web version in Chrome
- `flutter run -d macos` - Run macOS desktop version

##### Release Builds (Platform-Specific Flutter Channels)
The project uses different Flutter channels for optimal platform support:

**Android** (stable channel):
```bash
flutter channel stable && flutter upgrade
./build-release-android
# Builds app bundle - takes 15-30 minutes. NEVER CANCEL.
# Output: build/app/outputs/bundle/release/
```

**iOS** (stable channel):
```bash
flutter channel stable && flutter upgrade  
./build-release-ios
# Builds, archives, and uploads - takes 30-45 minutes. NEVER CANCEL.
# Requires Apple Developer certificates
```

**Web** (beta channel):
```bash
flutter channel beta && flutter upgrade
./build-release-web
# Builds web app with CanvasKit renderer - takes 10-20 minutes. NEVER CANCEL.
# Copies to ../beatscratch-page/app-staging if exists
```

**macOS** (dev channel):
```bash
flutter channel dev && flutter upgrade
./build-release-macos  
# Builds, signs, and compresses - takes 20-35 minutes. NEVER CANCEL.
# Requires macOS codesigning certificate EC73E3C309C841E94640BBA80B3FE67508A10A95
```

**All Platforms**:
```bash
./build-release-all
# Builds for all platforms sequentially - takes 60-120 minutes. NEVER CANCEL.
# Switches Flutter channels automatically
```

## Validation and Testing

### Always Run Before Committing
```bash
flutter analyze              # Static analysis - fails CI if issues found
flutter test                 # Unit tests - takes 2-5 minutes
flutter test --coverage      # With coverage report
```

**CRITICAL**: Always run these validation commands after setup:
```bash
# Ensure external dependency is present
test -d ../FlutterMidiCommand && echo "✓ FlutterMidiCommand found" || echo "✗ Missing FlutterMidiCommand - clone it first!"

# Verify protobuf files exist  
test -f lib/generated/protos/music.pb.dart && echo "✓ Protobuf files found" || echo "✗ Missing protobuf files"

# Check build script permissions
test -x build-release-all && echo "✓ Build scripts executable" || chmod +x build-release*
```

### Manual Testing Scenarios
After making changes, ALWAYS test these scenarios:
1. **App Launch**: Verify the app starts without crashes
2. **Basic Navigation**: Test main menu navigation and core features  
3. **Platform-Specific**: Test audio functionality if modifying audio code
4. **Web**: Test in Chrome with `flutter run -d chrome`

**Note**: If Flutter is not available in environment, focus on static analysis of build scripts and file structure validation using the commands above.

### CI/CD Validation
- GitHub Actions run on all pushes/PRs
- Tests must pass: `flutter analyze` and `flutter test`
- Integration tests run on Android API 21/29 and iOS simulators
- Build artifacts are generated for releases

## Common Tasks and Troubleshooting

### Repository Structure
```
BeatFlutter/
├── lib/                    # Main Dart code
│   ├── generated/protos/   # Generated protobuf classes (committed)
│   └── main.dart          # App entry point
├── protos/                # Protobuf definitions
├── android/               # Android platform code
├── ios/                   # iOS platform code  
├── macos/                 # macOS platform code
├── web/                   # Web platform code and assets
├── test/                  # Unit tests
├── build-release*         # Platform-specific build scripts
└── build-protos          # Protobuf generation script
```

### Key Files to Know
- `lib/main.dart` - Main application entry point
- `pubspec.yaml` - Dependencies and project config
- `analysis_options.yaml` - Linting rules
- `lib/generated/protos/` - Generated protobuf message classes
- `build-release-*` scripts - Platform-specific build automation

### Common Issues
- **Missing FlutterMidiCommand**: Clone to `../FlutterMidiCommand` - build fails without it
- **Protobuf generation fails**: Install protobuf plugins or use committed generated files
- **Channel conflicts**: Use correct Flutter channel per platform (see build commands above)
- **Long build times**: Normal - iOS builds can take 45+ minutes, never cancel
- **macOS signing**: Requires specific developer certificate for release builds

### Build Time Expectations
- **Unit tests**: 2-5 minutes - NEVER CANCEL, timeout: 10+ minutes
- **Flutter analyze**: 30-60 seconds  
- **Android release build**: 15-30 minutes - NEVER CANCEL, timeout: 45+ minutes
- **iOS release build**: 30-45 minutes - NEVER CANCEL, timeout: 60+ minutes  
- **Web release build**: 10-20 minutes - NEVER CANCEL, timeout: 30+ minutes
- **macOS release build**: 20-35 minutes - NEVER CANCEL, timeout: 45+ minutes
- **Full release build (all platforms)**: 60-120 minutes - NEVER CANCEL, timeout: 150+ minutes

### Development Workflow
1. Make changes to code
2. Run `flutter analyze` to check for issues
3. Run `flutter test` to verify tests pass
4. Test manually with `flutter run` on target platform
5. For releases, use appropriate `build-release-*` script with correct Flutter channel
6. Always wait for builds to complete - they take significant time but work reliably

## Architecture Notes
- Uses protobuf for cross-platform message serialization
- Platform channels delegate audio to native implementations
- Redux-style state management (beatscratch_flutter_redux)
- Multi-platform UI with platform-specific optimizations
- External MIDI support via FlutterMidiCommand plugin