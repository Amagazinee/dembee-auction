# ДЭМБЭЭ — Онлайн Дуудлага Худалдааны Апп

> **Cursor Agent заавар.** Энэ файл Figma загварын бүрэн төлөвлөгөө.
> Төсөл: **Flutter + Firebase** (React биш).

---

## Товч танилцуулга

Монголын онлайн "penny auction" платформ. Хэрэглэгч санал багц худалдан аваад дуудлага худалдаанд оролцоно. Санал бүр үнийг ₮1–₮5-аар нэмж, ялагч тодрох хугацааг дахин эхлүүлнэ. Ямар ч үед хугацаа 0 болоход хамгийн сүүлд санал явуулсан хэрэглэгч ялагч болно.

---

## Технологийн стек (Flutter төсөл)

| Figma/React | Flutter төсөл |
|-------------|---------------|
| React + TypeScript | **Flutter + Dart** |
| Vite | `flutter run` / Gradle |
| Tailwind CSS | **Material 3** + `lib/theme/app_theme.dart` |
| Lucide React | **Material Icons** / `lucide_icons` (шаардлагатай бол) |
| pnpm | `flutter pub get` |

### Backend
- Firebase Authentication (Email/Password)
- Cloud Firestore (realtime)
- GoRouter (navigation)

---

## Файлын бүтэц (Flutter)

```
dembee_app/
├── CLAUDE.md                    ← энэ файл
├── lib/
│   ├── main.dart
│   ├── theme/app_theme.dart     ← theme.css орлуулагч
│   ├── core/constants/
│   │   ├── bid_packages.dart    ← санал багц
│   │   └── auction_phases.dart  ← 8 үе механик
│   ├── models/
│   ├── services/
│   ├── screens/
│   ├── widgets/
│   └── routes/app_router.dart
├── assets/images/
│   └── logo.png                 ← Figma Asset_1.png (ДЭМБЭЭ лого)
└── firebase/firestore.rules
```

---

## Design Tokens (Figma theme.css → Flutter)

### Өнгө

| Token | Hex | Flutter |
|-------|-----|---------|
| background | `#0c0c0e` | `AppTheme.background` |
| foreground | `#f0ead8` | `AppTheme.foreground` |
| card | `#141418` | `AppTheme.card` |
| primary (gold) | `#c9a84c` | `AppTheme.primary` |
| secondary | `#1e1e26` | `AppTheme.secondary` |
| muted-foreground | `#7a7468` | `AppTheme.mutedForeground` |
| destructive | `#e03e3e` | `AppTheme.destructive` |
| border | `rgba(255,255,255,0.08)` | `AppTheme.border` |
| input-background | `#1e1e26` | `AppTheme.inputBackground` |

### Фонт (fonts.css)

| Хэрэглээ | Font | Flutter |
|----------|------|---------|
| Гарчиг | **Fraunces** | `GoogleFonts.fraunces()` |
| Текст | **Manrope** | `GoogleFonts.manrope()` |
| Тоо/цаг | **JetBrains Mono** | `GoogleFonts.jetBrainsMono()` |

### Radius
- `--radius: 0.25rem` (4px) — `BorderRadius.circular(4)`

### Лого
- Figma: `src/imports/Asset_1.png`
- Flutter: `assets/images/logo.png` → `Image.asset('assets/images/logo.png')`

---

## Types (Dart models)

```dart
// BidRecord
{ user, price, ts }

// Auction
{
  id, title, image, retailValue, description?,
  currentPrice, totalBids, lastBidder,
  increment, phase, phaseStartedAt,
  winCountdownEndsAt, finished, winner,
  myBids, bidHistory[]
}

// AuthUser
{ name, email, phone, joinedAt, avatar, role: "user"|"admin" }

// SubView (navigation)
main | topup | purchases | transactions | feedback | privacy | terms | faq | help | delete | admin | add_auction

// Notif
{ id, kind, title, body, ts, read }
// kind: topup | phase | winner | new_auction | time_warning

// BidPkg
{ id, amount, price, bonus, popular }
```

---

## Дэлгэц / Компонентууд

| Figma/React | Flutter (төлөвлөгөө) |
|-------------|----------------------|
| AuthScreen | `lib/screens/auth/` |
| UserMenuDrawer | `lib/widgets/user_menu_drawer.dart` |
| AdminPanel | `lib/screens/admin/` |
| NotifDrawer | `lib/widgets/notif_drawer.dart` |
| TopUpView | `lib/screens/topup/topup_screen.dart` |
| AddAuctionView | `lib/screens/admin/add_auction_screen.dart` |
| PurchasesView | `lib/screens/profile/purchases_screen.dart` |
| TransactionsView | `lib/screens/profile/transactions_screen.dart` |
| FeedbackView | `lib/screens/profile/feedback_screen.dart` |
| FAQView | `lib/screens/profile/faq_screen.dart` |
| HelpView | `lib/screens/profile/help_screen.dart` |
| TextPageView | privacy / terms screens |
| DeleteAccountView | `lib/screens/profile/delete_account_screen.dart` |
| PhaseBar | `lib/widgets/phase_bar.dart` |
| DualTimer | `lib/widgets/dual_timer.dart` |
| AuctionCard | `lib/widgets/auction_card.dart` |
| App (root) | `lib/main.dart` + providers |

---

## Дуудлагын механик (8 үе)

| Үе | Үргэлжлэх | Ялагч тодрох |
|----|-----------|--------------|
| 1 | 2 цаг | 30 мин |
| 2 | 1 цаг | 30 мин |
| 3 | 1 цаг | 30 мин |
| 4 | 1 цаг | 30 мин |
| 5 | 30 мин | 10 мин |
| 6 | 30 мин | 1 мин |
| 7 | 30 мин | 10 сек |
| 8 | 30 мин | 3 сек |

### Дүрэм
- Санал бүр «Ялагч тодрох» хугацааг дахин эхлүүлнэ
- «Ялагч тодрох» 0 → **ЭЦСИЙН ЯЛАГЧ** (ямар ч үед)
- Үе дуусвал → дараагийн үе (ялагч тодрохгүй)
- Бүх дуудлага 1-р үеэс эхэлнэ

---

## Санал багц

| Санал | Үнэ |
|-------|-----|
| 10 | ₮10,000 |
| 20 | ₮18,000 |
| 40 | ₮30,000 ⭐ хамгийн алдартай |
| 60 | ₮45,000 |
| 100 | ₮65,000 |
| 200 | ₮110,000 |

Төлбөр: QPay, Golomt Bank (удахгүй)

---

## Нэвтрэлт (тест)

| Хэрэглэгч | И-мэйл | Нууц үг |
|-----------|--------|---------|
| Тест | bat@email.mn | bat123 |
| Админ | admin@dembee.mn | admin123 |

---

## App State (Provider/Riverpod төлөвлөгөө)

```
user: AuthUser?
auctions: Auction[]
credits: int              // үлдсэн санал (bidBalance)
feed: Feed[]
showMenu: bool
subView: SubView
myLeading: Set<int>
notifs: Notif[]
showNotif: bool
```

---

## Effects / Realtime (Firestore)

| React effect | Flutter хэрэгжилт |
|--------------|-------------------|
| Phase advancement (80ms) | Timer + Firestore transaction |
| Bot simulation | Cloud Function эсвэл admin (удаахгүй) |
| New auction notifications | FCM (удаахгүй) |
| Bid → timer reset | `winCountdownEndsAt` шинэчлэх |

---

## ЧУХАЛ анхааруулга (кодлохдоо)

1. **Auth form** — TextEditingController-ийг build дотор бүү үүсгэ (remount асуудал)
2. **bidHistory** — `auction.bidHistory ?? []` null-safe
3. **Phase advancement** — closure-д хуучин state бүү ашигла
4. **Зураг upload** — Firebase Storage (admin add auction)

---

## Хөгжүүлэлтийн дараалал

1. ✅ Firebase Auth + Firestore суурь
2. ✅ Энгийн bid (+1–₮5)
3. ⏳ Design tokens (өнгө, фонт) — `app_theme.dart`
4. ⏳ Санал багц (credits/bidBalance) + TopUp screen
5. ⏳ 8 үе механик + DualTimer + PhaseBar
6. ⏳ Figma UI (grid home, auction card)
7. ⏳ Admin panel
8. ⏳ QPay integration
9. ⏳ Push notifications

---

## Нэмэх боломжтой (хийгдээгүй)

- [ ] QPay API
- [ ] Push notification
- [ ] Дуудлага хайх / шүүх
- [ ] Хэрэглэгчийн профайл засах
- [ ] Bot simulation

---

## Coding Style

- Null-safe Dart
- Material 3 + AppTheme tokens ашиглах
- Figma өнгө/фонтыг `AppTheme`-ээс авч бүү hardcode хий
- Firestore StreamBuilder хадгалах
- Монгол хэл UI
- Аюулгүй: service account key commit хийхгүй
