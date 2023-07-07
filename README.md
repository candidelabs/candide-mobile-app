<!-- logo -->
<p align="center">
  <img src="https://github.com/candidelabs/candide-mobile-app/assets/7014833/94823afb-da40-4026-81b9-d467c704a225">
</p>

<h1 align='center' style='margin: 1em;'> <b>CANDIDE Wallet</b> </h1>
<h2 align='center' style='margin: 1em;'> <b>The Golden Standard for ERC-4337 smart contract wallets </b> </h2>
<h3 align='center' style='margin: 1em;'> <b>Try the IOS and Android app today on our discord </b> </h3>


<p align="center">
  <a href="https://discord.gg/NM5HakA9nC">
    <img width="70" height="70"src="https://assets-global.website-files.com/6257adef93867e50d84d30e2/636e0a69f118df70ad7828d4_icon_clyde_blurple_RGB.svg">
  </a>
</p>

## Development
### Getting Started

- Install flutter
  [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)
- Clone this repo
- Make sure to have an installed [android emulator](https://developer.android.com/studio/run/managing-avds)
- Open your emulator through cli or through AVD Device manager
- Make sure flutter sees your emulator (`flutter devices`)
- Run `flutter pub get`
- Make a copy of `.env.example` to `.env` and fill all variables
- Run `flutter run --debug` (if you encounter problems with device detection run with `-d <DEVICE_NAME>` flag)

### ENV variables

- **Bundler**: We host [FREE endpoints](https://docs.candidewallet.com/bundler/rpc-endpoints) based on our compliant ERC-4337 python bundler Voltaire . 
- **Paymasters**: Run your own open source [verifying paymaster](https://github.com/candidelabs/Candide-Paymaster-RPC)
- **Node**: Get your node endpoints on [ChainList](https://chainlist.org/)

### Troubleshooting
- If you are getting `compileSdkVersion errors`. Go to `android/local.properties` and add those lines
```
flutter.minSdkVersion=23
flutter.compileSdkVersion=33
```

## Acknowledgement

We would like to thank [Optimism Community Governance](https://community.optimism.io/docs/governance) providing the intial support for this project.

## License
Candide Wallet is available under the GNU General Public License v3.0 license. 
