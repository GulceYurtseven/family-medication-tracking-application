import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TakvimEkrani extends StatefulWidget {
  const TakvimEkrani({super.key});

  @override
  State<TakvimEkrani> createState() => _TakvimEkraniState();
}

class _TakvimEkraniState extends State<TakvimEkrani> {
  final List<String> _gunler = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"];
  final List<String> _vakitler = ["Sabah", "Öğle", "Akşam", "Gece"];

  String _secilenGun = "Pazartesi";

  @override
  void initState() {
    super.initState();
    // Bugünün gününü otomatik seç
    int bugun = DateTime.now().weekday; // 1=Pazartesi, 7=Pazar
    _secilenGun = _gunler[bugun - 1];
  }

  // İkonlar
  IconData _vakitIkonu(String vakit) {
    switch (vakit) {
      case 'Sabah': return Icons.wb_twilight;
      case 'Öğle': return Icons.wb_sunny;
      case 'Akşam': return Icons.nights_stay;
      case 'Gece': return Icons.bed;
      default: return Icons.access_time;
    }
  }

  Color _vakitRengi(String vakit) {
    switch (vakit) {
      case 'Sabah': return Colors.orange;
      case 'Öğle': return Colors.yellow.shade800;
      case 'Akşam': return Colors.indigo;
      case 'Gece': return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Gün Seçici (Üst Kısım)
        Container(
          height: 100,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade400, Colors.teal.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _gunler.length,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemBuilder: (context, index) {
              String gun = _gunler[index];
              bool secili = gun == _secilenGun;
              int bugun = DateTime.now().weekday - 1; // 0=Pazartesi
              bool bugunMu = index == bugun;

              return GestureDetector(
                onTap: () => setState(() => _secilenGun = gun),
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: secili ? Colors.white : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: bugunMu ? Border.all(color: Colors.amber, width: 3) : null,
                    boxShadow: secili ? [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))] : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        gun.substring(0, 3),
                        style: TextStyle(
                          color: secili ? Colors.teal.shade700 : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (bugunMu)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text("Bugün", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // İlaç Listesi (Vakitlere Göre)
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('ilaclar').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text("Henüz ilaç eklenmemiş", style: TextStyle(color: Colors.grey.shade600, fontSize: 18)),
                    ],
                  ),
                );
              }

              // Tüm ilaçları filtrele: Seçilen günde içilmesi gerekenler
              var tumIlaclar = snapshot.data!.docs.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                bool herGun = data['her_gun'] ?? true;
                List<dynamic> gunler = data['gunler'] ?? [];

                return herGun || gunler.contains(_secilenGun);
              }).toList();

              if (tumIlaclar.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text("$_secilenGun günü için ilaç yok", style: TextStyle(color: Colors.grey.shade600, fontSize: 18)),
                    ],
                  ),
                );
              }

              // Vakitlere göre grupla
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _vakitler.length,
                itemBuilder: (context, vakitIndex) {
                  String vakit = _vakitler[vakitIndex];

                  // Bu vakitte içilmesi gereken ilaçlar
                  var vakitIlaclari = tumIlaclar.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    List<dynamic> vakitler = data['vakitler'] ?? [];
                    return vakitler.contains(vakit);
                  }).toList();

                  if (vakitIlaclari.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vakit Başlığı
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: _vakitRengi(vakit).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _vakitRengi(vakit), width: 2),
                        ),
                        child: Row(
                          children: [
                            Icon(_vakitIkonu(vakit), color: _vakitRengi(vakit), size: 28),
                            const SizedBox(width: 12),
                            Text(
                              vakit,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _vakitRengi(vakit),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _vakitRengi(vakit),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${vakitIlaclari.length} İlaç",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // İlaçlar
                      ...vakitIlaclari.map((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        String sahibi = data['sahibi'] ?? '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: sahibi == 'Dede' ? Colors.blue : Colors.pink,
                              child: Icon(
                                sahibi == 'Dede' ? Icons.man : Icons.woman,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              data['ad'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Text(
                              "${data['kullanim_sekli'] ?? ''} • Stok: ${data['stok'] ?? 0}",
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            trailing: Icon(Icons.medication, color: _vakitRengi(vakit), size: 30),
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 20),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}