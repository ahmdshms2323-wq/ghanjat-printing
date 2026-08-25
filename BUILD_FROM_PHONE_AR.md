# بناء تطبيق غنجات من التلفون فقط

هذه النسخة مجهزة للبناء السحابي على Codemagic.

## الخطوات المختصرة
1. افتح GitHub من المتصفح في التلفون وأنشئ Repository جديد باسم:
   ghanjat-printing
2. ارفع كل ملفات هذا المشروع داخل الـ Repository.
3. افتح Codemagic وسجل الدخول بحساب GitHub.
4. اختر Add application.
5. اختر GitHub ثم Repository باسم ghanjat-printing.
6. سيكتشف Codemagic ملف codemagic.yaml.
7. شغّل Workflow باسم:
   Ghanjat Android APK
8. بعد نجاح البناء، افتح Artifacts.
9. نزّل الملف:
   app-debug.apk
10. افتح APK في تلفون Android وثبته.

إذا ظهر تحذير أمني عند التثبيت، اسمح للمتصفح أو مدير الملفات بتثبيت التطبيقات من هذا المصدر.
