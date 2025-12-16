# OOUTH Cooperative Mobile App

A comprehensive Flutter-based mobile application for the OOUTH Cooperative Society, providing members with seamless access to cooperative services, financial management, and member engagement features.

## 📱 Overview

The OOUTH Cooperative Mobile App is a cross-platform mobile application built with Flutter, designed to empower cooperative members with easy access to their accounts, loans, transactions, events, and other cooperative services. The app provides a modern, intuitive interface for managing cooperative membership activities on the go.

## ✨ Features

### Core Functionality

- **Authentication & Security**

  - Secure login with OTP verification
  - Biometric authentication support
  - Device binding for enhanced security
  - Password management and recovery

- **Financial Services**

  - Wallet management and balance tracking
  - Transaction history and summaries
  - Loan applications and tracking
  - Payment processing
  - Financial statements

- **Member Services**

  - Profile management
  - Account information
  - Product catalog browsing
  - Event registration and attendance
  - Duty rota management

- **Communication**

  - Push notifications (OneSignal & Firebase)
  - In-app notifications
  - Support and complaint submission

- **Additional Features**
  - Location services and Google Maps integration
  - Offline connectivity detection
  - App update notifications
  - Dark/Light theme support
  - Multi-platform support (iOS, Android, Web)

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (>=3.0.0 <4.0.0)
- **Dart SDK** (comes with Flutter)
- **Android Studio** or **Xcode** (for mobile development)
- **VS Code** or **Android Studio** (recommended IDEs)
- **Git** for version control

### Installation

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd oouth_coop_app
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure environment variables**

   - Create a `.env` file in the root directory
   - Add your API endpoints and configuration variables
   - Ensure `.env` is included in your assets (already configured in `pubspec.yaml`)

4. **Configure Firebase** (if using Firebase services)

   - Add your `google-services.json` (Android) to `android/app/`
   - Add your `GoogleService-Info.plist` (iOS) to `ios/Runner/`

5. **Run the application**
   ```bash
   flutter run
   ```

## 🏗️ Project Structure

```
lib/
├── config/           # App configuration and theme settings
├── features/         # Feature modules
│   ├── account/      # Account management
│   ├── auth/         # Authentication flows
│   ├── complaints/   # Support and complaints
│   ├── events/       # Event management
│   ├── home/         # Home screen
│   ├── loans/        # Loan services
│   ├── notifications/# Notification handling
│   ├── payments/     # Payment processing
│   ├── products/     # Product catalog
│   ├── profile/      # User profile
│   ├── settings/     # App settings
│   ├── support/      # Support services
│   ├── transactions/ # Transaction history
│   └── wallet/       # Wallet management
├── services/         # Core services
│   ├── app_update_service.dart
│   ├── device_id_service.dart
│   ├── notification_service.dart
│   ├── theme_service.dart
│   └── wallet_service.dart
├── shared/           # Shared widgets and components
│   └── widgets/
└── utils/            # Utility functions and helpers
```

## 📦 Key Dependencies

- **State Management**: `provider` (^6.0.5)
- **Networking**: `http` (^1.1.0)
- **Storage**: `shared_preferences` (^2.2.0)
- **Authentication**: `local_auth` (^2.1.6)
- **Notifications**:
  - `onesignal_flutter` (^5.2.9)
  - `firebase_messaging` (^14.7.16)
- **Location & Maps**:
  - `geolocator` (^10.1.0)
  - `google_maps_flutter` (^2.5.0)
- **UI Components**:
  - `google_fonts` (^5.1.0)
  - `flutter_svg` (^2.0.7)
  - `lottie` (^2.7.0)

For a complete list, see `pubspec.yaml`.

## 🔧 Configuration

### Environment Setup

1. Copy the `.env.example` (if available) to `.env`
2. Configure the following variables:
   - API base URL
   - Firebase configuration
   - OneSignal app ID
   - Google Maps API key

### Build Configuration

#### Android

- Minimum SDK: 21
- Target SDK: Latest stable
- Keystore: Configured in `android/app/`

#### iOS

- Minimum iOS version: 12.0
- Configure signing in Xcode

## 🏃 Running the App

### Development Mode

```bash
flutter run
```

### Release Build

#### Android

```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

#### iOS

```bash
flutter build ios --release
```

#### Web

```bash
flutter build web --release
```

## 🧪 Testing

Run tests with:

```bash
flutter test
```

## 📱 Build & Deployment

The app supports automated builds and deployments:

- **APK builds** are stored in the `dist/` and `download/` directories
- **Version management** is handled via `version.json` and `version_bump.sh`
- **Firebase Hosting** is configured for web deployment
- **Vercel** configuration is available for alternative web hosting

## 🔐 Security

- Device binding for account security
- Biometric authentication support
- Secure storage of sensitive data
- Encrypted API communications
- OTP-based authentication

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Material Design](https://material.io/design)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

[Specify your license here]

## 👥 Support

For support, email [support email] or open an issue in the repository.

## 📝 Version History

- **v2.0.0+9** - Current version
  - Enhanced security features
  - Improved UI/UX
  - Bug fixes and performance improvements

---

**Built with ❤️ using Flutter**
