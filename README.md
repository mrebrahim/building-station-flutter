# Building Station - Flutter WebView App

تطبيق WebView يفتح: https://building-station-mobile-hub.lovable.app/

---

## 🚀 خطوات الرفع على Codemagic

### 1. ارفع المشروع على GitHub
```bash
git init
git add .
git commit -m "Initial commit: Building Station WebView App"
git remote add origin https://github.com/YOUR_USERNAME/building-station-app.git
git push -u origin main
```

### 2. اربط GitHub بـ Codemagic
1. ادخل على [codemagic.io](https://codemagic.io)
2. سجّل دخول بـ GitHub
3. اضغط **"Add application"**
4. اختار الـ repo: `building-station-app`
5. اختار **"Flutter App"**
6. اضغط **"Finish: Add application"**

### 3. ابدأ الـ Build
- اختار workflow: **"Android Debug (No Signing Required)"** للتجربة
- اضغط **"Start new build"**
- انتظر ~10 دقائق
- نزّل الـ APK من قسم **Artifacts**

---

## 📁 هيكل المشروع

```
building_station/
├── lib/
│   └── main.dart          ← الكود الرئيسي
├── android/               ← إعدادات Android
├── ios/                   ← إعدادات iOS
├── assets/                ← الأيقونات والـ Splash
├── pubspec.yaml           ← Dependencies
└── codemagic.yaml         ← إعدادات البناء
```

---

## 🎨 تغيير الأيقونة

1. ضع أيقونة `1024x1024 PNG` في `assets/icon.png`
2. ضع صورة Splash `1024x1024 PNG` في `assets/splash.png`
3. Codemagic سيولد الأيقونات تلقائياً

---

## ✅ مميزات التطبيق

- 🌐 WebView كامل لرابط التطبيق
- ⬅️ زر Back يرجع في تاريخ المتصفح
- 📶 شاشة "لا يوجد إنترنت" مع زر إعادة المحاولة
- ⏳ Loading spinner أثناء التحميل
- 📱 يدعم Portrait و Landscape
- 🌙 Dark theme

---

## 🔧 Build Workflows في Codemagic

| Workflow | الوصف | يحتاج |
|----------|--------|--------|
| `android-debug-workflow` | APK للتجربة | لا شيء |
| `android-workflow` | APK/AAB للنشر | Keystore |
| `ios-workflow` | IPA للنشر | Apple Developer Account + Mac |
