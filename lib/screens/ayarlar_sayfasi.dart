import 'package:flutter/material.dart';
import '../services/zaman_yoneticisi.dart';

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
      await ZamanYoneticisi().saatGuncelle(vakit, secilen);
      setState(() {}); // Ekranı yenile

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$vakit saati ${secilen.format(context)} olarak güncellendi. Yeni ilaçlarda geçerli olacak.')),
        );
      }
      // Not: Var olan bildirimleri güncellemek için daha karmaşık bir yapı gerekir,
      // şimdilik "yeni eklenenler veya güncellenenler" yeni saati alacak.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Saat Ayarları")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("İlaç Vakitlerini Düzenle", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Burada belirlediğiniz saatler, bildirimlerin ne zaman geleceğini belirler."),
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
      child: ListTile(
        leading: Icon(ikon, color: renk, size: 30),
        title: Text("$vakit Vakti"),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
          child: Text("${saat.hour.toString().padLeft(2,'0')}:${saat.minute.toString().padLeft(2,'0')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        onTap: () => _saatSec(context, vakit),
      ),
    );
  }
}