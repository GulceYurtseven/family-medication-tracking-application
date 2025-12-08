import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'services/bildirim_servisi.dart';
import 'services/zaman_yoneticisi.dart'; // EKLENDİ
import 'screens/ana_sayfa.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Saat dilimi ve Yöneticiler
  tz.initializeTimeZones();
  try {
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
  } catch (e) {
    print("Saat hatası: $e");
  }

  await ZamanYoneticisi().saatleriYukle(); // EKLENDİ: Saatleri hafızadan oku
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