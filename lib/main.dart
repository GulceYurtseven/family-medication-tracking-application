import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/bildirim_servisi.dart';
import 'services/zaman_yoneticisi.dart';
import 'services/aile_yoneticisi.dart';
import 'screens/ana_sayfa.dart';
import 'screens/giris_ekrani.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 1. Zaman ayarlarını yükle
  await ZamanYoneticisi().saatleriYukle();

  // 2. Aile verilerini yükle
  await AileYoneticisi().verileriYukle();

  // 3. Bildirim servisini başlat
  await BildirimServisi().init();

  await AndroidAlarmManager.initialize();

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
      home: FutureBuilder<String?>(
        future: _kontrolEt(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade400, Colors.teal.shade700],
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            );
          }

          // Eğer aile kodu varsa ana sayfaya, yoksa giriş ekranına yönlendir
          if (snapshot.hasData && snapshot.data != null) {
            return const AnaSayfa();
          } else {
            return const GirisEkrani();
          }
        },
      ),
    );
  }

  Future<String?> _kontrolEt() async {
    await Future.delayed(const Duration(seconds: 1)); // Splash için
    return AileYoneticisi().aktifAileKodu;
  }
}