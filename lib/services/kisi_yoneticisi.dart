import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class KisiYoneticisi {
  static final KisiYoneticisi _instance = KisiYoneticisi._internal();
  factory KisiYoneticisi() => _instance;
  KisiYoneticisi._internal();

  List<Map<String, String>> _kisiler = [];

  // Varsayılan kişiler
  final List<Map<String, String>> _varsayilanKisiler = [
    {"ad": "Dede", "emoji": "👴"},
    {"ad": "Anane", "emoji": "👵"},
  ];

  // Kullanılabilir emoji listesi
  final List<String> kullanilabilirEmojiler = [
    "👴", "👵", "👨", "👩", "🧑", "👦", "👧", "🧒",
    "👶", "🧓", "👨‍⚕️", "👩‍⚕️", "🤱", "🧔", "👨‍🦳", "👩‍🦳",
    "👨‍🦰", "👩‍🦰", "👱‍♂️", "👱‍♀️", "🙋‍♂️", "🙋‍♀️"
  ];

  // Kişileri yükle
  Future<void> kisileriYukle() async {
    final prefs = await SharedPreferences.getInstance();
    String? kisilerJson = prefs.getString('kisiler');

    if (kisilerJson != null) {
      List<dynamic> decoded = jsonDecode(kisilerJson);
      _kisiler = decoded.map((item) => Map<String, String>.from(item)).toList();
    } else {
      // İlk kullanımda varsayılan kişileri yükle
      _kisiler = List.from(_varsayilanKisiler);
      await kisileriKaydet();
    }
  }

  // Kişileri kaydet
  Future<void> kisileriKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    String kisilerJson = jsonEncode(_kisiler);
    await prefs.setString('kisiler', kisilerJson);
  }

  // Tüm kişileri getir
  List<Map<String, String>> tumKisileriGetir() {
    return List.from(_kisiler);
  }

  // Kişi adlarını getir
  List<String> kisiAdlariniGetir() {
    return _kisiler.map((k) => k["ad"]!).toList();
  }

  // Kişi ekle
  Future<bool> kisiEkle(String ad, String emoji) async {
    // Aynı isimde kişi var mı kontrol et
    if (_kisiler.any((k) => k["ad"] == ad)) {
      return false;
    }

    _kisiler.add({"ad": ad, "emoji": emoji});
    await kisileriKaydet();
    return true;
  }

  // Kişi sil (Varsayılan kişiler silinemez)
  Future<bool> kisiSil(String ad) async {
    // Varsayılan kişileri koruma
    if (ad == "Dede" || ad == "Anane") {
      return false;
    }

    _kisiler.removeWhere((k) => k["ad"] == ad);
    await kisileriKaydet();
    return true;
  }

  // Kişi güncelle
  Future<bool> kisiGuncelle(String eskiAd, String yeniAd, String yeniEmoji) async {
    int index = _kisiler.indexWhere((k) => k["ad"] == eskiAd);
    if (index != -1) {
      _kisiler[index] = {"ad": yeniAd, "emoji": yeniEmoji};
      await kisileriKaydet();
      return true;
    }
    return false;
  }

  // Emojiye göre kişi getir
  String? emojiGetir(String ad) {
    try {
      return _kisiler.firstWhere((k) => k["ad"] == ad)["emoji"];
    } catch (e) {
      return "👤"; // Varsayılan
    }
  }

  // İsme göre kişi var mı?
  bool kisiVarMi(String ad) {
    return _kisiler.any((k) => k["ad"] == ad);
  }
}