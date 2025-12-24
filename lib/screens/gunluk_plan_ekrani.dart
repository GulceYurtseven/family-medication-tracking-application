import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ilac_ekle_ekrani.dart';
import '../services/stok_kontrol_servisi.dart';
import '../services/aile_yoneticisi.dart';

class GunlukPlanEkrani extends StatefulWidget {
  const GunlukPlanEkrani({super.key});

  @override
  State<GunlukPlanEkrani> createState() => _GunlukPlanEkraniState();
}

class _GunlukPlanEkraniState extends State<GunlukPlanEkrani> {
  final _yonetici = AileYoneticisi();
  String? _secilenKisiFiltresi; // null = Hepsi

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

  String _bugununGunu() {
    const gunler = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"];
    int bugun = DateTime.now().weekday;
    return gunler[bugun - 1];
  }

  bool _ilacBugunIcilmeliMi(Map<String, dynamic> data) {
    bool herGun = data['her_gun'] ?? true;
    if (herGun) return true;
    List<dynamic> gunler = data['gunler'] ?? [];
    return gunler.contains(_bugununGunu());
  }

  void _vakitIcildiIsaretle(DocumentSnapshot doc, String vakit, BuildContext context) async {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    Map<String, dynamic> icilenTarihler = Map<String, dynamic>.from(data['icilen_tarihler'] ?? {});

    bool zatenIcildi = _vakitBugunTamamMi(icilenTarihler[vakit]);

    int mevcutStok = data['stok'] ?? 0;
    int yeniStok = mevcutStok;

    if (zatenIcildi) {
      // GERİ ALMA
      yeniStok = mevcutStok + 1;
      icilenTarihler.remove(vakit);

      await _yonetici.ilacGuncelle(doc.id, {
        'stok': yeniStok,
        'icilen_tarihler': icilenTarihler,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İlaç içilmedi olarak işaretlendi, stok iade edildi.'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      // İÇME İŞLEMİ
      if (mevcutStok > 0) {
        yeniStok = mevcutStok - 1;
        icilenTarihler[vakit] = Timestamp.now();

        await _yonetici.ilacGuncelle(doc.id, {
          'stok': yeniStok,
          'icilen_tarihler': icilenTarihler,
        });

        await StokKontrolServisi().stokKontrolEt(
          doc.id,
          data['ad'] ?? '',
          _kisiCache[data['kisi_id']]?['ad'] ?? 'Bilinmeyen',
          yeniStok,
          mevcutStok,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('İlaç içildi, hatırlatıcılar kapatıldı.'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stok bitmiş!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _ilacSil(String id, BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Siliniyor"),
        content: const Text("Bu ilacı silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Vazgeç"),
          ),
          TextButton(
            onPressed: () {
              _yonetici.ilacSil(id);
              Navigator.pop(ctx);
            },
            child: const Text("SİL", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  bool _vakitBugunTamamMi(dynamic timestamp) {
    if (timestamp == null) return false;
    DateTime simdi = DateTime.now();
    DateTime kayit = (timestamp as Timestamp).toDate();
    return simdi.year == kayit.year &&
        simdi.month == kayit.month &&
        simdi.day == kayit.day;
  }

  IconData _vakitIkonuGetir(String vakit) {
    switch (vakit) {
      case 'Sabah':
        return Icons.wb_twilight;
      case 'Öğle':
        return Icons.wb_sunny;
      case 'Akşam':
        return Icons.nights_stay;
      case 'Gece':
        return Icons.bed;
      default:
        return Icons.access_time;
    }
  }

  Color _vakitRengiGetir(String vakit) {
    switch (vakit) {
      case 'Sabah':
        return Colors.orange;
      case 'Öğle':
        return Colors.yellow.shade700;
      case 'Akşam':
        return Colors.indigo;
      case 'Gece':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    String bugun = _bugununGunu();

    // Takip edilen kişileri al
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
        // KİŞİ FİLTRESİ
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

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _yonetici.takipEdilenIlaclariGetir(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    "Henüz hiç ilaç eklenmemiş.",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              var ilaclar = snapshot.data!.docs;

              // Bugün içilmeli ilaçları filtrele
              var bugunIlaclar = ilaclar.where((doc) {
                var data = doc.data() as Map<String, dynamic>;

                // Kişi filtresi uygula
                if (_secilenKisiFiltresi != null && data['kisi_id'] != _secilenKisiFiltresi) {
                  return false;
                }

                return _ilacBugunIcilmeliMi(data);
              }).toList();

              if (bugunIlaclar.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_available, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        _secilenKisiFiltresi == null
                            ? "$bugun günü için ilaç yok"
                            : "Bu kişi için bugün ilaç yok",
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }

              // Kişilere göre grupla
              Map<String, List<DocumentSnapshot>> kisiGruplari = {};
              for (var doc in bugunIlaclar) {
                String kisiId = doc['kisi_id'] ?? '';
                if (!kisiGruplari.containsKey(kisiId)) kisiGruplari[kisiId] = [];
                kisiGruplari[kisiId]!.add(doc);
              }

              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Tarih başlığı
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade400, Colors.teal.shade700],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white, size: 22),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bugun,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                              style: const TextStyle(fontSize: 14, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Kişi grupları
                  ...kisiGruplari.entries.map((entry) {
                    String kisiId = entry.key;
                    List<DocumentSnapshot> ilacListesi = entry.value;
                    String emoji = _kisiCache[kisiId]?['emoji'] ?? '👤';
                    String kisiAdi = _kisiCache[kisiId]?['ad'] ?? 'Bilinmeyen';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 8),
                              Text(
                                "$kisiAdi'nin İlaçları",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...ilacListesi.map((doc) => _ilacKarti(doc, Colors.teal.shade50, context)),
                        const SizedBox(height: 10),
                      ],
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _kisiFiltresiButon(String label, String emoji, String? kisiId) {
    bool secili = _secilenKisiFiltresi == kisiId;
    return GestureDetector(
      onTap: () => setState(() => _secilenKisiFiltresi = kisiId),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ilacKarti(DocumentSnapshot doc, Color cardColor, BuildContext context) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    List<dynamic> vakitler = data['vakitler'] ?? [];
    Map<String, dynamic> icilenTarihler = data['icilen_tarihler'] ?? {};

    vakitler.sort((a, b) => ["Sabah", "Öğle", "Akşam", "Gece"]
        .indexOf(a)
        .compareTo(["Sabah", "Öğle", "Akşam", "Gece"].indexOf(b)));

    bool tumuTamam = vakitler.isNotEmpty &&
        vakitler.every((v) => _vakitBugunTamamMi(icilenTarihler[v]));

    return Card(
      color: tumuTamam ? Colors.grey.shade200 : cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: tumuTamam ? 0 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: tumuTamam
            ? BorderSide(color: Colors.grey.shade300)
            : BorderSide.none,
      ),
      child: ExpansionTile(
        leading: Icon(
          Icons.medication,
          color: tumuTamam ? Colors.green : Colors.grey.shade800,
          size: 35,
        ),
        title: Text(
          data['ad'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            decoration: tumuTamam ? TextDecoration.lineThrough : null,
            color: tumuTamam ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${data['kullanim_sekli']} • Stok: ${data['stok']}",
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: vakitler.map((vakit) {
                bool icildi = _vakitBugunTamamMi(icilenTarihler[vakit]);
                Color vakitRengi = _vakitRengiGetir(vakit.toString());

                return ActionChip(
                  avatar: Icon(
                    icildi ? Icons.check : _vakitIkonuGetir(vakit.toString()),
                    size: 18,
                    color: icildi ? Colors.white : vakitRengi,
                  ),
                  label: Text(
                    vakit.toString(),
                    style: TextStyle(
                      color: icildi ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      decoration: icildi ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.white,
                      decorationThickness: 2.0,
                    ),
                  ),
                  backgroundColor: icildi ? Colors.green : Colors.white,
                  side: BorderSide(
                    color: icildi ? Colors.transparent : vakitRengi,
                    width: 2,
                  ),
                  elevation: icildi ? 0 : 2,
                  onPressed: () {
                    _vakitIcildiIsaretle(doc, vakit.toString(), context);
                  },
                );
              }).toList(),
            )
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text("Not: ${data['not'] ?? 'Yok'}")),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => IlacEkleEkrani(
                            ilacId: doc.id,
                            mevcutVeri: data,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _ilacSil(doc.id, context),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}