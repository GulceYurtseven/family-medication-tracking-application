import 'package:flutter/material.dart';
import 'gunluk_plan_ekrani.dart';
import 'kisi_yonetim_ekrani.dart';
import 'takvim_ekrani.dart'; // YENİ
import 'stok_ekrani.dart';
import 'ilac_ekle_ekrani.dart';
import 'ayarlar_sayfasi.dart';

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  int _secilenIndex = 0;

  final List<Widget> _sayfalar = [
    const GunlukPlanEkrani(),
    const TakvimEkrani(), // YENİ
    const StokEkrani(),
    const IlacEkleEkrani(),
  ];

  final List<String> _basliklar = [
    'Bugün',
    'Takvim',
    'Stoklar',
    'İlaç Ekle',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _secilenIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_basliklar[_secilenIndex]),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: "Kişi Yönetimi",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const KisiYonetimEkrani()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Ayarlar",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AyarlarSayfasi()));
            },
          )
        ],
      ),
      body: _sayfalar[_secilenIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: 'Bugün',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Takvim',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Stoklar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Ekle',
          ),
        ],
        currentIndex: _secilenIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}