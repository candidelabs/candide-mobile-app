<!-- logo -->
<p align="center">
  <img src="assets/images/logov3.svg">
</p>

<h3 align='center' style='margin: 1em;'> Join the <b>Beta Testnet</b> on Android and IOS</h3>

<p align="center">
  <a href="https://discord.gg/NM5HakA9nC">
    <img width="50" height="50"src="https://assets-global.website-files.com/6257adef93867e50d84d30e2/636e0a6918e57475a843f59f_icon_clyde_black_RGB.svg">
  </a>
</p>

## Development
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

## Acknowledgement

We would like to thank [Optimism Community Governance](https://community.optimism.io/docs/governance) for giving the intial support for this projet.

## License
GNU General Public License v3.0