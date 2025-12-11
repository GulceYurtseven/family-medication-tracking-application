import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ilac_ekle_ekrani.dart';
import '../services/bildirim_servisi.dart';

class GunlukPlanEkrani extends StatelessWidget {
  const GunlukPlanEkrani({super.key});

  // Bugünün gününü döndür (Pazartesi, Salı vb.)
  String _bugununGunu() {
    const gunler = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"];
    int bugun = DateTime.now().weekday; // 1=Pazartesi, 7=Pazar
    return gunler[bugun - 1];
  }

  // İlaç bugün içilmeli mi?
  bool _ilacBugunIcilmeliMi(Map<String, dynamic> data) {
    bool herGun = data['her_gun'] ?? true;
    if (herGun) return true;

    List<dynamic> gunler = data['gunler'] ?? [];
    return gunler.contains(_bugununGunu());
  }

  void _vakitIcildiIsaretle(DocumentSnapshot doc, String vakit, BuildContext context) async {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    int mevcutStok = data['stok'] ?? 0;
    Map<String, dynamic> icilenTarihler = data['icilen_tarihler'] ?? {};
    int ilacIdBase = data['bildirim_id_base'] ?? 0;

    if (mevcutStok > 0) {
      icilenTarihler[vakit] = Timestamp.now();
      await FirebaseFirestore.instance.collection('ilaclar').doc(doc.id).update({
        'stok': mevcutStok - 1,
        'icilen_tarihler': icilenTarihler,
      });

      await BildirimServisi().hatirlaticilariIptalEt(ilacIdBase, vakit);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İlaç içildi, hatırlatıcılar kapatıldı.'), duration: Duration(seconds: 1)));
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok bitmiş!'), backgroundColor: Colors.red));
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

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('ilaclar').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medication_outlined, size: 100, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text("Henüz hiç ilaç eklenmemiş.", style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
              ],
            ),
          );
        }

        var ilaclar = snapshot.data!.docs;

        // BUGÜN İÇİLMESİ GEREKEN İLAÇLARI FİLTRELE
        var bugunIlaclar = ilaclar.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return _ilacBugunIcilmeliMi(data);
        }).toList();

        if (bugunIlaclar.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 100, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text("$bugun günü için ilaç yok 🎉", style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
              ],
            ),
          );
        }

        var dedenin = bugunIlaclar.where((doc) => doc['sahibi'] == 'Dede').toList();
        var ananenin = bugunIlaclar.where((doc) => doc['sahibi'] == 'Anane').toList();

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Bugünün Tarihi
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade400, Colors.teal.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.white, size: 30),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bugun,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (dedenin.isNotEmpty) ...[
              _baslik("👴 Dede'nin İlaçları", Colors.blue.shade800),
              ...dedenin.map((doc) => _ilacKarti(doc, Colors.blue.shade50, context)),
              const SizedBox(height: 20),
            ],
            if (ananenin.isNotEmpty) ...[
              _baslik("👵 Anane'nin İlaçları", Colors.pink.shade800),
              ...ananenin.map((doc) => _ilacKarti(doc, Colors.pink.shade50, context)),
            ],
          ],
        );
      },
    );
  }

  Widget _baslik(String text, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
  );

  Widget _ilacKarti(DocumentSnapshot doc, Color cardColor, BuildContext context) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String id = doc.id;

    List<dynamic> vakitler = data['vakitler'] ?? [];
    Map<String, dynamic> icilenTarihler = data['icilen_tarihler'] ?? {};

    vakitler.sort((a, b) {
      List order = ["Sabah", "Öğle", "Akşam", "Gece"];
      return order.indexOf(a).compareTo(order.indexOf(b));
    });

    bool tumuTamam = vakitler.isNotEmpty && vakitler.every((v) => _vakitBugunTamamMi(icilenTarihler[v]));

    return Card(
      color: tumuTamam ? Colors.grey.shade300 : cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: tumuTamam ? 1 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(
          Icons.medication,
          color: tumuTamam ? Colors.green : Colors.grey.shade800,
          size: 35,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                data['ad'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: tumuTamam ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Row(
              children: vakitler.map((v) => Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(_vakitIkonuGetir(v.toString()), size: 16, color: _vakitRengiGetir(v.toString())),
              )).toList(),
            )
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("${data['kullanim_sekli']} • Stok: ${data['stok']}"),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: vakitler.map((vakit) {
                bool icildi = _vakitBugunTamamMi(icilenTarihler[vakit]);
                Color vakitRengi = _vakitRengiGetir(vakit.toString());

                return ActionChip(
                  avatar: Icon(
                    icildi ? Icons.check_circle : _vakitIkonuGetir(vakit.toString()),
                    size: 18,
                    color: icildi ? Colors.white : vakitRengi,
                  ),
                  label: Text(
                    vakit.toString(),
                    style: TextStyle(
                      color: icildi ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: icildi ? Colors.green.shade600 : Colors.white,
                  disabledColor: Colors.green.shade600,
                  side: BorderSide(
                    color: icildi ? Colors.green.shade800 : vakitRengi,
                    width: 2,
                  ),
                  elevation: icildi ? 0 : 2,
                  shadowColor: vakitRengi.withOpacity(0.3),
                  onPressed: icildi ? null : () {
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
                        MaterialPageRoute(builder: (context) => IlacEkleEkrani(ilacId: id, mevcutVeri: data)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _ilacSil(id, context),
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