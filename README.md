# Дэмбээ (Dembee Auction)

Монголын уламжлалт дуудлага худалдааны Flutter + Firebase апп.

## Технологи

- **Flutter** + Dart
- **Firebase** Authentication + Cloud Firestore
- **GoRouter** — navigation
- **Material 3** — dark theme + gold accent

## Эхлэх

Дэлгэрэнгүй заавар: [SETUP.md](SETUP.md)

```bash
flutter pub get
flutterfire configure
flutter run
```

## Одоогийн төлөв

| Функц | Төлөв |
|-------|--------|
| Төслийн бүтэц | ✅ |
| Dark theme + gold | ✅ |
| Firebase Auth (login/register) | ✅ |
| Auction жагсаалт (realtime) | ✅ |
| Bid (+1–+5) | ✅ |
| Countdown timer | ✅ |
| Auction дуусах + bid хаах | ✅ |
| Winner тодорхойлох | ✅ |
| Bid history | ✅ |
| Profile (ялсан + санал) | ✅ |
| Firestore security rules | ✅ |
| Admin panel | ⏳ |
| Notifications | ⏳ |

## Аюулгүй байдал

- Service account key-г **хэзээ ч** commit хийхгүй
- Firestore rules заавал тохируулна
- Дэлгэрэнгүй: [SETUP.md](SETUP.md#8-аюулгүй-байдлын-дүрэм)
