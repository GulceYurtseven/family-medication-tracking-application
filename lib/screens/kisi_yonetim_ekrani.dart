import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../services/aile_yoneticisi.dart';

class KisiYonetimEkrani extends StatefulWidget {
  const KisiYonetimEkrani({super.key});

  @override
  State<KisiYonetimEkrani> createState() => _KisiYonetimEkraniState();
}

class _KisiYonetimEkraniState extends State<KisiYonetimEkrani> {
  final AileYoneticisi _yonetici = AileYoneticisi();

  final List<String> kullanilabilirEmojiler = [
    "👴", "👵", "👨", "👩", "🧑", "👦", "👧", "🧒",
    "👶", "🧓", "👨‍⚕️", "👩‍⚕️", "🤱", "🧔", "👨‍🦳", "👩‍🦳",
    "👨‍🦰", "👩‍🦰", "👱‍♂️", "👱‍♀️", "🙋‍♂️", "🙋‍♀️"
  ];

  void _kisiEkleDialog() {
    final TextEditingController adController = TextEditingController();
    String secilenEmoji = kullanilabilirEmojiler[0];

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
                  decoration: const InputDecoration(
                    labelText: "Kişi Adı",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                const Text("Emoji Seç:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: kullanilabilirEmojiler.length,
                    itemBuilder: (context, index) {
                      String emoji = kullanilabilirEmojiler[index];
                      bool secili = emoji == secilenEmoji;
                      return GestureDetector(
                        onTap: () => setStateDialog(() => secilenEmoji = emoji),
                        child: Container(
                          decoration: BoxDecoration(
                            color: secili ? Colors.teal.shade100 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: secili ? Colors.teal : Colors.grey.shade300,
                              width: secili ? 3 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(emoji, style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () async {
                String ad = adController.text.trim();
                if (ad.isEmpty) return;

                bool basarili = await _yonetici.yeniKisiEkle(ad, secilenEmoji);

                if (basarili) {
                  Navigator.pop(ctx);
                  if (mounted) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("$secilenEmoji $ad eklendi ve takip ediliyor!")),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Bu isimde bir kişi zaten var!")),
                  );
                }
              },
              child: const Text("Ekle", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  /*void _kisiSil(String kisiId, String ad, String emoji) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Kişi Siliniyor ⚠️"),
        content: Text(
          "DİKKAT: $emoji $ad kişisini silerseniz, ona ait TÜM İLAÇLAR ve BİLDİRİMLER de silinecektir.\n\nEmin misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Vazgeç"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _kisiVeVerileriniSil(kisiId, ad);
            },
            child: const Text("EVET, HEPSİNİ SİL"),
          ),
        ],
      ),
    );
  }*/

  /*Future<void> _kisiVeVerileriniSil(String kisiId, String kisiAdi) async {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      String? aileKodu = _yonetici.aktifAileKodu;
      if (aileKodu == null) return;

      // Kişiye ait ilaçları bul ve sil
      QuerySnapshot ilaclar = await FirebaseFirestore.instance
          .collection('aileler')
          .doc(aileKodu)
          .collection('ilaclar')
          .where('kisi_id', isEqualTo: kisiId)
          .get();

      for (var doc in ilaclar.docs) {
        await doc.reference.delete();
      }

      // Kişiyi sil
      bool basarili = await _yonetici.kisiSil(kisiId, kisiAdi);

      if (mounted) {
        Navigator.pop(context); // Loading'i kapat
        setState(() {});

        if (basarili) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Kişi ve verileri temizlendi.")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Varsayılan kişiler silinemez!")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e")),
        );
      }
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kişi Yönetimi"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          // Aile Kodu Göster
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: "Aile Bilgileri",
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Aile Bilgileri"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Aile Kodunuz:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                  GestureDetector(
                    onLongPress: () {
                      // Panoya kopyalama işlemi
                      Clipboard.setData(ClipboardData(text: _yonetici.aktifAileKodu ?? ''));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Aile kodu kopyalandı! ✅")),
                      );
                      Navigator.pop(ctx); // İstersen dialogu kapatabilirsin
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.teal, width: 2),
                        ),
                        child: Text(
                          _yonetici.aktifAileKodu ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                    ),
                  ),
                      const SizedBox(height: 12),
                      const Text(
                        "Bu kodu aile üyelerinizle paylaşabilirsiniz",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Kapat"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _yonetici.aileUyeleriniGetir(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Henüz kişi eklenmemiş."));
          }

          var kisiler = snapshot.data!.docs;

          return Column(
            children: [
              // Bilgilendirme Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.amber.shade50,
                child: Row(
                  children: [
                    Icon(Icons.visibility, color: Colors.amber.shade800),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Sadece takip ettiğiniz kişilerin ilaçlarını göreceksiniz",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Kişi Listesi
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: kisiler.length,
                  itemBuilder: (context, index) {
                    var doc = kisiler[index];
                    var data = doc.data() as Map<String, dynamic>;
                    String ad = data['ad'] ?? '';
                    String emoji = data['emoji'] ?? '👤';
                    bool varsayilan = ad == "Dede" || ad == "Anane";
                    bool takipEdiliyor = _yonetici.kisiTakipEdiliyor(doc.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: takipEdiliyor ? 4 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: takipEdiliyor ? Colors.teal : Colors.grey.shade300,
                          width: takipEdiliyor ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: takipEdiliyor
                              ? Colors.teal.shade100
                              : Colors.grey.shade200,
                          child: Text(emoji, style: const TextStyle(fontSize: 28)),
                        ),
                        title: Text(
                          ad,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: takipEdiliyor ? Colors.black : Colors.grey,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (varsayilan)
                              const Text(
                                "Varsayılan Kişi",
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            if (takipEdiliyor)
                              Row(
                                children: [
                                  Icon(Icons.visibility, size: 14, color: Colors.teal.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Takip ediliyor",
                                    style: TextStyle(
                                      color: Colors.teal.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Takip Et/Etme Switch
                            Switch(
                              value: takipEdiliyor,
                              activeColor: Colors.teal,
                              onChanged: (bool value) async {
                                await _yonetici.kisiTakipDurumunuDegistir(doc.id, value);
                                setState(() {});

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        value
                                            ? "$ad artık takip ediliyor"
                                            : "$ad takipten çıkarıldı",
                                      ),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
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