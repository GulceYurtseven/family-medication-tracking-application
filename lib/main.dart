import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ilac_takip/services/kisi_yoneticisi.dart';
import 'services/bildirim_servisi.dart';
import 'services/zaman_yoneticisi.dart';
import 'screens/ana_sayfa.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 1. Veritabanındaki saatleri hazırla
  await ZamanYoneticisi().saatleriYukle();

  // 2. Kişileri Hafızadan Yükle (YENİ EKLENEN SATIR)
  await KisiYoneticisi().kisileriYukle();

  // 3. Bildirim servisini başlat
  await BildirimServisi().init();

  runApp(const AileIlacTakipApp());
}

class AileIlacTakipApp extends StatelessWidget {
  const AileIlacTakipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aile İlaç Takip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const AnaSayfa(),
    );
  }
}