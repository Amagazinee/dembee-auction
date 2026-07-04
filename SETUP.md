# Дэмбээ (Dembee Auction) — Суулгах заавар

Энэ заавар нь төслийг **аюулгүй, зөв дарааллаар** тохируулахад зориулагдсан.

---

## 1. Шаардлага

| Зүйл | Хувилбар |
|------|----------|
| Flutter SDK | 3.12+ |
| Dart | 3.12+ |
| Firebase төсөл | Console дээр үүсгэсэн |
| Git | Суулгасан |

Шалгах:
```bash
flutter --version
git --version
```

---

## 2. Төслийг татах

```bash
git clone https://github.com/Amagazinee/dembee-auction.git
cd dembee-auction
flutter pub get
```

---

## 3. Firebase тохируулах

### 3.1 Firebase Console (https://console.firebase.google.com)

1. **Шинэ төсөл** үүсгэнэ (жишээ нь: `dembee-auction`)
2. **Authentication** → Sign-in method → **Email/Password** идэвхжүүлнэ
3. **Cloud Firestore** → Database үүсгэнэ (test mode биш — доорх rules ашиглана)

### 3.2 FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

**Windows (PowerShell):**
```powershell
$env:Path += ";$env:LOCALAPPDATA\Pub\Cache\bin"
dart pub global run flutterfire_cli:flutterfire configure
```

**macOS/Linux:**
```bash
flutterfire configure
```

- Firebase төслөө сонгоно
- Platform: **Android** (Chrome ашиглахгүй бол Web хэрэггүй)
- Үүсэх файлууд: `lib/firebase_options.dart`, `android/app/google-services.json`

### 3.3 Android

`flutterfire configure` ихэвчлэн `google-services.json` файлыг автоматаар тавина.

Хэрэв гараар хийвэл:
- Firebase Console → Project settings → Android app
- `google-services.json` татаж `android/app/` дотор тавина

---

## 4. Firestore Security Rules болон Indexes

**Rules:** Firebase Console → Firestore → Rules → `firebase/firestore.rules` хуулж **Publish**

**Indexes:** Firebase Console → Firestore → Indexes → `firebase/firestore.indexes.json` ашиглана
эсвэл `firebase deploy --only firestore:indexes` (Firebase CLI суулгасан бол)

**Чухал:** Rules болон Indexes тавихгүй бол бүртгэл/санал өгөх ажиллахгүй.

---

## 5. Firestore бүтэц

### users/{uid}
```
name: string
phone: string
email: string
createdAt: timestamp
role: "user" | "admin"
```

### auctions/{docId}
```
title: string
price: number          // эхлэх үнэ (0 эсвэл бага)
endsAt: timestamp      // дуусах цаг
status: "pending" | "active" | "closed"
lastBidder: string?
lastBidUid: string?
lastBidAmount: number
updatedAt: timestamp?
winnerUid: string?
winnerName: string?
finalPrice: number?
```

### auctionHistory/{docId} (удахгүй)
```
auctionId: string
userUid: string
userName: string
amount: number
createdAt: timestamp
```

---

## 6. Тест auction нэмэх (Console-оор)

Firestore → `auctions` collection → Add document:

```
title: "Мөнгөн аяга"
price: 0
endsAt: (одоо + 1 цаг)
status: "active"
lastBidAmount: 0
```

---

## 7. Апп ажиллуулах

```bash
flutter devices
flutter run
```

Android эмулятор сонгоно. Chrome сонгохгүй (Web тохируулаагүй бол).

### Windows — эмулятор алдаа

`Can't find service: package` гарвал:
```powershell
powershell -ExecutionPolicy Bypass -File scripts\windows-emulator-fix.ps1
```

Дараа нь `flutter run`. `gphone16k` эмуляторыг устгаад **Pixel 7 + API 34** ашиглана.

### Хар дэлгэц (Impeller алдаа)

Эмулятор хар хэвээр бол:
```powershell
flutter run -d emulator-5554 --no-enable-impeller
```

Эсвэл Device Manager → Pixel 7 → Edit → Graphics: **Hardware - GLES 2.0**

---

## 8. АЮУЛГҮЙ БАЙДЛЫН ДҮРЭМ

### ✅ Хийж болно
- Кодыг GitHub руу push хийх
- `firebase_options.dart` commit хийх (package name-ээр хязгаарлагдсан)
- `google-services.json` commit хийх (өөрийн төсөл бол)

### ❌ ХЭЗЭЭ Ч бүү хий
- Service account JSON (`*serviceAccount*.json`) commit хийх
- GitHub token, нууц үгийг чатанд илгээх
- Firestore rules-ийг `allow read, write: if true` гэж үлдээх

### Admin эрх өгөх
Firestore → `users` → таны UID document → `role` талбар:
```
role: "admin"
```

---

## 9. Төслийн бүтэц

```
lib/
├── core/          # constants, errors, utils
├── models/        # UserModel, AuctionModel
├── providers/     # Auth state
├── routes/        # GoRouter
├── screens/       # UI дэлгэцүүд
├── services/      # Firebase, Auth, Auction
├── theme/         # Dark + gold theme
├── widgets/       # Дахин ашиглах widget
└── main.dart
```

---

## 10. Дараагийн алхмууд

1. ✅ Суурь бүтэц (одоо)
2. ⏳ Countdown timer бүрэн интеграци
3. ⏳ Auction дуусах + winner
4. ⏳ Bid history
5. ⏳ Admin panel
6. ⏳ Push notification

---

## Тусламж

Алдаа гарвал:
1. `flutter clean && flutter pub get`
2. `flutterfire configure` дахин ажиллуулах
3. Firebase Console дээр Auth, Firestore идэвхтэй эсэхийг шалгах
