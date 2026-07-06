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

### Апп icon (launcher)

`assets/images/logo.png`-аас Android/iOS/Web icon автоматаар үүсгэнэ:

```powershell
dart run flutter_launcher_icons
```

Дараа нь аппыг **бүрэн дахин суулгах** (hot reload хангалтгүй):

```powershell
flutter run --no-enable-impeller
```

Эмулятор дээр хуучин Flutter icon харагдвал: апп устгаад дахин `flutter run` хийнэ.

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

### 4.1 Firebase CLI (terminal-аас deploy)

```powershell
# 1. Нэг удаа нэвтрэх
firebase login

# 2. Төсөл сонгох (репо дотор .firebaserc байвал алгасаж болно)
cd C:\Users\user\dembee_app
firebase use dembee-auction

# 3. Rules болон indexes publish
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

`No currently active project` алдаа гарвал:
```powershell
firebase use --add
```
→ жагсаалтаас **dembee-auction** сонго → alias: `default`

Эсвэл шууд:
```powershell
firebase deploy --only firestore:rules --project dembee-auction
```

### 4.2 Cloud Functions (ялагч тодруулах + үе шилжилт)

Дуудлагын lifecycle (ялагч тодруулах, 8 үе шилжих) **зөвхөн сервер** дээр ажиллана.

#### Blaze төлөвлөгөө (заавал)

Cloud Functions, Cloud Scheduler, Cloud Tasks deploy хийхийн тулд төсөл **Blaze (pay-as-you-go)** байх ёстой. Spark (үнэгүй) дээр дараах алдаа гарна:

```
Your project must be on the Blaze plan...
Required API artifactregistry.googleapis.com can't be enabled
```

**Шилжих:**
1. https://console.firebase.google.com/project/dembee-auction/usage/details
2. **Upgrade project** → Blaze сонго
3. Төлбөрийн карт холбоно (Google Cloud billing)

**Зардал:** Beta (10–20 хэрэглэгч) ихэвчлэн сарын **$0–5** орчим. Ихэнх үйлчилгээнд үнэгүй хязгаар үлдэнэ. Google Cloud Console → **Billing → Budgets & alerts** дээр сарын $10 хязгаар тавьж болно.

**Blaze-гүйгээр одоо хийж болох зүйлс:**
```powershell
firebase deploy --only firestore:rules,firestore:indexes,storage --project dembee-auction
```
Апп, санал өгөх, админ самбар, **зураг upload** ажиллана. Ялагч тодруулах: админ → Дуудлага tab → «Ялагч тодруулах» товч (Cloud Functions deploy хийхээс өмнө).

#### Blaze одоо идэвхжүүлэх (3 алхам)

**Алхам 1 — Blaze сонгох** (2 минут, зөвхөн та хийж чадна)

1. Нээх: https://console.firebase.google.com/project/dembee-auction/usage/details
2. **Modify plan** / **Upgrade** → **Blaze** сонго
3. Төлбөрийн карт холбоно
4. (Зөвлөмж) Google Cloud Console → Billing → **Budget $10/сар** alert тавих

**Алхам 2 — Firebase нэвтрэх** (компьютер дээрээ)

```bash
npx firebase-tools@14 login
```

**Алхам 3 — Deploy**

```bash
# Linux / macOS
./scripts/deploy-blaze.sh

# Windows (PowerShell)
cd functions; npm install; npm run build; cd ..
npx firebase-tools@14 deploy --only functions,firestore:rules,firestore:indexes --project dembee-auction
```

Deploy амжилттай болсны дараа Firebase Console → **Functions** таб дээр 3 функц харагдана.

#### Deploy (Blaze дээр) — дэлгэрэнгүй

```powershell
cd C:\Users\user\dembee_app\functions
npm install
cd ..
firebase deploy --only functions,firestore:rules,firestore:indexes --project dembee-auction
```

**Функцүүд** (`asia-southeast1` бүс):
| Функц | Зориулалт |
|-------|-----------|
| `processAuctionTask` | Task queue — төлөвлөсөн эхлэх + lifecycle шалгалт |
| `scheduleAuctionLifecycle` | Дуудлага өөрчлөгдөхөд дараагийн шалгалт төлөвлөнө |
| `sweepAuctionLifecycle` | Минут бүр: pending идэвхжүүлэх + lifecycle sweep |

Deploy дараа шинэ index (`status` + `startsAt`, `status` + `winCountdownEndsAt`) publish хийнэ.

### 4.3 Firebase Storage (дуудлагын зураг)

Spark төлөвлөгөөнд ажиллана (5GB хүртэл үнэгүй).

```powershell
firebase deploy --only storage --project dembee-auction
```

Админ «Шинэ дуудлага нэмэх» дээр зураг сонгоход `auctions/{id}/cover.jpg` руу upload хийнэ.

---

#### Локал тест (Blaze шаардлагагүй)

Functions-ийг компьютер дээрээ турших:

```powershell
cd C:\Users\user\dembee_app\functions
npm install
npm run build
cd ..
firebase emulators:start --only functions,firestore --project dembee-auction
```

Аппыг emulator-той холбохын тулд `lib/main.dart` эсвэл `firebase_service.dart` дээр Firestore/Functions emulator host тохируулах шаардлагатай (зөвхөн dev).

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
endsAt: timestamp      // дуудлагын эцсийн хязгаар (30 хоног)
status: "pending" | "active" | "closed"
phase: number           // 1–8
phaseStartedAt: timestamp
winCountdownEndsAt: timestamp
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

---

## 7.1 «Тохиргоо шаардлагатай» — апп ажиллахгүй

Энэ дэлгэц гарвал **`lib/firebase_options.dart` дээр `YOUR_API_KEY` placeholder** байна гэсэн үг.
Firestore Console дээр өгөгдөл байсан ч **локал апп** Firebase-тэй холбогдоогүй.

### Хурдан засвар (PowerShell)

```powershell
cd C:\Users\user\dembee-auction
powershell -ExecutionPolicy Bypass -File scripts\setup-firebase.ps1
flutter pub get
flutter run --no-enable-impeller
```

### Гараар шалгах

| Файл | Байх ёстой |
|------|------------|
| `lib\firebase_options.dart` | `YOUR_API_KEY` **байхгүй** |
| `android\app\google-services.json` | Файл байна |

`firebase_options.dart` нээж харна — `projectId: 'dembee-auction'` гэх мэт **бодит** утга байх ёстой.

### Гараар (flutterfire ажиллахгүй бол)

1. https://console.firebase.google.com/project/dembee-auction/settings/general
2. **Android app** → package name: `com.example.dembee_app`
3. `google-services.json` татаж `android\app\` дотор тавина
4. Дахин: `flutterfire configure --project=dembee-auction`
5. Апп бүрэн дахин ажиллуулна: `q` → `flutter run --no-enable-impeller`

### Түгээмэл алдаа

| Алдаа | Шийдэл |
|-------|--------|
| `flutterfire` олдсонгүй | `$env:Path += ";$env:LOCALAPPDATA\Pub\Cache\bin"` |
| Web сонгосон | Дахин configure → **Android** сонго |
| Өөр хавтас | `cd C:\Users\user\dembee-auction` шалгана |
| Hot reload | `q` дарж бүрэн дахин `flutter run` |

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

**Арга 1 — Seed admin бүртгэл (хурдан)**

1. Апп дээр **Бүртгүүлэх** → имэйл: `admin@dembee.mn`, нууц үг: `admin123` (эсвэл өөр)
2. Firestore rules publish хийсэн эсэхийг шалгана (`firebase deploy --only firestore:rules`)
3. Нэвтэрсний дараа:
   - App bar дээр **АДМИН** badge
   - **Шинэ дуудлага нэмэх** товч
   - Цэс → **удирдлага** → **Админ самбар**

**Арга 2 — Одоо байгаа аккаунтыг admin болгох**

Firestore → `users` → таны UID document → `role` талбар:
```
role: "admin"
```
(Console-оос гараар засна — хэрэглэгч өөрөө role өөрчилж чадахгүй)

**Өөр admin имэйл нэмэх:** `lib/core/constants/app_constants.dart` дотор `adminSeedEmails` жагсаалтад нэмж, `firebase/firestore.rules` дотор `isSeedAdminEmail()` функцийг шинэчилнэ.

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
