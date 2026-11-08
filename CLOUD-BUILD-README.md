# PCT App — APK banao (GitHub Actions, phone se)

Ye zip wahi Phase 1 project hai, bas `.github/workflows/build-apk.yml`
andar add hai. Is se APK GitHub ke computer par banta hai — laptop,
Android Studio ya kisi permission ki zaroorat nahi.

## Steps (phone ke Chrome se, desktop-site mode on kar lena)
1. github.com par account banao / login karo, phir **New repository**
   banao (naam: `pct-app`, Public).
2. Repo kholo → **Add file → Upload files** → `pct_app` folder ke
   ANDAR ki saari files/folders upload karo (folder khud nahi,
   uska content — taake `.github/workflows/build-apk.yml` repo
   ki root par ho). **Commit changes** dabao.
3. Upar **Actions** tab kholo → **Build APK** → **Run workflow**.
4. 5–10 minute wait karo. Green tick aaye to job kholo →
   neeche **Artifacts** me `pct-app-debug-apk` download karo →
   andar `app-debug.apk` hogi. Phone par install karo.
5. Pehli dafa app khulegi to Firebase setup screen dikhayegi —
   ye normal hai. Live login ke liye Firebase project +
   `google-services.json` chahiye (steps: README.md).

## Notes
- Private repo par bhi free minutes (2,000/month) me ban jata hai.
- Har dafa code badlo to dobara **Run workflow** karna — naya APK
  ban jayega. Release/signing baad me (Phase 2 se pehle).
