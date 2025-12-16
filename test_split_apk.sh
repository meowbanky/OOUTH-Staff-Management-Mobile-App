#!/bin/bash

echo "Testing Split APK Build..."
echo "=========================="

# Clean previous builds
echo "Cleaning previous builds..."
flutter clean

# Try split APK build
echo "Building split APKs..."
flutter build apk --split-per-abi --release

echo ""
echo "Checking for APK files..."
echo "=========================="

# Check for split APKs
if [ -f "build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" ]; then
    echo "✅ ARM64 APK found"
    ls -lh build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
else
    echo "❌ ARM64 APK not found"
fi

if [ -f "build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk" ]; then
    echo "✅ ARM APK found"
    ls -lh build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
else
    echo "❌ ARM APK not found"
fi

if [ -f "build/app/outputs/flutter-apk/app-x86_64-release.apk" ]; then
    echo "✅ x86_64 APK found"
    ls -lh build/app/outputs/flutter-apk/app-x86_64-release.apk
else
    echo "❌ x86_64 APK not found"
fi

# Check for universal APK
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo "✅ Universal APK found"
    ls -lh build/app/outputs/flutter-apk/app-release.apk
else
    echo "❌ Universal APK not found"
fi

echo ""
echo "Summary:"
echo "========="
echo "If you see split APKs, the build is working correctly."
echo "If you only see Universal APK, that's also fine - it works on all devices."
echo ""
echo "To enable split APKs, make sure:"
echo "1. abiFilters is commented out in android/app/build.gradle"
echo "2. Your Flutter version supports split APKs"
echo "3. No build errors occur" 