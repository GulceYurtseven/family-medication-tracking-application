import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class AileYoneticisi {
  static final AileYoneticisi _instance = AileYoneticisi._internal();
  factory AileYoneticisi() => _instance;
  AileYoneticisi._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _aktifAileKodu;
  List<String> _takipEdilenKisiler = []; // Kullanıcının seçtiği kişiler (local)

  // Aktif aile kodunu getir
  String? get aktifAileKodu => _aktifAileKodu;

  // Takip edilen kişileri getir
  List<String> get takipEdilenKisiler => List.from(_takipEdilenKisiler);

  // Uygulama başladığında yerel verileri yükle
  Future<void> verileriYukle() async {
    final prefs = await SharedPreferences.getInstance();
    _aktifAileKodu = prefs.getString('aile_kodu');

    String? takipListesi = prefs.getString('takip_edilen_kisiler');
    if (takipListesi != null) {
      _takipEdilenKisiler = List<String>.from(jsonDecode(takipListesi));
    }
  }

  // Aile kodu ile giriş yap (mevcut aile kodunu kontrol et)
  Future<bool> aileKoduIleGiris(String aileKodu) async {
    try {
      // Firebase'de bu aile kodunun olup olmadığını kontrol et
      DocumentSnapshot doc = await _firestore.collection('aileler').doc(aileKodu).get();

      if (doc.exists) {
        _aktifAileKodu = aileKodu;
        await _yerelKaydet();

        // Varsayılan olarak tüm aile üyelerini takip et
        await _tumAileUyeleriniTakipEt();

        return true;
      }
      return false;
    } catch (e) {
      print('Aile kodu giriş hatası: $e');
      return false;
    }
  }

  // Yeni aile oluştur
  Future<String?> yeniAileOlustur(String aileAdi) async {
    try {
      // Benzersiz aile kodu oluştur (İlk 4 harf + 4 rakam)
      String aileKodu = _aileKoduOlustur(aileAdi);

      // Firebase'de aile kaydı oluştur
      await _firestore.collection('aileler').doc(aileKodu).set({
        'aile_adi': aileAdi,
        'olusturma_tarihi': FieldValue.serverTimestamp(),
        'aile_kodu': aileKodu,
      });

      // Varsayılan kişileri ekle (Dede ve Anane)
      // await _varsayilanKisileriEkle(aileKodu);

      _aktifAileKodu = aileKodu;
      await _yerelKaydet();

      // Tüm üyeleri takip et
      await _tumAileUyeleriniTakipEt();

      return aileKodu;
    } catch (e) {
      print('Aile oluşturma hatası: $e');
      return null;
    }
  }

  // Benzersiz aile kodu oluştur
  String _aileKoduOlustur(String aileAdi) {
    String prefix = aileAdi.toUpperCase().replaceAll(' ', '').substring(0, aileAdi.length >= 4 ? 4 : aileAdi.length);
    String suffix = DateTime.now().millisecondsSinceEpoch.toString().substring(7, 11);
    return '$prefix$suffix';
  }


  // Tüm aile üyelerini varsayılan olarak takip et
  Future<void> _tumAileUyeleriniTakipEt() async {
    if (_aktifAileKodu == null) return;

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('aileler')
          .doc(_aktifAileKodu)
          .collection('kisiler')
          .get();

      _takipEdilenKisiler = snapshot.docs.map((doc) => doc.id).toList();
      await _yerelKaydet();
    } catch (e) {
      print('Takip listesi yükleme hatası: $e');
    }
  }

  // Kişiyi takip et/etme
  Future<void> kisiTakipDurumunuDegistir(String kisiId, bool takipEt) async {
    if (takipEt) {
      if (!_takipEdilenKisiler.contains(kisiId)) {
        _takipEdilenKisiler.add(kisiId);
      }
    } else {
      _takipEdilenKisiler.remove(kisiId);
    }
    await _yerelKaydet();
  }

  // Kişinin takip edilip edilmediğini kontrol et
  bool kisiTakipEdiliyor(String kisiId) {
    return _takipEdilenKisiler.contains(kisiId);
  }

  // Yerel hafızaya kaydet
  Future<void> _yerelKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    if (_aktifAileKodu != null) {
      await prefs.setString('aile_kodu', _aktifAileKodu!);
    }
    await prefs.setString('takip_edilen_kisiler', jsonEncode(_takipEdilenKisiler));
  }

  // Çıkış yap
  Future<void> cikisYap() async {
    _aktifAileKodu = null;
    _takipEdilenKisiler.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('aile_kodu');
    await prefs.remove('takip_edilen_kisiler');
  }

  // Aile üyelerini getir (Firebase'den)
  Stream<QuerySnapshot> aileUyeleriniGetir() {
    if (_aktifAileKodu == null) {
      return Stream.empty();
    }
    return _firestore
        .collection('aileler')
        .doc(_aktifAileKodu)
        .collection('kisiler')
        .snapshots();
  }

  // Yeni kişi ekle (Firebase'e)
  Future<bool> yeniKisiEkle(String ad, String emoji) async {
    if (_aktifAileKodu == null) return false;

    try {
      // Aynı isimde kişi var mı kontrol et
      QuerySnapshot existing = await _firestore
          .collection('aileler')
          .doc(_aktifAileKodu)
          .collection('kisiler')
          .where('ad', isEqualTo: ad)
          .get();

      if (existing.docs.isNotEmpty) return false;

      // Kişiyi ekle
      DocumentReference docRef = await _firestore
          .collection('aileler')
          .doc(_aktifAileKodu)
          .collection('kisiler')
          .add({
        'ad': ad,
        'emoji': emoji,
        'olusturma_tarihi': FieldValue.serverTimestamp(),
      });

      // Otomatik olarak takip et
      await kisiTakipDurumunuDegistir(docRef.id, true);

      return true;
    } catch (e) {
      print('Kişi ekleme hatası: $e');
      return false;
    }
  }

  // Kişi sil (Firebase'den)
  Future<bool> kisiSil(String kisiId, String ad) async {
    if (_aktifAileKodu == null) return false;

    // Varsayılan kişileri koruma
    if (ad == "Dede" || ad == "Anane") return false;

    try {
      await _firestore
          .collection('aileler')
          .doc(_aktifAileKodu)
          .collection('kisiler')
          .doc(kisiId)
          .delete();

      // Takip listesinden de kaldır
      _takipEdilenKisiler.remove(kisiId);
      await _yerelKaydet();

      return true;
    } catch (e) {
      print('Kişi silme hatası: $e');
      return false;
    }
  }

  // İlaçları getir (sadece takip edilen kişilerin)
  Stream<QuerySnapshot> takipEdilenIlaclariGetir() {
    if (_aktifAileKodu == null || _takipEdilenKisiler.isEmpty) {
      return Stream.empty();
    }

    return _firestore
        .collection('aileler')
        .doc(_aktifAileKodu)
        .collection('ilaclar')
        .where('kisi_id', whereIn: _takipEdilenKisiler)
        .snapshots();
  }

  // Tüm ilaçları getir (filtresiz)
  Stream<QuerySnapshot> tumIlaclariGetir() {
    if (_aktifAileKodu == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('aileler')
        .doc(_aktifAileKodu)
        .collection('ilaclar')
        .snapshots();
  }

  // İlaç ekle
  Future<bool> ilacEkle(Map<String, dynamic> ilacVerisi) async {
    if (_aktifAileKodu == null) return false;

    try {
      await _firestore
          .collection('aileler')
          .doc(_aktifAileKodu)
          .collection('ilaclar')
          .add(ilacVerisi);
      return true;
    } catch (e) {
      print('İlaç ekleme hatası: $e');
      return false;
    }
  }

  // İlaç güncelle
  Future<bool> ilacGuncelle(String ilacId, Map<String, dynamic> ilacVerisi) async {
    if (_aktifAileKodu == null) return false;

    try {
      await _firestore
          .collection('aileler')
          .doc(_aktifAileKodu)
          .collection('ilaclar')
          .doc(ilacId)
          .update(ilacVerisi);
      return true;
    } catch (e) {
      print('İlaç güncelleme hatası: $e');
      return false;
    }
  }

  // İlaç sil
  Future<bool> ilacSil(String ilacId) async {
    if (_aktifAileKodu == null) return false;

    try {
      await _firestore
          .collection('aileler')
          .doc(_aktifAileKodu)
          .collection('ilaclar')
          .doc(ilacId)
          .delete();
      return true;
    } catch (e) {
      print('İlaç silme hatası: $e');
      return false;
    }
  }

  // Kişinin adını ID'den getir
  Future<String> kisiAdiniGetir(String kisiId) async {
    if (_aktifAileKodu == null) return 'Bilinmeyen';

    try {
      DocumentSnapshot doc = await _firestore
          .collection('aileler')
          .doc(_aktifAileKodu)
          .collection('kisiler')
          .doc(kisiId)
          .get();

      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['ad'] ?? 'Bilinmeyen';
      }
      return 'Bilinmeyen';
    } catch (e) {
      return 'Bilinmeyen';
    }
  }

  // Kişinin emojisini ID'den getir
  Future<String> kisiEmojisiniGetir(String kisiId) async {
    if (_aktifAileKodu == null) return '👤';

    try {
      DocumentSnapshot doc = await _firestore
          .collection('aileler')
          .doc(_aktifAileKodu)
          .collection('kisiler')
          .doc(kisiId)
          .get();

      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['emoji'] ?? '👤';
      }
      return '👤';
    } catch (e) {
      return '👤';
    }
  }
}