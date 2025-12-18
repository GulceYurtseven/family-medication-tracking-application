import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ilac_ekle_ekrani.dart';
import '../services/bildirim_servisi.dart';
import '../services/stok_kontrol_servisi.dart';
import '../services/kisi_yoneticisi.dart';

class GunlukPlanEkrani extends StatefulWidget {
  const GunlukPlanEkrani({super.key});

  @override
  State<GunlukPlanEkrani> createState() => _GunlukPlanEkraniState();
}

class _GunlukPlanEkraniState extends State<GunlukPlanEkrani> {
  String? _secilenKisi; // null = Hepsi

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

    // Önce bu vakit zaten içilmiş mi kontrol edelim
    bool zatenIcildi = _vakitBugunTamamMi(icilenTarihler[vakit]);

    int mevcutStok = data['stok'] ?? 0;
    int yeniStok = mevcutStok;
    int ilacIdBase = data['bildirim_id_base'] ?? 0;

    if (zatenIcildi) {
      // --- GERİ ALMA İŞLEMİ (YANLIŞLIKLA BASILDIYSA) ---

      // 1. Stoğu geri iade et
      yeniStok = mevcutStok + 1;

      // 2. İçilen tarih kaydını bu vakit için sil
      icilenTarihler.remove(vakit);

      // 3. Veritabanını güncelle
      await FirebaseFirestore.instance.collection('ilaclar').doc(doc.id).update({
        'stok': yeniStok,
        'icilen_tarihler': icilenTarihler,
      });

      // (Opsiyonel) Bildirimleri geri açmak isterseniz burada tekrar schedule edebilirsiniz.
      // Ancak saat bilgisi dinamik olduğu için genelde sadece veritabanı güncellemesi yeterlidir.

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İlaç içilmedi olarak işaretlendi, stok iade edildi.'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.orange, // Uyarı rengi
          ),
        );
      }

    } else {
      // --- İÇME İŞLEMİ (MEVCUT KODUNUZ) ---
      if (mevcutStok > 0) {
        yeniStok = mevcutStok - 1;

        icilenTarihler[vakit] = Timestamp.now();

        await FirebaseFirestore.instance.collection('ilaclar').doc(doc.id).update({
          'stok': yeniStok,
          'icilen_tarihler': icilenTarihler,
        });

        await BildirimServisi().hatirlaticilariIptalEt(ilacIdBase, vakit);

        await StokKontrolServisi().stokKontrolEt(
          doc.id,
          data['ad'] ?? '',
          data['sahibi'] ?? '',
          yeniStok,
          mevcutStok,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İlaç içildi, hatırlatıcılar kapatıldı.'), duration: Duration(seconds: 1)),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stok bitmiş!'), backgroundColor: Colors.red),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Vazgeç")),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('ilaclar').doc(id).delete();
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
    return simdi.year == kayit.year && simdi.month == kayit.month && simdi.day == kayit.day;
  }

  IconData _vakitIkonuGetir(String vakit) {
    switch (vakit) {
      case 'Sabah': return Icons.wb_twilight;
      case 'Öğle': return Icons.wb_sunny;
      case 'Akşam': return Icons.nights_stay;
      case 'Gece': return Icons.bed;
      default: return Icons.access_time;
    }
  }

  Color _vakitRengiGetir(String vakit) {
    switch (vakit) {
      case 'Sabah': return Colors.orange;
      case 'Öğle': return Colors.yellow.shade700;
      case 'Akşam': return Colors.indigo;
      case 'Gece': return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    String bugun = _bugununGunu();
    List<Map<String, String>> kisiler = KisiYoneticisi().tumKisileriGetir();

    return Column(
      children: [
        // KİŞİ FİLTRESİ
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
                    child: _kisiFiltresiButon(kisi["ad"]!, kisi["emoji"]!, kisi["ad"]),
                  );
                }).toList(),
              ],
            ),
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('ilaclar').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Henüz hiç ilaç eklenmemiş.", style: TextStyle(color: Colors.grey)));
              }

              var ilaclar = snapshot.data!.docs;

              var bugunIlaclar = ilaclar.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                if (_secilenKisi != null && data['sahibi'] != _secilenKisi) {
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
                        _secilenKisi == null ? "$bugun günü için ilaç yok" : "$_secilenKisi için ilaç yok",
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }

              Map<String, List<DocumentSnapshot>> kisiGruplari = {};
              for (var doc in bugunIlaclar) {
                String sahibi = doc['sahibi'] ?? 'Diğer';
                if (!kisiGruplari.containsKey(sahibi)) kisiGruplari[sahibi] = [];
                kisiGruplari[sahibi]!.add(doc);
              }

              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.teal.shade400, Colors.teal.shade700]),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white, size: 22),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(bugun, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text("${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}", style: const TextStyle(fontSize: 14, color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  ...kisiGruplari.entries.map((entry) {
                    String kisi = entry.key;
                    List<DocumentSnapshot> ilacListesi = entry.value;
                    String emoji = KisiYoneticisi().emojiGetir(kisi) ?? "👤";

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 8),
                              Text("$kisi'nin İlaçları", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
                            ],
                          ),
                        ),
                        ...ilacListesi.map((doc) => _ilacKarti(doc, Colors.teal.shade50, context)),
                        const SizedBox(height: 10),
                      ],
                    );
                  }).toList(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

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
              style: TextStyle(color: secili ? Colors.white : Colors.teal, fontWeight: FontWeight.bold),
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

    vakitler.sort((a, b) => ["Sabah", "Öğle", "Akşam", "Gece"].indexOf(a).compareTo(["Sabah", "Öğle", "Akşam", "Gece"].indexOf(b)));

    // Tüm vakitler tamamlandı mı?
    bool tumuTamam = vakitler.isNotEmpty && vakitler.every((v) => _vakitBugunTamamMi(icilenTarihler[v]));

    return Card(
      color: tumuTamam ? Colors.grey.shade200 : cardColor, // Kart rengini biraz daha açık yaptık
      margin: const EdgeInsets.only(bottom: 12),
      elevation: tumuTamam ? 0 : 3, // Tamamlandıysa gölgeyi kaldır
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: tumuTamam ? BorderSide(color: Colors.grey.shade300) : BorderSide.none),
      child: ExpansionTile(
        leading: Icon(
            Icons.medication,
            color: tumuTamam ? Colors.green : Colors.grey.shade800,
            size: 35
        ),
        title: Text(
            data['ad'],
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                decoration: tumuTamam ? TextDecoration.lineThrough : null,
                color: tumuTamam ? Colors.grey : Colors.black
            )
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${data['kullanim_sekli']} • Stok: ${data['stok']}", style: TextStyle(color: Colors.black)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: vakitler.map((vakit) {
                bool icildi = _vakitBugunTamamMi(icilenTarihler[vakit]);
                Color vakitRengi = _vakitRengiGetir(vakit.toString());

                return ActionChip(
                  // İKON: İçildiyse 'Check', değilse vakit ikonu
                  avatar: Icon(
                      icildi ? Icons.check : _vakitIkonuGetir(vakit.toString()),
                      size: 18,
                      color: icildi ? Colors.white : vakitRengi
                  ),

                  // ETİKET: İçildiyse üstü çizili
                  label: Text(
                      vakit.toString(),
                      style: TextStyle(
                        color: icildi ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        decoration: icildi ? TextDecoration.lineThrough : null, // Çizgili yazı
                        decorationColor: Colors.white,
                        decorationThickness: 2.0,
                      )
                  ),

                  // RENK: İçildiyse YEŞİL, değilse Beyaz
                  backgroundColor: icildi ? Colors.green : Colors.white,

                  // KENARLIK: İçildiyse şeffaf, değilse vakit rengi
                  side: BorderSide(
                      color: icildi ? Colors.transparent : vakitRengi,
                      width: 2
                  ),

                  elevation: icildi ? 0 : 2,

                  // TIKLAMA: Artık her durumda tıklanabilir (Toggle)
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
                    IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => IlacEkleEkrani(ilacId: doc.id, mevcutVeri: data)))),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _ilacSil(doc.id, context)),
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