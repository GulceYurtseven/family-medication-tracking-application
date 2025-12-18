import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/kisi_yoneticisi.dart'; // EMOJİLER İÇİN EKLENDİ

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
    int bugun = DateTime.now().weekday;
    _secilenGun = _gunler[bugun - 1];
  }

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
        // GÜN SEÇİCİ
        Container(
          height: 90,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.teal.shade400, Colors.teal.shade700]),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _gunler.length,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemBuilder: (context, index) {
              String gun = _gunler[index];
              bool secili = gun == _secilenGun;
              bool bugunMu = index == (DateTime.now().weekday - 1);

              return GestureDetector(
                onTap: () => setState(() => _secilenGun = gun),
                child: Container(
                  width: 75,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: secili ? Colors.white : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: bugunMu ? Border.all(color: Colors.amber, width: 3) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(gun.substring(0, 3), style: TextStyle(color: secili ? Colors.teal.shade700 : Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      if (bugunMu)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)),
                          child: const Text("Bugün", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('ilaclar').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("İlaç yok."));

              // O güne ait ilaçları filtrele
              var gunlukIlaclar = snapshot.data!.docs.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                bool herGun = data['her_gun'] ?? true;
                List<dynamic> gunler = data['gunler'] ?? [];
                return herGun || gunler.contains(_secilenGun);
              }).toList();

              if (gunlukIlaclar.isEmpty) return Center(child: Text("$_secilenGun günü için ilaç yok."));

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _vakitler.length,
                itemBuilder: (context, vakitIndex) {
                  String vakit = _vakitler[vakitIndex];

                  // Bu vakitteki ilaçlar
                  var vakitIlaclari = gunlukIlaclar.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    List<dynamic> vakitler = data['vakitler'] ?? [];
                    return vakitler.contains(vakit);
                  }).toList();

                  if (vakitIlaclari.isEmpty) return const SizedBox.shrink();

                  // KİŞİLERE GÖRE GRUPLA
                  Map<String, List<DocumentSnapshot>> kisiGruplari = {};
                  for (var doc in vakitIlaclari) {
                    String sahibi = (doc.data() as Map<String, dynamic>)['sahibi'] ?? 'Diğer';
                    if (!kisiGruplari.containsKey(sahibi)) kisiGruplari[sahibi] = [];
                    kisiGruplari[sahibi]!.add(doc);
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vakit Başlığı
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 8, top: 8),
                        decoration: BoxDecoration(
                          color: _vakitRengi(vakit).withOpacity(0.1),
                          border: Border.all(color: _vakitRengi(vakit)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(_vakitIkonu(vakit), color: _vakitRengi(vakit)),
                            const SizedBox(width: 8),
                            Text(vakit, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _vakitRengi(vakit))),
                          ],
                        ),
                      ),

                      // Kişiler ve İlaçları
                      ...kisiGruplari.entries.map((entry) {
                        String kisi = entry.key;
                        String emoji = KisiYoneticisi().emojiGetir(kisi) ?? "👤";
                        List<DocumentSnapshot> ilaclar = entry.value;

                        return Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Kişi Başlığı
                              Row(
                                children: [
                                  Text(emoji, style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 4),
                                  Text(kisi, style: TextStyle(fontWeight: FontWeight.bold, fontSize : 22 ,color: Colors.teal.shade800)),
                                ],
                              ),
                              // İlaç Kartları
                              ...ilaclar.map((doc) {
                                var data = doc.data() as Map<String, dynamic>;
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  color: Colors.green[100],
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                    visualDensity: VisualDensity.compact,
                                    title: Text(data['ad'], style: TextStyle(fontWeight: FontWeight.bold) ),
                                    subtitle: Text("${data['stok']} adet • ${data['kullanim_sekli']}" , style: TextStyle(color:Colors.black)),
                                    trailing: const Icon(Icons.medication, size: 20, color: Colors.teal),
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }),
                      const Divider(),
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