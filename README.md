# PAK Cyber Team — Mobile App (Phase 3)

Flutter app (Android + iOS, one codebase). Fully INDEPENDENT of the
website — it uses Firebase for login, data and notifications.

## What Phase 1 has
- Login / Signup / Email verification / Forgot password
- Strict input validation (name letters only max 50, email max 150,
  password 8–72) + login throttle (5 fails -> 15 min lock)
- Home shell with bottom nav (Home, CTFs, Courses, Rooms, Profile)
- PCT dark + gold theme (same as the website)
- FCM push wiring (token saved to the user doc)

## What Phase 2 adds
- **CTFs tab**: lists competitions from Firestore `ctfs`
  (own PCT CTFs first, then upcoming international ones).
  Tap a CTF for dates, format and a copyable event link.
- **Courses tab**: courses from Firestore `courses`; tap one to see
  its modules (`courses/{id}/modules`). The final exam module stays
  locked until all other modules are complete.
- **Rooms tab**: rooms + labs from Firestore `rooms` (filter: All /
  Rooms / Labs). Tap a room to see its challenges
  (`rooms/{id}/challenges`) — sequential: each challenge unlocks
  only after the previous one is solved.
- **Notifications**: bell on Home. The app requests notification
  permission, saves the FCM token to the user's Firestore doc, and
  shows received push messages in an in-app list (newest first).
- Progress (modules done / challenges solved) is stored on the
  device only in Phase 2 — nothing is sent to a server.
- Empty collections show "No CTFs yet" / "No courses yet" /
  "No rooms yet" — no fake sample data is ever shown as real.

## What Phase 3 adds
- **Leaderboard**: Rank | Name | Points from Firestore
  `leaderboard` (admin-maintained). Top 3 highlighted gold / silver /
  bronze, and your own row is marked "You". Tabs for Global / Rooms /
  Labs appear only when the data carries those scopes; otherwise
  Global only, with a note that the other boards appear once scores
  are published for them. If the `leaderboard` collection is empty,
  the app best-effort derives the board from `users` ordered by
  points — with the default rules that read is blocked, so the board
  honestly shows "No scores yet" instead of inventing scores.
- **Certificates**: your own certificates from Firestore
  `certificates` (where userId == your uid). Each card shows title,
  unique code, issue date and category. Tap one for a detail card
  with the verify code and a Download button that saves the
  certificate image to Photos (needs the `gal` package, already
  added; iOS asks for Photos permission). Without an image URL the
  detail page is a shareable card with a "Copy Certificate Code"
  button — no fake certificate image is ever generated.
- Reachable from Home cards ("Leaderboard", "My Certificates") and
  from Profile ("My Certificates"). Bottom nav unchanged.

## Firestore collections (create in the Firebase console)
- `ctfs`: {name, startDate, endDate, format, url, description, isOwn}
  (startDate/endDate: Timestamp or ISO date string)
- `courses`: {title, description, level, duration, moduleCount}
- `courses/{courseId}/modules`: {title, order, isFinal}
- `rooms`: {name, description, difficulty, points, isLab, category}
- `rooms/{roomId}/challenges`: {title, points, order}
- `leaderboard`: {userId, displayName, points, rank, scope}
  (scope: 'global', 'rooms' or 'labs'; written by the admin app)
- `certificates`: {userId, title, code, issueDate, category, imageUrl}
  (issueDate: Timestamp or ISO date string; issued by the admin app)
- `users`: {name, email, role, createdAt, fcmToken, fcmUpdatedAt}
- Paste the rules from `firestore.rules` (signed-in users read the
  public collections; only the user themself writes their own doc).

## Firebase setup (owner does this once, ~5 minutes)
1. Go to https://console.firebase.google.com -> create a project (free).
2. Add an Android app, package name: `com.pakcyberteam.app`
   (iOS later: bundle id `com.pakcyberteam.app`).
3. Download `google-services.json` -> put it in `android/app/`.
4. Authentication -> Sign-in method -> enable Email/Password.
5. Firestore -> create database -> paste the rules from `firestore.rules`.
6. Rebuild: `flutter run` / `flutter build apk --debug`.

Without `google-services.json` the app still opens and shows the
setup steps instead of crashing.

## Build
- `flutter pub get`
- `flutter analyze`
- `flutter build apk --debug` (Android)
- iOS needs a Mac + Apple Developer account ($99/year).

## Later phases
- Phase 4: SEPARATE admin app.
- Website bridge (later): when the website runs on hosting/VPS,
  new rooms/courses sync to both app and website.
