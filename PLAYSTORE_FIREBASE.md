# Play Store AAB — Firebase заавал тохируулах

Play Store-оос татсан апп **"Firebase тохируулаагүй"** гэж гарвал `lib/firebase_options.dart` файл placeholder (`YOUR_PROJECT_ID`) байна гэсэн үг.

## Засах (Windows)

### 1. FlutterFire configure

```cmd
cd C:\Users\user\dembee-auction
dart pub global activate flutterfire_cli
firebase login
flutterfire configure --project=dembee-auction
```

- Platform: **Android**
- Package: **com.dembee.auction**

Шалгах: `lib\firebase_options.dart` дотор `projectId: 'dembee-auction'` байх ёстой (`YOUR_PROJECT_ID` биш).

`android\app\google-services.json` файл үүссэн эсэхийг шалгана.

### 2. SHA fingerprint (чухал!)

Firebase Console → Project settings → Android app (`com.dembee.auction`) → Add fingerprint:

**Upload key** (локал keystore):

```cmd
"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v -keystore C:\Users\user\dembee-upload-key.jks -alias upload
```

**Play App Signing key** (Play Console):

`Release` → `Setup` → `App signing` → SHA-1 certificate

Хоёуланг нь Firebase-д нэмнэ.

### 3. Шинэ AAB build

`pubspec.yaml`:

```yaml
version: 1.0.0+4
```

```cmd
flutter clean
flutter pub get
flutter build appbundle --release
```

### 4. Play Console upload

- Closed testing → шинэ release
- `app-release.aab` upload (Version **4**)
- Rollout

## Ирээдүйд

AAB build хийхээс **өмнө** `firebase_options.dart` зөв эсэхийг шалгана:

```cmd
findstr dembee-auction lib\firebase_options.dart
```

Үр дүн гарвал бэлэн. `YOUR_PROJECT_ID` гарвал `flutterfire configure` дахин ажиллуулна.
