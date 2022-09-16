# Candide Mobile App

### Getting Started

- Install flutter
  [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)
- Make the following project structure
  ```
  candide-mobile/
  ├─ wallet-dart/
  ├─ candide-mobile-app/
  ```
- Git clone [wallet-dart repo](https://github.com/candidelabs/wallet-dart) into `wallet-dart/`
- Git clone this repo into `candide-mobile-app/`
- Make sure to have an installed [android emulator](https://developer.android.com/studio/run/managing-avds)
- Open your emulator through cli or through AVD Device manager
- Make sure flutter sees your emulator (`flutter devices`)
- Run `flutter pub get` (from `candide-mobile-app/`)
- Make a copy of `.env.example` to `.env` and fill all variables
- Run `flutter run --debug` (if you encounter problems with device detection run with `-d <DEVICE_NAME>` flag)

