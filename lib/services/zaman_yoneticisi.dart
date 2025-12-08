import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ZamanYoneticisi {
  static final ZamanYoneticisi _instance = ZamanYoneticisi._internal();
  factory ZamanYoneticisi() => _instance;
  ZamanYoneticisi._internal();

  // Varsayılan Saatler
  TimeOfDay sabah = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay ogle = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay aksam = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay gece = const TimeOfDay(hour: 22, minute: 0);

  // Kayıtlı saatleri yükle
  Future<void> saatleriYukle() async {
    final prefs = await SharedPreferences.getInstance();
    sabah = _stringToTime(prefs.getString('sabah') ?? "10:00");
    ogle = _stringToTime(prefs.getString('ogle') ?? "14:00");
    aksam = _stringToTime(prefs.getString('aksam') ?? "18:00");
    gece = _stringToTime(prefs.getString('gece') ?? "22:00");
  }

  // Saati kaydet
  Future<void> saatGuncelle(String vakit, TimeOfDay yeniSaat) async {
    final prefs = await SharedPreferences.getInstance();
    String saatStr = "${yeniSaat.hour}:${yeniSaat.minute}";
    await prefs.setString(vakit.toLowerCase(), saatStr); // 'sabah', 'ogle' vb.

    // Değişkeni de güncelle
    if (vakit == "Sabah") sabah = yeniSaat;
    if (vakit == "Öğle") ogle = yeniSaat;
    if (vakit == "Akşam") aksam = yeniSaat;
    if (vakit == "Gece") gece = yeniSaat;
  }

  // Vakte göre saati getir
  TimeOfDay saatiGetir(String vakit) {
    switch (vakit) {
      case "Sabah": return sabah;
      case "Öğle": return ogle;
      case "Akşam": return aksam;
      case "Gece": return gece;
      default: return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  // Yardımcılar
  TimeOfDay _stringToTime(String s) {
    final parts = s.split(":");
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}