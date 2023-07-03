Android versions prior to 7.1.1 don't have Let's encrypt (LE) root certificate in the OS' system ca-certificates.

Because many 3rd party services use LE's SSL certificates, we need to add LE's ISRG Root X1 to the set of trusted X509 certificates.

```dart
Future<void> _addLERootCertificate() async {
  if (Platform.isAndroid){
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    // if android version is prior to 7.1.1
    if (androidInfo.version.sdkInt <= 25){
      try {
        var isrgX1 = await rootBundle.loadString('assets/ca/isrgrootx1.pem');
        SecurityContext.defaultContext.setTrustedCertificatesBytes(ascii.encode(isrgX1));
      } catch (e) {/* ignore errors */}
    }
  }
}
```

You can find the certificate in `"assets/ca/isrgrootx1.pem"`

You can verify the certificate from\
https://letsencrypt.org/certificates/

You can also verify that this exact certificate was added to Android's system ca-certificates for versions >= 7.1.1\
https://android.googlesource.com/platform/system/ca-certificates/+/51300a813051dcaaf3dc07000e92ed40a27a2b21/files/6187b673.0

You can read more about this issue:
1. https://letsencrypt.org/2020/11/06/own-two-feet.html#if-you-are-an-app-developer
2. https://community.letsencrypt.org/t/mobile-client-workarounds-for-isrg-issue/137807
3. https://github.com/square/okhttp/issues/6403
4. https://stackoverflow.com/questions/69511057/flutter-on-android-7-certificate-verify-failed-with-letsencrypt-ssl-cert-after-s