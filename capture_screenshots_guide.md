# 📸 Screenshot Capture Guide for OOUTH Mobile

## 🎯 Required Screenshots (2-8 images)

### **Recommended Screenshots:**

1. **Welcome/Login Screen** - Professional login interface
2. **Dashboard** - Main dashboard with salary overview
3. **Profile Screen** - Employee profile management
4. **Payslip Screen** - Salary information display
5. **Notifications** - Notification system
6. **Settings** - App configuration

## 📱 How to Capture Screenshots

### **Method 1: Using Flutter DevTools**

```bash
# Run your app in debug mode
flutter run

# Open DevTools in browser
flutter pub global activate devtools
flutter pub global run devtools
```

### **Method 2: Using Android Studio/VS Code**

1. Run the app in debug mode
2. Navigate to each screen
3. Use the screenshot tool in your IDE
4. Save as PNG format

### **Method 3: Using Physical Device**

1. Connect your Android device
2. Run: `flutter run --release`
3. Navigate through the app
4. Take screenshots using device screenshot feature
5. Transfer to computer

## 📐 Screenshot Requirements

- **Format**: PNG or JPEG
- **Aspect ratio**: 16:9 or 9:16
- **Size**: 320px to 3,840px per side
- **Max size**: 8 MB each
- **Recommended**: At least 4 screenshots at 1080px minimum

## 🎨 Screenshot Tips

### **Best Practices:**

1. **Use real data** - Show actual app functionality
2. **Clean interface** - Remove any debug information
3. **Professional appearance** - Ensure UI looks polished
4. **Show key features** - Highlight main functionality
5. **Consistent style** - Use same device/theme for all screenshots

### **What to Avoid:**

- ❌ Debug information or console logs
- ❌ Personal or sensitive data
- ❌ Incomplete or broken UI elements
- ❌ Different device sizes/styles
- ❌ Blurry or low-quality images

## 📁 File Naming Convention

Save screenshots with descriptive names:

```
playstore_screenshots/
├── 01_welcome_screen.png
├── 02_dashboard.png
├── 03_profile.png
├── 04_payslip.png
├── 05_notifications.png
└── 06_settings.png
```

## 🚀 Quick Setup Commands

```bash
# Create screenshots directory
mkdir -p playstore_screenshots

# Run app for screenshot capture
flutter run --release

# Navigate through screens and capture
# Save screenshots to playstore_screenshots/ directory
```

## 📋 Screenshot Checklist

- [ ] Welcome/Login Screen
- [ ] Dashboard with salary overview
- [ ] Profile management screen
- [ ] Payslip generation screen
- [ ] Notifications screen
- [ ] Settings/Configuration screen
- [ ] All screenshots are high quality (1080px+)
- [ ] All screenshots are properly sized
- [ ] No sensitive data visible
- [ ] Professional appearance maintained

## 🎯 Ready for Upload

Once you have captured all screenshots:

1. Place them in `playstore_screenshots/` directory
2. Ensure they meet size and format requirements
3. Upload to Google Play Console
4. Add descriptions for each screenshot

**Remember**: Screenshots are crucial for app discovery and user conversion on the Play Store!
