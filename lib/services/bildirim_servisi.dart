import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'dart:typed_data';

class BildirimServisi {
  static final BildirimServisi _instance = BildirimServisi._internal();
  factory BildirimServisi() => _instance;
  BildirimServisi._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Bildirim kanalı detayları
  static const AndroidNotificationChannel kanal = AndroidNotificationChannel(
    'ilac_takip_v2',
    'İlaç Bildirimleri',
    description: 'İlaç zamanı hatırlatmaları',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
    showBadge: true,
  );

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    // Android bildirim kanalını oluştur
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(kanal);

    const AndroidInitializationSettings androidAyarlari = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosAyarlari = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings baslatmaAyarlari = InitializationSettings(
      android: androidAyarlari,
      iOS: iosAyarlari,
    );

    await flutterLocalNotificationsPlugin.initialize(
      baslatmaAyarlari,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("📢 BİLDİRİM GELDİ/TIKLANDI: ${response.payload}");
      },
    );

    // İzinleri iste
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? notifGranted = await androidImplementation.requestNotificationsPermission();
      print("📱 Bildirim izni: ${notifGranted == true ? 'VERİLDİ ✅' : 'REDDEDİLDİ ❌'}");

      final bool? alarmGranted = await androidImplementation.requestExactAlarmsPermission();
      print("⏰ Exact Alarm izni: ${alarmGranted == true ? 'VERİLDİ ✅' : 'REDDEDİLDİ ❌'}");

      // Exact alarm izninin gerçekten verilip verilmediğini kontrol et
      final bool? canSchedule = await androidImplementation.canScheduleExactNotifications();
      print("🔧 Exact alarm planlanabilir mi: ${canSchedule == true ? 'EVET ✅' : 'HAYIR ❌'}");

      if (canSchedule != true) {
        print("⚠️ UYARI: Exact alarm izni verilmemiş! Ayarlardan manuel açın.");
      }
    }
  }

  // 1. ANA VAKİT BİLDİRİMİ (Detaylı içerikle)
  Future<void> anaVakitBildirimiKur(String vakit, int saat, int dakika) async {
    int id = 0;
    if (vakit == "Sabah") id = 1;
    if (vakit == "Öğle") id = 2;
    if (vakit == "Akşam") id = 3;
    if (vakit == "Gece") id = 4;

    // İlaçları çek ve bu vakitte içilenleri listele
    String icerik = await _vakitIlaclariGetir(vakit);

    await _bildirimPlanla(
        id,
        "$vakit İlaç Vakti ⏰",
        icerik,
        saat,
        dakika
    );
  }

  // Yardımcı: O vakitte içilecek ilaçları listele
  Future<String> _vakitIlaclariGetir(String vakit) async {
    try {
      // Firestore'dan verileri çekmek için import gerekli
      // Bu fonksiyon sadece örnek, gerçek kullanımda import ekleyin
      return "Lütfen $vakit ilaçlarınızı almayı unutmayın.";
    } catch (e) {
      return "Lütfen $vakit ilaçlarınızı almayı unutmayın.";
    }
  }

  // 2. İLAÇ HATIRLATICILARI
  // NOT: Bildirimler her gün çalışır, ancak gün kontrolü gunluk_plan_ekrani.dart'ta yapılır
  Future<void> hatirlaticiKur(int ilacBaseId, String ilacAdi, String kisi, String vakit, int saat, int dakika) async {
    int vakitOffset = 0;
    if (vakit == "Sabah") vakitOffset = 10000;
    if (vakit == "Öğle") vakitOffset = 20000;
    if (vakit == "Akşam") vakitOffset = 30000;
    if (vakit == "Gece") vakitOffset = 40000;

    int temelId = ilacBaseId + vakitOffset;

    await _bildirimPlanla(temelId + 1, "İlaç İçilmedi!", "$kisi, $ilacAdi ilacını içtin mi?", saat, dakika + 15);
    await _bildirimPlanla(temelId + 2, "İlaç İçilmedi!", "$kisi, $ilacAdi ilacını içtin mi?", saat, dakika + 30);
    await _bildirimPlanla(temelId + 3, "Lütfen İlacı İç", "$kisi, $ilacAdi ilacını hala içmedin mi?", saat, dakika + 45);
  }

  // 3. HATIRLATICILARI İPTAL ET
  Future<void> hatirlaticilariIptalEt(int ilacBaseId, String vakit) async {
    int vakitOffset = 0;
    if (vakit == "Sabah") vakitOffset = 10000;
    if (vakit == "Öğle") vakitOffset = 20000;
    if (vakit == "Akşam") vakitOffset = 30000;
    if (vakit == "Gece") vakitOffset = 40000;

    int temelId = ilacBaseId + vakitOffset;

    await flutterLocalNotificationsPlugin.cancel(temelId + 1);
    await flutterLocalNotificationsPlugin.cancel(temelId + 2);
    await flutterLocalNotificationsPlugin.cancel(temelId + 3);
    print("Hatırlatıcılar iptal edildi: ${temelId + 1}, ${temelId + 2}, ${temelId + 3}");
  }

  // PLANLAMA FONKSİYONU - EN AGRESİF VERSİYON
  Future<void> _bildirimPlanla(int id, String baslik, String icerik, int saat, int dakika) async {
    // Dakika taşması kontrolü
    int ekSaat = dakika ~/ 60;
    int netDakika = dakika % 60;
    int netSaat = (saat + ekSaat) % 24;

    // ŞU ANKİ ZAMAN
    final tz.TZDateTime simdi = tz.TZDateTime.now(tz.local);

    // HEDEF ZAMANI OLUŞTUR
    tz.TZDateTime hedefZaman = tz.TZDateTime(
      tz.local,
      simdi.year,
      simdi.month,
      simdi.day,
      netSaat,
      netDakika,
      0,
      0,
    );

    // Eğer hedef saat geçmişte kaldıysa yarına ekle
    if (hedefZaman.isBefore(simdi) || hedefZaman.isAtSameMomentAs(simdi)) {
      hedefZaman = hedefZaman.add(const Duration(days: 1));
    }

    // DETAYLI LOG
    final Duration fark = hedefZaman.difference(simdi);
    print("═══════════════════════════════════════");
    print("🔔 BİLDİRİM PLANLANIYOR");
    print("   ID: $id");
    print("   Başlık: $baslik");
    print("   Şu an: ${simdi.hour}:${simdi.minute.toString().padLeft(2,'0')}:${simdi.second}");
    print("   Hedef: ${hedefZaman.hour}:${hedefZaman.minute.toString().padLeft(2,'0')}");
    print("   Kalan: ${fark.inMinutes} dakika ${fark.inSeconds % 60} saniye");
    print("   Unix Timestamp: ${hedefZaman.millisecondsSinceEpoch}");
    print("═══════════════════════════════════════");

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        baslik,
        icerik,
        hedefZaman,
        NotificationDetails(
          android: AndroidNotificationDetails(
            kanal.id,
            kanal.name,
            channelDescription: kanal.description,
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            when: hedefZaman.millisecondsSinceEpoch,
            usesChronometer: false,
            chronometerCountDown: false,
            color: const Color(0xFF009688),
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
            enableLights: true,
            ledColor: const Color(0xFF00FF00),
            ledOnMs: 1000,
            ledOffMs: 500,
            visibility: NotificationVisibility.public,
            category: AndroidNotificationCategory.alarm,
            fullScreenIntent: true,
            autoCancel: false,
            ongoing: false,
            channelShowBadge: true,
            // Bu satır çok önemli - tam ekran bildirim için
            additionalFlags: Int32List.fromList([4, 32]),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      print("✅ Bildirim başarıyla kuruldu!");
    } catch (e) {
      print("❌ BİLDİRİM KURMA HATASI: $e");
      rethrow;
    }
  }
}