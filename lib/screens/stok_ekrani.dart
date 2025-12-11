import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/bildirim_servisi.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class StokEkrani extends StatefulWidget {
  const StokEkrani({super.key});

  @override
  State<StokEkrani> createState() => _StokEkraniState();
}

class _StokEkraniState extends State<StokEkrani> {
  String _aramaMetni = "";
  String? _secilenKisi; // null = Hepsi, "Dede" veya "Anane"

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // KİŞİ SEÇİM BUTONLARI
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Row(
            children: [
              Expanded(
                child: _kisiButonu(
                  "Hepsi",
                  "🏠",
                  Colors.grey.shade700,
                  _secilenKisi == null,
                      () => setState(() => _secilenKisi = null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _kisiButonu(
                  "Dede",
                  "👴",
                  Colors.blue.shade700,
                  _secilenKisi == "Dede",
                      () => setState(() => _secilenKisi = "Dede"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _kisiButonu(
                  "Anane",
                  "👵",
                  Colors.pink.shade700,
                  _secilenKisi == "Anane",
                      () => setState(() => _secilenKisi = "Anane"),
                ),
              ),
            ],
          ),
        ),

        // ARAMA ÇUBUĞU
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: "İlaç Ara...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: (deger) {
              setState(() {
                _aramaMetni = deger.toLowerCase();
              });
            },
          ),
        ),

        // LİSTE
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('ilaclar').orderBy('stok').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Kayıtlı ilaç yok."));
              }

              var docs = snapshot.data!.docs;

              // FİLTRELEME (Arama + Kişi)
              var filtrelenmisDocs = docs.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                String ad = (data['ad'] ?? '').toString().toLowerCase();
                String sahibi = data['sahibi'] ?? '';

                bool aramaUygun = ad.contains(_aramaMetni);
                bool kisiUygun = _secilenKisi == null || sahibi == _secilenKisi;

                return aramaUygun && kisiUygun;
              }).toList();

              if (filtrelenmisDocs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text("Sonuç bulunamadı.", style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtrelenmisDocs.length,
                itemBuilder: (context, index) {
                  var data = filtrelenmisDocs[index].data() as Map<String, dynamic>;
                  int stok = data['stok'] ?? 0;
                  bool kritikStok = stok < 5;

                  return Card(
                    color: kritikStok ? Colors.red.shade100 : Colors.white,
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: data['sahibi'] == 'Dede' ? Colors.blue : Colors.pink,
                        child: Text(
                          data['sahibi'] == 'Dede' ? "👴" : "👵",
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      title: Text(data['ad'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Sahibi: ${data['sahibi']}"),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kritikStok ? Colors.red : Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "$stok Adet",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _kisiButonu(String label, String emoji, Color color, bool secili, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: secili ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
          boxShadow: secili ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 4))] : null,
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: secili ? Colors.white : color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}