import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StokEkrani extends StatefulWidget {
  const StokEkrani({super.key});

  @override
  State<StokEkrani> createState() => _StokEkraniState();
}

class _StokEkraniState extends State<StokEkrani> {
  String _aramaMetni = "";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Kayıtlı ilaç yok."));

              var docs = snapshot.data!.docs;

              // ARAMA FİLTRESİ (Flutter tarafında yapıyoruz)
              var filtrelenmisDocs = docs.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                String ad = (data['ad'] ?? '').toString().toLowerCase();
                return ad.contains(_aramaMetni);
              }).toList();

              if (filtrelenmisDocs.isEmpty) return const Center(child: Text("Sonuç bulunamadı."));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtrelenmisDocs.length,
                itemBuilder: (context, index) {
                  var data = filtrelenmisDocs[index].data() as Map<String, dynamic>;
                  int stok = data['stok'] ?? 0;
                  bool kritikStok = stok < 5;

                  return Card(
                    color: kritikStok ? Colors.red.shade100 : Colors.white,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: data['sahibi'] == 'Dede' ? Colors.blue : Colors.pink,
                        child: Icon(data['sahibi'] == 'Dede' ? Icons.man : Icons.woman, color: Colors.white),
                      ),
                      title: Text(data['ad'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Sahibi: ${data['sahibi']}"),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kritikStok ? Colors.red : Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text("$stok Adet", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
}