import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

class BildirimServisi {
  static final BildirimServisi _instance = BildirimServisi._internal();
  factory BildirimServisi() => _instance;
  BildirimServisi._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidAyarlari = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings baslatmaAyarlari = InitializationSettings(android: androidAyarlari);

    await flutterLocalNotificationsPlugin.initialize(baslatmaAyarlari);
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // 1. ANA VAKİT BİLDİRİMİ (Toplu)
  // Bu bildirim ID'leri sabittir: Sabah=1, Öğle=2, Akşam=3, Gece=4
  Future<void> anaVakitBildirimiKur(String vakit, int saat, int dakika) async {
    int id = 0;
    if (vakit == "Sabah") id = 1;
    if (vakit == "Öğle") id = 2;
    if (vakit == "Akşam") id = 3;
    if (vakit == "Gece") id = 4;

    await _bildirimPlanla(
        id,
        "$vakit İlaç Vakti",
        "Lütfen $vakit ilaçlarınızı almayı unutmayın.",
        saat,
        dakika
    );
  }

  // 2. İLAÇ HATIRLATICILARI (3 Kere Tekrar Eden)
  Future<void> hatirlaticiKur(int ilacBaseId, String ilacAdi, String kisi, String vakit, int saat, int dakika) async {
    // Vakit offsetleri (Çakışmayı önlemek için)
    int vakitOffset = 0;
    if (vakit == "Sabah") vakitOffset = 10000;
    if (vakit == "Öğle") vakitOffset = 20000;
    if (vakit == "Akşam") vakitOffset = 30000;
    if (vakit == "Gece") vakitOffset = 40000;

    int temelId = ilacBaseId + vakitOffset;

    // 3 Kere Bildirim Kuruyoruz (15 dk arayla)
    // 1. Hatırlatma (+15 dk) -> ID: Temel + 1
    await _bildirimPlanla(temelId + 1, "İlaç İçilmedi!", "$kisi, $ilacAdi ilacını içtin mi? (1. Hatırlatma)", saat, dakika + 15);

    // 2. Hatırlatma (+30 dk) -> ID: Temel + 2
    await _bildirimPlanla(temelId + 2, "İlaç İçilmedi!", "$kisi, $ilacAdi ilacını içtin mi? (2. Hatırlatma)", saat, dakika + 30);

    // 3. Hatırlatma (+45 dk) -> ID: Temel + 3
    await _bildirimPlanla(temelId + 3, "Lütfen İlacı İçin", "$kisi, $ilacAdi ilacını hala içmedin mi? (Son Uyarı)", saat, dakika + 45);
  }

  // 3. HATIRLATICILARI İPTAL ET (İlaç İçilince)
  Future<void> hatirlaticilariIptalEt(int ilacBaseId, String vakit) async {
    int vakitOffset = 0;
    if (vakit == "Sabah") vakitOffset = 10000;
    if (vakit == "Öğle") vakitOffset = 20000;
    if (vakit == "Akşam") vakitOffset = 30000;
    if (vakit == "Gece") vakitOffset = 40000;

    int temelId = ilacBaseId + vakitOffset;

    // Kurduğumuz 3 bildirimi de iptal ediyoruz
    await flutterLocalNotificationsPlugin.cancel(temelId + 1);
    await flutterLocalNotificationsPlugin.cancel(temelId + 2);
    await flutterLocalNotificationsPlugin.cancel(temelId + 3);
  }

  // YARDIMCI PLANLAMA FONKSİYONU
  Future<void> _bildirimPlanla(int id, String baslik, String icerik, int saat, int dakika) async {
    tz.TZDateTime tarih = _zamanHesapla(saat, dakika);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      baslik,
      icerik,
      tarih,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ilac_takip_v2',
          'İlaç Bildirimleri',
          importance: Importance.max,
          priority: Priority.high,
          color: Colors.teal,
          enableLights: true,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Dakika hesabı (60'ı geçerse saati artırır)
  tz.TZDateTime _zamanHesapla(int saat, int dakika) {
    final tz.TZDateTime simdi = tz.TZDateTime.now(tz.local);

    // Dakika taşmasını düzelt (Örn: 14:75 -> 15:15)
    int ekSaat = dakika ~/ 60;
    int netDakika = dakika % 60;
    int netSaat = (saat + ekSaat) % 24;

    tz.TZDateTime planlanan = tz.TZDateTime(tz.local, simdi.year, simdi.month, simdi.day, netSaat, netDakika);

    if (planlanan.isBefore(simdi)) {
      return planlanan.add(const Duration(days: 1));
    }
    return planlanan;
  }
}