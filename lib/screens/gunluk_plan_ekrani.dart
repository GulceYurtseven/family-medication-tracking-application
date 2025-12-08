import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ilac_ekle_ekrani.dart';
import '../services/bildirim_servisi.dart'; // Bildirim servisini import ettik

class GunlukPlanEkrani extends StatelessWidget {
  const GunlukPlanEkrani({super.key});

  // --- İŞLEV FONKSİYONLARI ---

  // 1. İlaç içildiğinde çalışan ana fonksiyon
  void _vakitIcildiIsaretle(DocumentSnapshot doc, String vakit, BuildContext context) async {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    int mevcutStok = data['stok'] ?? 0;
    Map<String, dynamic> icilenTarihler = data['icilen_tarihler'] ?? {};
    int ilacIdBase = data['bildirim_id_base'] ?? 0;

    if (mevcutStok > 0) {
      // 1. Veritabanı
      icilenTarihler[vakit] = Timestamp.now();
      await FirebaseFirestore.instance.collection('ilaclar').doc(doc.id).update({
        'stok': mevcutStok - 1,
        'icilen_tarihler': icilenTarihler,
      });

      // 2. HATIRLATICILARI İPTAL ET (Yeni Fonksiyon)
      // Bu fonksiyon o vakit için kurulmuş 3 tane (15-30-45 dk) bildirimi iptal eder.
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

  // 2. İlaç Silme
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

  // --- YARDIMCI KONTROLLER ---

  // O vakit bugün içildi mi?
  bool _vakitBugunTamamMi(dynamic timestamp) {
    if (timestamp == null) return false;
    DateTime simdi = DateTime.now();
    DateTime kayit = (timestamp as Timestamp).toDate();
    return simdi.year == kayit.year && simdi.month == kayit.month && simdi.day == kayit.day;
  }

  // İkon Belirleme
  IconData _vakitIkonuGetir(String vakit) {
    switch (vakit) {
      case 'Sabah': return Icons.wb_twilight;
      case 'Öğle': return Icons.wb_sunny;
      case 'Akşam': return Icons.nights_stay;
      case 'Gece': return Icons.bed;
      default: return Icons.access_time;
    }
  }

  // Renk Belirleme
  Color _vakitRengiGetir(String vakit) {
    switch (vakit) {
      case 'Sabah': return Colors.orange;
      case 'Öğle': return Colors.yellow.shade700;
      case 'Akşam': return Colors.indigo;
      case 'Gece': return Colors.purple;
      default: return Colors.grey;
    }
  }

  // --- ARAYÜZ ---

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('ilaclar').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Henüz hiç ilaç eklenmemiş."));

        var ilaclar = snapshot.data!.docs;
        var dedenin = ilaclar.where((doc) => doc['sahibi'] == 'Dede').toList();
        var ananenin = ilaclar.where((doc) => doc['sahibi'] == 'Anane').toList();

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
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

  Widget _baslik(String text, Color color) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)));

  Widget _ilacKarti(DocumentSnapshot doc, Color cardColor, BuildContext context) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String id = doc.id;

    // Verileri güvenli çekelim
    List<dynamic> vakitler = data['vakitler'] ?? []; // ['Sabah', 'Akşam']
    Map<String, dynamic> icilenTarihler = data['icilen_tarihler'] ?? {};

    // Vakitleri sıraya dizelim (Sabah -> Gece)
    vakitler.sort((a, b) {
      List order = ["Sabah", "Öğle", "Akşam", "Gece"];
      return order.indexOf(a).compareTo(order.indexOf(b));
    });

    // Bugün hepsi içildi mi kontrolü (Üstünü çizmek için)
    bool tumuTamam = vakitler.isNotEmpty && vakitler.every((v) => _vakitBugunTamamMi(icilenTarihler[v]));

    return Card(
      color: tumuTamam ? Colors.grey.shade300 : cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(Icons.medication, color: tumuTamam ? Colors.green : Colors.grey.shade800, size: 35),
        title: Row(
          children: [
            Expanded(
              child: Text(data['ad'], style: TextStyle(fontWeight: FontWeight.bold, decoration: tumuTamam ? TextDecoration.lineThrough : null)),
            ),
            // Küçük ikonlar
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
            Text("${data['kullanim_sekli']} - Stok: ${data['stok']}"),
            const SizedBox(height: 8),

            // --- İŞTE SORDUĞUN KISIM BURASI ---
            // Her vakit için bir buton oluşturuyoruz
            Wrap(
              spacing: 8,
              children: vakitler.map((vakit) {
                bool icildi = _vakitBugunTamamMi(icilenTarihler[vakit]);
                return ActionChip(
                  avatar: Icon(icildi ? Icons.check : _vakitIkonuGetir(vakit.toString()), size: 16, color: icildi ? Colors.white : _vakitRengiGetir(vakit.toString())),
                  label: Text(vakit.toString(), style: TextStyle(color: icildi ? Colors.white : Colors.black)),
                  backgroundColor: icildi ? Colors.green : Colors.white,
                  side: BorderSide(color: icildi ? Colors.transparent : Colors.grey.shade300),

                  // SENİN ARADIĞIN onPressed BURADA:
                  onPressed: icildi ? null : () {
                    _vakitIcildiIsaretle(doc, vakit.toString(), context);
                  },
                );
              }).toList(),
            )
            // ----------------------------------
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
                    IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => IlacEkleEkrani(ilacId: id, mevcutVeri: data)))),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _ilacSil(id, context)),
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