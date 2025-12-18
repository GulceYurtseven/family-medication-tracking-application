import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/kisi_yoneticisi.dart';

class StokEkrani extends StatefulWidget {
  const StokEkrani({super.key});

  @override
  State<StokEkrani> createState() => _StokEkraniState();
}

class _StokEkraniState extends State<StokEkrani> {
  String _aramaMetni = "";
  String? _secilenKisi;

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> kisiler = KisiYoneticisi().tumKisileriGetir();

    return Column(
      children: [
        // KİŞİ SEÇİM BUTONLARI (Bugün Ekranıyla Aynı Tasarım)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _kisiFiltresiButon("Hepsi", "🏠", null),
                const SizedBox(width: 8),
                ...kisiler.map((kisi) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _kisiFiltresiButon(
                      kisi["ad"]!,
                      kisi["emoji"]!,
                      kisi["ad"],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),

        // ARAMA
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
            onChanged: (deger) => setState(() => _aramaMetni = deger.toLowerCase()),
          ),
        ),

        // LİSTE
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('ilaclar').orderBy('stok').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Kayıtlı ilaç yok."));

              var docs = snapshot.data!.docs.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                String ad = (data['ad'] ?? '').toString().toLowerCase();
                String sahibi = data['sahibi'] ?? '';
                bool aramaUygun = ad.contains(_aramaMetni);
                bool kisiUygun = _secilenKisi == null || sahibi == _secilenKisi;
                return aramaUygun && kisiUygun;
              }).toList();

              if (docs.isEmpty) return const Center(child: Text("Sonuç bulunamadı."));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var data = docs[index].data() as Map<String, dynamic>;
                  int stok = data['stok'] ?? 0;
                  bool kritikStok = stok < 5;
                  String sahibi = data['sahibi'] ?? '';
                  String emoji = KisiYoneticisi().emojiGetir(sahibi) ?? "👤";

                  return Card(
                    color: kritikStok ? Colors.red.shade100 : Colors.white,
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.shade100,
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                      title: Text(data['ad'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      subtitle: Text("Sahibi: $sahibi", style: TextStyle(color: Colors.black),),
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

  // Tasarım Widget'ı
  Widget _kisiFiltresiButon(String label, String emoji, String? kisiAdi) {
    bool secili = _secilenKisi == kisiAdi;
    return GestureDetector(
      onTap: () => setState(() => _secilenKisi = kisiAdi),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: secili ? Colors.teal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.teal, width: 2),
          boxShadow: secili ? [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 8)] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: secili ? Colors.white : Colors.teal, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}