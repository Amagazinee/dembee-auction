# Portrait Submit

> **ДЭМБЭЭ (`dembee-auction`)-ээс тусдаа төсөл.**  
> Зөвхөн **овог**, **нэр**, **цээж (portrait) зураг** илгээнэ. Өөр профайл/auth хадгалахгүй.

## Дэлгэц (2)

1. **Илгээх** — овог, нэр, portrait зураг (камер/галерей) → «Илгээх»
2. **Амжилт** — баталгаажуулалт + «Шинээр илгээх»

## Ажиллуулах

```bash
cd portrait_submit
flutter pub get
flutter run
```

## Линкээр түгээх (store-гүй)

### Android

```bash
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

APK-г Firebase App Distribution эсвэл Hosting линкээр өгнө.

### iOS

- **TestFlight** урилгын линк (санал болгох), эсвэл
- **Ad Hoc** + Firebase App Distribution (UDID бүртгэлтэй төхөөрөмж)

## Хадгалалт (одоо)

MVP: төхөөрөмжийн `Documents/submissions/` дотор зураг + JSON.

Дараа нь `SubmitService`-ийг Firebase Storage + Firestore руу солиход бэлэн.

## Бүтэц

```
portrait_submit/
├── lib/
│   ├── main.dart
│   ├── theme/app_theme.dart
│   ├── models/submission.dart
│   ├── services/submit_service.dart
│   └── screens/
│       ├── submit_screen.dart
│       └── success_screen.dart
└── README.md
```
