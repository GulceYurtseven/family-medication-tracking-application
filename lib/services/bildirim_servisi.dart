import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'dart:async';

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

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    print("🌍 Saat dilimi Europe/Istanbul olarak ayarlandı");

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

    await flutterLocalNotificationsPlugin.initialize(baslatmaAyarlari);

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }

    print("✅ Bildirim servisi başlatıldı");
  }

  // 1. ANA VAKİT BİLDİRİMİ (Herkese ortak)
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

    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    print("📋 ANA BİLDİRİM KURULDU");
    print("   Vakit: $vakit");
    print("   Saat: ${saat.toString().padLeft(2,'0')}:${dakika.toString().padLeft(2,'0')}");
    print("   ID: $id");
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  }

  // 2. KİŞİ BAZLI HATIRLATICILAR (3 adet: +15, +30, +45 dk)
  Future<void> kisiHatirlaticiKur(String vakit, int saat, int dakika) async {
    // 1. Hatırlatma: +15 dakika
    await _hatirlaticiPlanla(vakit, 1, saat, dakika + 15);

    // 2. Hatırlatma: +30 dakika
    await _hatirlaticiPlanla(vakit, 2, saat, dakika + 30);

    // 3. Hatırlatma: +45 dakika
    await _hatirlaticiPlanla(vakit, 3, saat, dakika + 45);

    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    print("🔔 HATIRLATICILAR KURULDU");
    print("   Vakit: $vakit");
    print("   1. Hatırlatma: +15 dk");
    print("   2. Hatırlatma: +30 dk");
    print("   3. Hatırlatma: +45 dk");
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  }

  // 3. HATIRLATICI PLANLAMA
  Future<void> _hatirlaticiPlanla(String vakit, int hatirlatmaNo, int saat, int dakika) async {
    // Dakika taşmasını hesapla
    int ekSaat = dakika ~/ 60;
    int netDakika = dakika % 60;
    int netSaat = (saat + ekSaat) % 24;

    // Hedef zamanı hesapla
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

    // Eğer geçmişte kaldıysa yarına ertele
    if (hedefZaman.isBefore(simdi) || hedefZaman.isAtSameMomentAs(simdi)) {
      hedefZaman = hedefZaman.add(const Duration(days: 1));
    }

    // Benzersiz ID oluştur
    int vakitOffset = 0;
    if (vakit == "Sabah") vakitOffset = 100000;
    if (vakit == "Öğle") vakitOffset = 200000;
    if (vakit == "Akşam") vakitOffset = 300000;
    if (vakit == "Gece") vakitOffset = 400000;

    int bildirimId = vakitOffset + hatirlatmaNo;

    // Bildirim planla (İçerik dummy, gerçek içerik _kontrolleriYap'ta oluşturulacak)
    /*await flutterLocalNotificationsPlugin.zonedSchedule(
      bildirimId,
      "Hatırlatma", // Dummy başlık
      "Kontrol ediliyor...", // Dummy içerik
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
          color: hatirlatmaNo == 3 ? Colors.red : Colors.orange,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );*/

    // Aynı zamanda kontrol mekanizmasını planla
    _zamanlanmisKontrolKur(vakit, hatirlatmaNo, hedefZaman);

    final Duration fark = hedefZaman.difference(simdi);
    print("   ⏱️ $hatirlatmaNo. Hatırlatma → ${hedefZaman.hour}:${hedefZaman.minute.toString().padLeft(2,'0')} (${fark.inMinutes} dk sonra)");
  }

  // 4. ZAMANLANMIŞ KONTROL MEKANIZMASI
  void _zamanlanmisKontrolKur(String vakit, int hatirlatmaNo, tz.TZDateTime hedefZaman) {
    final Duration beklemeSuresi = hedefZaman.difference(tz.TZDateTime.now(tz.local));

    // Timer ile zamanı geldiğinde kontrol yap
    Timer(beklemeSuresi, () async {
      print("\n🔍 KONTROL BAŞLADI: $vakit - $hatirlatmaNo. Hatırlatma");
      await _kontrolleriYapVeBildirimGonder(vakit, hatirlatmaNo);
    });
  }

  // 5. KRİTİK: İÇİLMEMİŞ İLAÇLARI KONTROL ET VE BİLDİRİM GÖNDER
  Future<void> _kontrolleriYapVeBildirimGonder(String vakit, int hatirlatmaNo) async {
    try {
      // Bugünün gününü al
      const gunler = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"];
      String bugun = gunler[DateTime.now().weekday - 1];

      print("   📅 Bugün: $bugun");

      // Firestore'dan tüm ilaçları çek
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('ilaclar').get();

      // Kişilere göre içilmemiş ilaçları grupla
      Map<String, List<String>> kisiIlaclari = {};

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        // Bu ilaç bugün içilmeli mi? (Gün kontrolü)
        bool herGun = data['her_gun'] ?? true;
        List<dynamic> gunler = data['gunler'] ?? [];
        if (!herGun && !gunler.contains(bugun)) {
          continue;
        }

        // Bu vakitte içilmeli mi? (Vakit kontrolü)
        List<dynamic> vakitler = data['vakitler'] ?? [];
        if (!vakitler.contains(vakit)) {
          continue;
        }

        // Bugün bu vakitte içildi mi? (İçilme kontrolü)
        Map<String, dynamic> icilenTarihler = data['icilen_tarihler'] ?? {};
        bool bugunIcildi = _bugunIcildiMi(icilenTarihler[vakit]);

        if (bugunIcildi) {
          continue; // İçildiyse atla
        }

        // İçilmemiş - Listeye ekle
        String kisi = data['sahibi'] ?? 'Diğer';
        String ilacAdi = data['ad'] ?? '';

        if (!kisiIlaclari.containsKey(kisi)) {
          kisiIlaclari[kisi] = [];
        }
        kisiIlaclari[kisi]!.add(ilacAdi);
      }

      print("   📊 İçilmemiş ilaçlar:");
      kisiIlaclari.forEach((kisi, ilaclar) {
        print("      • $kisi: ${ilaclar.join(', ')}");
      });

      // Eğer hiç içilmemiş ilaç yoksa bildirim gönderme
      if (kisiIlaclari.isEmpty) {
        print("   ✅ Tüm ilaçlar içilmiş, bildirim gönderilmedi.");

        // Dummy bildirimi iptal et
        int vakitOffset = 0;
        if (vakit == "Sabah") vakitOffset = 100000;
        if (vakit == "Öğle") vakitOffset = 200000;
        if (vakit == "Akşam") vakitOffset = 300000;
        if (vakit == "Gece") vakitOffset = 400000;
        await flutterLocalNotificationsPlugin.cancel(vakitOffset + hatirlatmaNo);

        return;
      }

      // Her kişi için ayrı bildirim gönder
      int kisiIndex = 0;
      for (var entry in kisiIlaclari.entries) {
        String kisi = entry.key;
        List<String> ilaclar = entry.value;

        // Başlık oluştur
        String baslik = hatirlatmaNo == 3
            ? "🚨 SON UYARI - İlaç İçilmedi!"
            : "💊 İlaç Hatırlatması ($hatirlatmaNo/3)";

        // İçerik oluştur: "Filiz, A, B ilacını içtin mi?"
        String ilacListesi = ilaclar.join(", ");
        String icerik = "$kisi, $ilacListesi ilacını içtin mi? ($hatirlatmaNo. Hatırlatma)";

        // Kişi başına benzersiz ID
        int vakitOffset = 0;
        if (vakit == "Sabah") vakitOffset = 500000;
        if (vakit == "Öğle") vakitOffset = 600000;
        if (vakit == "Akşam") vakitOffset = 700000;
        if (vakit == "Gece") vakitOffset = 800000;

        int bildirimId = vakitOffset + (hatirlatmaNo * 100) + kisiIndex;

        // Bildirimi gönder
        await flutterLocalNotificationsPlugin.show(
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
              onlyAlertOnce: true,
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

      print("   ✅ Toplam ${kisiIlaclari.length} kişiye bildirim gönderildi.\n");

    } catch (e) {
      print("   ❌ Hata: $e\n");
    }
  }

  // Bugün içildi mi kontrolü
  bool _bugunIcildiMi(dynamic timestamp) {
    if (timestamp == null) return false;
    DateTime simdi = DateTime.now();
    DateTime kayit = (timestamp as Timestamp).toDate();
    return simdi.year == kayit.year &&
        simdi.month == kayit.month &&
        simdi.day == kayit.day;
  }

  // ESKİ FONKSİYONLAR (Uyumluluk için)
  Future<void> hatirlaticilariIptalEt(int ilacBaseId, String vakit) async {
    print("ℹ️ hatirlaticilariIptalEt çağrıldı (yeni sistemde otomatik)");
  }

  @Deprecated("Artık kullanılmıyor")
  Future<void> hatirlaticiKur(int ilacBaseId, String ilacAdi, String kisi, String vakit, int saat, int dakika) async {
    print("ℹ️ Eski hatirlaticiKur çağrıldı");
  }

  // YARDIMCI: Basit bildirim planlama
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
    print("   ⏰ Bildirim → ${hedefZaman.hour}:${hedefZaman.minute.toString().padLeft(2,'0')} (${fark.inMinutes} dk sonra)");
  }
}