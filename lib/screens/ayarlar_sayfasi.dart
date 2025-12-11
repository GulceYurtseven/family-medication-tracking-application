import 'package:flutter/material.dart';
import '../services/zaman_yoneticisi.dart';
import '../services/bildirim_servisi.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AyarlarSayfasi extends StatefulWidget {
  const AyarlarSayfasi({super.key});

  @override
  State<AyarlarSayfasi> createState() => _AyarlarSayfasiState();
}

class _AyarlarSayfasiState extends State<AyarlarSayfasi> {

  // Saat seçiciyi açar ve kaydeder
  Future<void> _saatSec(BuildContext context, String vakit) async {
    TimeOfDay mevcut = ZamanYoneticisi().saatiGetir(vakit);

    final TimeOfDay? secilen = await showTimePicker(
      context: context,
      initialTime: mevcut,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (secilen != null) {
      // 1. Saati kaydet
      await ZamanYoneticisi().saatGuncelle(vakit, secilen);

      // 2. TÜM BİLDİRİMLERİ YENİDEN KUR
      await _tumBildirimleriGuncelle(vakit, secilen);

      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$vakit saati ${secilen.format(context)} olarak güncellendi.\nTüm bildirimler yenilendi! ✅'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // YENİ: Tüm bildirimleri güncelle
  Future<void> _tumBildirimleriGuncelle(String vakit, TimeOfDay yeniSaat) async {
    try {
      // 1. Ana vakit bildirimini güncelle
      await BildirimServisi().anaVakitBildirimiKur(vakit, yeniSaat.hour, yeniSaat.minute);

      // 2. Tüm ilaçları çek
      QuerySnapshot ilaclar = await FirebaseFirestore.instance.collection('ilaclar').get();

      // 3. Her ilaç için bu vakite ait hatırlatıcıları güncelle
      for (var doc in ilaclar.docs) {
        var data = doc.data() as Map<String, dynamic>;
        List<dynamic> vakitler = data['vakitler'] ?? [];

        // Eğer bu ilaç, güncellenen vakitte içiliyorsa
        if (vakitler.contains(vakit)) {
          int ilacIdBase = data['bildirim_id_base'] ?? 0;
          String ilacAdi = data['ad'] ?? '';
          String kisi = data['sahibi'] ?? '';

          // Hatırlatıcıları yeniden kur
          await BildirimServisi().hatirlaticiKur(
            ilacIdBase,
            ilacAdi,
            kisi,
            vakit,
            yeniSaat.hour,
            yeniSaat.minute,
          );

          print("✅ $ilacAdi ilacının $vakit bildirimleri güncellendi");
        }
      }
    } catch (e) {
      print("❌ Bildirimler güncellenirken hata: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saat Ayarları"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("İlaç Vakitlerini Düzenle", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade700, width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade900),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Saati değiştirdiğinizde TÜM ilaçların bildirimleri otomatik güncellenir.",
                    style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _saatKarti("Sabah", Icons.wb_twilight, Colors.orange),
          _saatKarti("Öğle", Icons.wb_sunny, Colors.yellow.shade800),
          _saatKarti("Akşam", Icons.nights_stay, Colors.indigo),
          _saatKarti("Gece", Icons.bed, Colors.purple),
        ],
      ),
    );
  }

  Widget _saatKarti(String vakit, IconData ikon, Color renk) {
    TimeOfDay saat = ZamanYoneticisi().saatiGetir(vakit);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(ikon, color: renk, size: 30),
        title: Text("$vakit Vakti", style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: renk.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: renk, width: 2),
          ),
          child: Text(
            "${saat.hour.toString().padLeft(2,'0')}:${saat.minute.toString().padLeft(2,'0')}",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: renk),
          ),
        ),
        onTap: () => _saatSec(context, vakit),
      ),
    );
  }
}