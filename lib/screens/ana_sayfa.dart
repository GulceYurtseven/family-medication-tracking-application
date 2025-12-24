import 'package:flutter/material.dart';
import 'gunluk_plan_ekrani.dart';
import 'kisi_yonetim_ekrani.dart';
import 'takvim_ekrani.dart';
import 'stok_ekrani.dart';
import 'ilac_ekle_ekrani.dart';
import 'ayarlar_sayfasi.dart';
import 'giris_ekrani.dart';
import '../services/aile_yoneticisi.dart';

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  int _secilenIndex = 0;

  final List<Widget> _sayfalar = [
    const GunlukPlanEkrani(),
    const TakvimEkrani(),
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

  void _cikisYap() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Çıkış Yap"),
        content: const Text("Çıkış yapmak istediğinize emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              await AileYoneticisi().cikisYap();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const GirisEkrani()),
                      (route) => false,
                );
              }
            },
            child: const Text("Çıkış Yap"),
          ),
        ],
      ),
    );
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const KisiYonetimEkrani()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Ayarlar",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AyarlarSayfasi()),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'cikis') {
                _cikisYap();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'cikis',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
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