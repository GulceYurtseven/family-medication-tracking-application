import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class StokKontrolServisi {
  static final StokKontrolServisi _instance = StokKontrolServisi._internal();
  factory StokKontrolServisi() => _instance;
  StokKontrolServisi._internal();

  final FlutterLocalNotificationsPlugin _notificationPlugin = FlutterLocalNotificationsPlugin();

  // Stok güncellendiğinde çağrılır
  Future<void> stokKontrolEt(String ilacId, String ilacAdi, String sahibi, int yeniStok, int eskiStok) async {
    // Stok azaldıysa kontrol et
    if (yeniStok < eskiStok) {
      if (yeniStok == 0 && eskiStok > 0) {
        // Stok bitti
        await _bildirimGonder(
          id: ilacId.hashCode + 1000000,
          baslik: "🚨 Stok Bitti!",
          icerik: "$sahibi - $ilacAdi ilacının stoğu bitti. Lütfen yenileyin.",
          onemi: Importance.max,
        );
      } else if (yeniStok == 5 && eskiStok > 5) {
        // Kritik seviye: 5
        await _bildirimGonder(
          id: ilacId.hashCode + 2000000,
          baslik: "⚠️ Kritik Stok!",
          icerik: "$sahibi - $ilacAdi ilacından sadece 5 adet kaldı.",
          onemi: Importance.high,
        );
      } else if (yeniStok == 10 && eskiStok > 10) {
        // Uyarı seviyesi: 10
        await _bildirimGonder(
          id: ilacId.hashCode + 3000000,
          baslik: "📦 Stok Azalıyor",
          icerik: "$sahibi - $ilacAdi ilacından 10 adet kaldı. Yenilemeyi unutmayın.",
          onemi: Importance.defaultImportance,
        );
      }
    }
  }

  Future<void> _bildirimGonder({
    required int id,
    required String baslik,
    required String icerik,
    required Importance onemi,
  }) async {
    await _notificationPlugin.show(
      id,
      baslik,
      icerik,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'stok_uyarilari',
          'Stok Uyarıları',
          channelDescription: 'İlaç stok durumu bildirimleri',
          importance: onemi,
          priority: Priority.high,
          color: Colors.orange,
          playSound: true,
          enableVibration: true,
          onlyAlertOnce: true,
        ),
      ),
    );
  }

  // Tüm ilaçların stok durumunu kontrol et (Opsiyonel - günlük kontrol için)
  Future<void> tumIlaclariKontrolEt() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('ilaclar').get();

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      int stok = data['stok'] ?? 0;
      String ad = data['ad'] ?? '';
      String sahibi = data['sahibi'] ?? '';

      if (stok == 0) {
        await _bildirimGonder(
          id: doc.id.hashCode + 1000000,
          baslik: "🚨 Stok Bitti!",
          icerik: "$sahibi - $ad ilacının stoğu bitti.",
          onemi: Importance.max,
        );
      } else if (stok <= 5) {
        await _bildirimGonder(
          id: doc.id.hashCode + 2000000,
          baslik: "⚠️ Kritik Stok!",
          icerik: "$sahibi - $ad ilacından sadece $stok adet kaldı.",
          onemi: Importance.high,
        );
      } else if (stok <= 10) {
        await _bildirimGonder(
          id: doc.id.hashCode + 3000000,
          baslik: "📦 Stok Azalıyor",
          icerik: "$sahibi - $ad ilacından $stok adet kaldı.",
          onemi: Importance.defaultImportance,
        );
      }
    }
  }
}