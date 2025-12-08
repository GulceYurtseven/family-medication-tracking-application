import 'package:flutter/material.dart';
import 'gunluk_plan_ekrani.dart';
import 'stok_ekrani.dart';
import 'ilac_ekle_ekrani.dart';
import 'ayarlar_sayfasi.dart'; // EKLENDİ

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  int _secilenIndex = 0;

  final List<Widget> _sayfalar = [
    const GunlukPlanEkrani(),
    const StokEkrani(),
    const IlacEkleEkrani(),
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
        title: const Text('Aile İlaç Takip'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // AYARLAR BUTONU
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AyarlarSayfasi()));
            },
          )
        ],
      ),
      body: _sayfalar[_secilenIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Bugün'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Stoklar'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'İlaç Ekle'),
        ],
        currentIndex: _secilenIndex,
        selectedItemColor: Colors.teal,
        onTap: _onItemTapped,
      ),
    );
  }
}