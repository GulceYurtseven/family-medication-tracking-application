import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
class BildirimServisi {
  static final BildirimServisi _instance = BildirimServisi._internal();
  factory BildirimServisi() => _instance;
  BildirimServisi._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

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

// Bu kodu bildirim_servisi.dart dosyanızın init() metoduna ekleyin

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    // Alarm Manager başlat
    await AndroidAlarmManager.initialize();

    // Kanal oluştur
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(kanal);

    const AndroidInitializationSettings androidAyarlari =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosAyarlari = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings baslatmaAyarlari = InitializationSettings(
      android: androidAyarlari,
      iOS: iosAyarlari,
    );

    await flutterLocalNotificationsPlugin.initialize(baslatmaAyarlari);

    // Android 13+ için bildirim iznini iste
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Bildirim izni
      final bool? notificationResult =
      await androidImplementation.requestNotificationsPermission();
      print('📱 Bildirim izni: ${notificationResult ?? false ? "✅ Verildi" : "❌ Reddedildi"}');

      // Tam zamanlanmış alarm izni (Android 12+)
      final bool? exactAlarmResult =
      await androidImplementation.requestExactAlarmsPermission();
      print('⏰ Exact Alarm izni: ${exactAlarmResult ?? false ? "✅ Verildi" : "❌ Reddedildi"}');

      // İzin durumunu kontrol et
      if (notificationResult == false) {
        print('⚠️ UYARI: Bildirim izni reddedildi! Kullanıcı ayarlardan açmalı.');
      }

      if (exactAlarmResult == false) {
        print('⚠️ UYARI: Exact Alarm izni reddedildi! Zamanlanmış bildirimler çalışmayabilir.');
      }
    }
  }

  // 1. ANA VAKİT BİLDİRİMİ
  Future<void> anaVakitBildirimiKur(String vakit, int saat, int dakika) async {
    int id = 0;
    if (vakit == "Sabah") id = 1;
    if (vakit == "Öğle") id = 2;
    if (vakit == "Akşam") id = 3;
    if (vakit == "Gece") id = 4;

    await _bildirimPlanla(
      id,
      "$vakit İlaç Vakti ⏰",
      "$vakit ilaçlarınızı almayı unutmayın!",
      saat,
      dakika,
    );

    print("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓");
    print("📋 ANA BİLDİRİM KURULDU: $vakit ($saat:$dakika)");
  }

  // 2. KİŞİ BAZLI HATIRLATICILAR
  Future<void> kisiHatirlaticiKur(String vakit, int saat, int dakika) async {
    await _hatirlaticiPlanla(vakit, 1, saat, dakika + 15);
    await _hatirlaticiPlanla(vakit, 2, saat, dakika + 30);
    await _hatirlaticiPlanla(vakit, 3, saat, dakika + 45);

    print("🔔 HATIRLATICILAR PLANLANDI: $vakit (+15, +30, +45 dk)");
    print("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛");
  }

  // 3. HATIRLATICI PLANLAMA
  Future<void> _hatirlaticiPlanla(String vakit, int hatirlatmaNo, int saat, int dakika) async {
    // Dakika taşmasını hesapla
    int ekSaat = dakika ~/ 60;
    int netDakika = dakika % 60;
    int netSaat = (saat + ekSaat) % 24;

    final tz.TZDateTime simdi = tz.TZDateTime.now(tz.local);
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

    if (hedefZaman.isBefore(simdi) || hedefZaman.isAtSameMomentAs(simdi)) {
      hedefZaman = hedefZaman.add(const Duration(days: 1));
    }

    // Alarm ID Oluşturma
    int vakitId = 1;
    if (vakit == "Öğle") vakitId = 2;
    if (vakit == "Akşam") vakitId = 3;
    if (vakit == "Gece") vakitId = 4;

    int alarmId = 1000 + (vakitId * 100) + hatirlatmaNo;

    // AlarmManager ile arka plan callback'i zamanla
    await AndroidAlarmManager.oneShotAt(
      hedefZaman,
      alarmId,
      _arkaPlanKontrolCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      params: {
        'vakit': vakit,
        'hatirlatmaNo': hatirlatmaNo,
      },
    );

    final Duration fark = hedefZaman.difference(simdi);
    print("   ⏱️ $hatirlatmaNo. Kontrol Alarmı → ${hedefZaman.hour}:${hedefZaman.minute.toString().padLeft(2,'0')} (${fark.inMinutes} dk sonra)");
  }

  // 4. ARKA PLAN CALLBACK (Static ve @pragma ile işaretli)
  @pragma('vm:entry-point')
  static Future<void> _arkaPlanKontrolCallback(int id, Map<String, dynamic> params) async {
    String vakit = params['vakit'] ?? '';
    int hatirlatmaNo = params['hatirlatmaNo'] ?? 0;

    print("🚀 ARKA PLAN ALARMI ÇALIŞTI: $vakit - $hatirlatmaNo. Hatırlatma");

    try {
      // Firebase'i başlat
      await Firebase.initializeApp();

      // Aile kodunu SharedPreferences'tan al
      final prefs = await SharedPreferences.getInstance();
      String? aileKodu = prefs.getString('aile_kodu');

      if (aileKodu == null) {
        print("   ❌ Aile kodu bulunamadı!");
        return;
      }

      // Bugünün günü
      const gunler = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"];
      String bugun = gunler[DateTime.now().weekday - 1];

      // Kişileri çek
      Map<String, String> kisiIdToName = {};
      QuerySnapshot kisilerSnapshot = await FirebaseFirestore.instance
          .collection('aileler')
          .doc(aileKodu)
          .collection('kisiler')
          .get();

      for (var kisiDoc in kisilerSnapshot.docs) {
        var kisiData = kisiDoc.data() as Map<String, dynamic>;
        kisiIdToName[kisiDoc.id] = kisiData['ad'] ?? 'Bilinmeyen';
      }

      // İlaçları çek
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('aileler')
          .doc(aileKodu)
          .collection('ilaclar')
          .get();

      Map<String, List<String>> kisiIlaclari = {};

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        // Gün kontrolü
        bool herGun = data['her_gun'] ?? true;
        List<dynamic> gunlerList = data['gunler'] ?? [];
        if (!herGun && !gunlerList.contains(bugun)) continue;

        // Vakit kontrolü
        List<dynamic> vakitler = data['vakitler'] ?? [];
        if (!vakitler.contains(vakit)) continue;

        // İçilme kontrolü
        Map<String, dynamic> icilenTarihler = data['icilen_tarihler'] ?? {};
        bool bugunIcildi = _bugunIcildiMiStatic(icilenTarihler[vakit]);

        if (bugunIcildi) continue;

        // Listeye ekle
        String kisiId = data['kisi_id'] ?? '';
        String kisiAdi = kisiIdToName[kisiId] ?? 'Bilinmeyen';
        String ilacAdi = data['ad'] ?? '';

        if (!kisiIlaclari.containsKey(kisiAdi)) {
          kisiIlaclari[kisiAdi] = [];
        }
        kisiIlaclari[kisiAdi]!.add(ilacAdi);
      }

      if (kisiIlaclari.isEmpty) {
        print("   ✅ Tüm ilaçlar içilmiş, bildirim yok.");
        return;
      }

      // BİLDİRİMLERİ GÖNDER
      final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();

      // Plugin'i yeniden başlat (arka plan için gerekli)
      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);
      await plugin.initialize(initSettings);

      int kisiIndex = 0;
      for (var entry in kisiIlaclari.entries) {
        String kisi = entry.key;
        List<String> ilaclar = entry.value;

        String baslik = hatirlatmaNo == 3
            ? "🚨 SON UYARI - İlaç İçilmedi!"
            : "💊 İlaç Hatırlatması ($hatirlatmaNo/3)";
        String ilacListesi = ilaclar.join(", ");
        String icerik = "$kisi, $ilacListesi ilacını içtin mi?";

        int vakitOffset = 0;
        if (vakit == "Sabah") vakitOffset = 500000;
        if (vakit == "Öğle") vakitOffset = 600000;
        if (vakit == "Akşam") vakitOffset = 700000;
        if (vakit == "Gece") vakitOffset = 800000;
        int bildirimId = vakitOffset + (hatirlatmaNo * 100) + kisiIndex;

        await plugin.show(
          bildirimId,
          baslik,
          icerik,
          NotificationDetails(
            android: AndroidNotificationDetails(
              kanal.id,
              kanal.name,
              channelDescription: kanal.description,
              importance: Importance.max,
              priority: Priority.high,
              styleInformation: BigTextStyleInformation(icerik),
              playSound: true,
              enableVibration: true,
              vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
              onlyAlertOnce: false,
              color: hatirlatmaNo == 3 ? Colors.red : Colors.orange,
              ledColor: const Color(0xFFFF0000),
              ledOnMs: 1000,
              ledOffMs: 500,
              enableLights: true,
            ),
          ),
        );

        print("   📲 Bildirim gönderildi: $kisi → $ilacListesi");
        kisiIndex++;
      }

      print("   ✅ Toplam ${kisiIlaclari.length} kişiye bildirim gönderildi.");

    } catch (e) {
      print("   ❌ Arka plan callback hatası: $e");
    }
  }

  // Bugün içildi mi kontrolü (Static metod - callback için)
  static bool _bugunIcildiMiStatic(dynamic timestamp) {
    if (timestamp == null) return false;
    DateTime simdi = DateTime.now();
    DateTime kayit = (timestamp as Timestamp).toDate();
    return simdi.year == kayit.year &&
        simdi.month == kayit.month &&
        simdi.day == kayit.day;
  }

  // ANA BİLDİRİM PLANLAMA
  Future<void> _bildirimPlanla(int id, String baslik, String icerik, int saat, int dakika) async {
    int ekSaat = dakika ~/ 60;
    int netDakika = dakika % 60;
    int netSaat = (saat + ekSaat) % 24;

    final tz.TZDateTime simdi = tz.TZDateTime.now(tz.local);
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

    if (hedefZaman.isBefore(simdi) || hedefZaman.isAtSameMomentAs(simdi)) {
      hedefZaman = hedefZaman.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      baslik,
      icerik,
      hedefZaman,
      NotificationDetails(
        android: AndroidNotificationDetails(
          kanal.id,
          kanal.name,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          onlyAlertOnce: true,
          color: const Color(0xFF009688),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    final Duration fark = hedefZaman.difference(simdi);
    print("   ⏰ Ana Bildirim → ${hedefZaman.hour}:${hedefZaman.minute.toString().padLeft(2,'0')} (${fark.inMinutes} dk sonra)");
  }
}