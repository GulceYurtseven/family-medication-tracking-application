import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/kisi_yoneticisi.dart';
import '../services/bildirim_servisi.dart'; // Bildirim iptali için

class KisiYonetimEkrani extends StatefulWidget {
  const KisiYonetimEkrani({super.key});

  @override
  State<KisiYonetimEkrani> createState() => _KisiYonetimEkraniState();
}

class _KisiYonetimEkraniState extends State<KisiYonetimEkrani> {
  final KisiYoneticisi _yonetici = KisiYoneticisi();
  List<Map<String, String>> _kisiler = [];

  @override
  void initState() {
    super.initState();
    _kisileriYukle();
  }

  void _kisileriYukle() {
    setState(() {
      _kisiler = _yonetici.tumKisileriGetir();
    });
  }

  void _kisiEkleDialog() {
    final TextEditingController adController = TextEditingController();
    String secilenEmoji = _yonetici.kullanilabilirEmojiler[0];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Yeni Kişi Ekle"),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: adController,
                  decoration: const InputDecoration(labelText: "Kişi Adı", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 16),
                const Text("Emoji Seç:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  height: 150,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: 8, crossAxisSpacing: 8),
                    itemCount: _yonetici.kullanilabilirEmojiler.length,
                    itemBuilder: (context, index) {
                      String emoji = _yonetici.kullanilabilirEmojiler[index];
                      bool secili = emoji == secilenEmoji;
                      return GestureDetector(
                        onTap: () => setStateDialog(() => secilenEmoji = emoji),
                        child: Container(
                          decoration: BoxDecoration(
                            color: secili ? Colors.teal.shade100 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: secili ? Colors.teal : Colors.grey.shade300, width: secili ? 3 : 1),
                          ),
                          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () async {
                String ad = adController.text.trim();
                if (ad.isEmpty) return;
                bool basarili = await _yonetici.kisiEkle(ad, secilenEmoji);
                if (basarili) {
                  _kisileriYukle();
                  Navigator.pop(ctx);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$secilenEmoji $ad eklendi!")));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bu isimde bir kişi zaten var!")));
                }
              },
              child: const Text("Ekle", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // --- KRİTİK DEĞİŞİKLİK: SİLME İŞLEMİ GÜNCELLENDİ ---
  void _kisiSil(String ad, String emoji) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Kişi Siliniyor ⚠️"),
        content: Text("DİKKAT: $emoji $ad kişisini silerseniz, ona ait TÜM İLAÇLAR ve BİLDİRİMLER de silinecektir.\n\nEmin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Vazgeç")),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx); // Dialogu kapat
              await _kisiVeVerileriniSil(ad);
            },
            child: const Text("EVET, HEPSİNİ SİL"),
          ),
        ],
      ),
    );
  }

  // Kişiye ait her şeyi silen fonksiyon
  Future<void> _kisiVeVerileriniSil(String kisiAdi) async {
    // 1. Loading göster
    if (mounted) {
      showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
    }

    try {
      // 2. Kişiye ait ilaçları bul
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('ilaclar')
          .where('sahibi', isEqualTo: kisiAdi)
          .get();

      // 3. Her ilacı tek tek gez
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        int ilacIdBase = data['bildirim_id_base'] ?? 0;
        List<dynamic> vakitler = data['vakitler'] ?? [];

        // Bildirimleri İptal Et
        for (var vakit in vakitler) {
          await BildirimServisi().hatirlaticilariIptalEt(ilacIdBase, vakit.toString());
        }

        // İlacı Veritabanından Sil
        await doc.reference.delete();
      }

      // 4. Kişiyi Listeden Sil
      bool basarili = await _yonetici.kisiSil(kisiAdi);

      if (mounted) {
        Navigator.pop(context); // Loading'i kapat
        _kisileriYukle();
        if (basarili) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kişi ve verileri temizlendi.")));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Varsayılan kişiler silinemez!")));
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Loading'i kapat
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kişi Yönetimi"), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: _kisiler.isEmpty
          ? const Center(child: Text("Henüz kişi eklenmemiş."))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _kisiler.length,
        itemBuilder: (context, index) {
          var kisi = _kisiler[index];
          bool varsayilan = kisi["ad"] == "Dede" || kisi["ad"] == "Anane";

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.teal.shade100, child: Text(kisi["emoji"]!, style: const TextStyle(fontSize: 28))),
              title: Text(kisi["ad"]!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: varsayilan ? const Text("Varsayılan Kişi", style: TextStyle(color: Colors.grey)) : null,
              trailing: varsayilan
                  ? const Icon(Icons.lock, color: Colors.grey)
                  : IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _kisiSil(kisi["ad"]!, kisi["emoji"]!),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _kisiEkleDialog,
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text("Kişi Ekle", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}