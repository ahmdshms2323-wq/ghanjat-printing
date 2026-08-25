# بناء تطبيق غنجات كـ APK

هذه النسخة تحتوي على مجلد Android كامل، لذلك لا تحتاج إلى تشغيل `flutter create .`.

## المطلوب على الكمبيوتر
- Flutter SDK
- Android Studio + Android SDK
- اتصال إنترنت أول مرة لتنزيل الحزم وGradle

## الأوامر
افتح Terminal داخل مجلد المشروع ثم شغّل:

```bash
flutter doctor
flutter pub get
flutter build apk --release
```

بعد نجاح البناء ستجد ملف التثبيت هنا:

`build/app/outputs/flutter-apk/app-release.apk`

## تثبيته على الهاتف
انقل `app-release.apk` للهاتف وافتحه ثم اسمح بالتثبيت من هذا المصدر عند طلب Android.

## ملاحظة التوقيع
النسخة الحالية تستخدم debug signing داخل build release لتسهيل الاختبار الشخصي. قبل النشر في Google Play يجب إنشاء مفتاح Release خاص بك.
