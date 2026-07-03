# Horar v10 – aktuel lokation

Denne version bruger `geolocator` til at hente telefonens aktuelle position og vælge den som standard-lokation.

## Android

I `android/app/src/main/AndroidManifest.xml` skal følgende ligge som direkte børn af `<manifest>` – altså over `<application>`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

I `android/app/build.gradle` eller `android/app/build.gradle.kts` bør compileSdk være mindst 35:

```gradle
compileSdk 35
```

eller:

```gradle
compileSdkVersion 35
```

Installer evt. SDK 35:

```bash
sdkmanager --install "platforms;android-35" "build-tools;35.0.0"
```

## iOS

I `ios/Runner/Info.plist` skal der tilføjes:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Horar bruger din aktuelle position til at beregne det horariske kort.</string>
```

## Funktion

- Appen starter med at forsøge at hente aktuel lokation.
- Hvis det lykkes, indsættes `Aktuel lokation` øverst i lokationslisten og vælges automatisk.
- Hvis det fejler, bruges Rørvig som fallback.
- Knappen `Beregn horar` er deaktiveret, indtil spørgsmålsfeltet indeholder tekst.
