import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/aile_yoneticisi.dart';

class StokEkrani extends StatefulWidget {
  const StokEkrani({super.key});

  @override
  State<StokEkrani> createState() => _StokEkraniState();
}

class _StokEkraniState extends State<StokEkrani> {
  final _yonetici = AileYoneticisi();
  String _aramaMetni = "";
  String? _secilenKisi;

  // Kişi bilgilerini cache'leyeceğiz
  Map<String, Map<String, String>> _kisiCache = {};

  @override
  void initState() {
    super.initState();
    _kisileriYukle();
  }

  void _kisileriYukle() async {
    String? aileKodu = _yonetici.aktifAileKodu;
    if (aileKodu == null) return;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('aileler')
        .doc(aileKodu)
        .collection('kisiler')
        .get();

    setState(() {
      _kisiCache = {
        for (var doc in snapshot.docs)
          doc.id: {
            'ad': (doc.data() as Map<String, dynamic>)['ad'] ?? 'Bilinmeyen',
            'emoji': (doc.data() as Map<String, dynamic>)['emoji'] ?? '👤',
          }
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    // Takip edilen kişiler
    List<String> takipEdilenler = _yonetici.takipEdilenKisiler;

    // Filtre için kişi listesi
    List<Map<String, String>> filtreKisiler = takipEdilenler
        .where((id) => _kisiCache.containsKey(id))
        .map((id) => {
      'id': id,
      'ad': _kisiCache[id]!['ad']!,
      'emoji': _kisiCache[id]!['emoji']!,
    })
        .toList();

    return Column(
      children: [
        // KİŞİ SEÇİM BUTONLARI
        if (filtreKisiler.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _kisiFiltresiButon("Hepsi", "👥", null),
                  const SizedBox(width: 8),
                  ...filtreKisiler.map((kisi) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _kisiFiltresiButon(
                        kisi["ad"]!,
                        kisi["emoji"]!,
                        kisi["id"],
                      ),
                    );
                  }),
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
            stream: _yonetici.takipEdilenIlaclariGetir(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Kayıtlı ilaç yok."));
              }

              var docs = snapshot.data!.docs.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                String ad = (data['ad'] ?? '').toString().toLowerCase();
                String kisiId = data['kisi_id'] ?? '';
                bool aramaUygun = ad.contains(_aramaMetni);
                bool kisiUygun = _secilenKisi == null || kisiId == _secilenKisi;
                return aramaUygun && kisiUygun;
              }).toList();

              if (docs.isEmpty) {
                return const Center(child: Text("Sonuç bulunamadı."));
              }

              // Stok durumuna göre sırala (düşükten yükseğe)
              docs.sort((a, b) {
                int stokA = (a.data() as Map<String, dynamic>)['stok'] ?? 0;
                int stokB = (b.data() as Map<String, dynamic>)['stok'] ?? 0;
                return stokA.compareTo(stokB);
              });

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var data = docs[index].data() as Map<String, dynamic>;
                  int stok = data['stok'] ?? 0;
                  bool kritikStok = stok < 5;
                  String kisiId = data['kisi_id'] ?? '';
                  String emoji = _kisiCache[kisiId]?['emoji'] ?? '👤';
                  String kisiAdi = _kisiCache[kisiId]?['ad'] ?? 'Bilinmeyen';

                  return Card(
                    color: kritikStok ? Colors.red.shade100 : Colors.white,
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.shade100,
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                      title: Text(
                        data['ad'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      subtitle: Text(
                        "Sahibi: $kisiAdi",
                        style: const TextStyle(color: Colors.black),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: kritikStok ? Colors.red : Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "$stok Adet",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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

  Widget _kisiFiltresiButon(String label, String emoji, String? kisiId) {
    bool secili = _secilenKisi == kisiId;
    return GestureDetector(
      onTap: () => setState(() => _secilenKisi = kisiId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: secili ? Colors.teal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.teal, width: 2),
          boxShadow: secili
              ? [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 8)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: secili ? Colors.white : Colors.teal,
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