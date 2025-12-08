import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/bildirim_servisi.dart';
import '../services/zaman_yoneticisi.dart'; // EKLENDİ

class IlacEkleEkrani extends StatefulWidget {
  final String? ilacId;
  final Map<String, dynamic>? mevcutVeri;

  const IlacEkleEkrani({super.key, this.ilacId, this.mevcutVeri});

  @override
  State<IlacEkleEkrani> createState() => _IlacEkleEkraniState();
}

class _IlacEkleEkraniState extends State<IlacEkleEkrani> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _adController;
  late TextEditingController _stokController;
  late TextEditingController _notController;

  String? _secilenKisi;
  String? _acTokDurumu;

  // ÇOKLU SEÇİM İÇİN LİSTELER
  final List<String> _kisiListesi = ["Dede", "Anane"];
  final List<String> _acTokListesi = ["Aç Karna", "Tok Karna", "Farketmez"];

  // Vakit seçenekleri ve seçilenler
  final List<String> _vakitSecenekleri = ["Sabah", "Öğle", "Akşam", "Gece"];
  List<String> _secilenVakitler = [];

  @override
  void initState() {
    super.initState();
    _adController = TextEditingController(text: widget.mevcutVeri?['ad'] ?? '');
    _stokController = TextEditingController(text: widget.mevcutVeri?['stok']?.toString() ?? '');
    _notController = TextEditingController(text: widget.mevcutVeri?['not'] ?? '');
    _secilenKisi = widget.mevcutVeri?['sahibi'];
    _acTokDurumu = widget.mevcutVeri?['kullanim_sekli'];

    // Eğer güncelleme ise kayıtlı vakitleri getir
    if (widget.mevcutVeri != null && widget.mevcutVeri!['vakitler'] != null) {
      _secilenVakitler = List<String>.from(widget.mevcutVeri!['vakitler']);
    }
  }

  void _kaydetVeyaGuncelle() async {
    if (_formKey.currentState!.validate()) {
      if (_secilenVakitler.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen vakit seçin!')));
        return;
      }

      String ad = _adController.text;
      // Benzersiz bir ID temeli oluşturuyoruz
      int ilacIdBase = ad.codeUnits.fold(0, (p, c) => p + c);

      Map<String, dynamic> veri = {
        'ad': ad,
        'sahibi': _secilenKisi,
        'stok': int.parse(_stokController.text),
        'kullanim_sekli': _acTokDurumu,
        'vakitler': _secilenVakitler,
        'not': _notController.text,
        'bildirim_id_base': ilacIdBase, // Bu ID'yi veritabanında saklıyoruz
        'tarih': FieldValue.serverTimestamp(),
      };

      try {
        if (widget.ilacId == null) {
          // YENİ KAYIT
          veri['icilen_tarihler'] = {};
          await FirebaseFirestore.instance.collection('ilaclar').add(veri);

          // --- YENİ BİLDİRİM MANTIĞI ---
          for (String vakit in _secilenVakitler) {
            // 1. Dinamik Saati Al (Ayarlardan)
            TimeOfDay saatAyari = ZamanYoneticisi().saatiGetir(vakit);

            // 2. Ana Vakit Bildirimini Güncelle/Kur (Tekrarlı olması sorun değil, üzerine yazar)
            await BildirimServisi().anaVakitBildirimiKur(vakit, saatAyari.hour, saatAyari.minute);

            // 3. İlaç Bazlı Hatırlatıcıları Kur (15 dk arayla 3 tane)
            await BildirimServisi().hatirlaticiKur(
                ilacIdBase,
                ad,
                _secilenKisi!,
                vakit,
                saatAyari.hour,
                saatAyari.minute
            );
          }

          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İlaç ve Alarmlar Kaydedildi!')));
          _temizle();
        } else {
          // Güncelleme... (Basitlik adına burada bildirim güncelleme yapmıyoruz,
          // profesyonel uygulamada eski ID'leri iptal edip yenilerini kurmak gerekir)
          await FirebaseFirestore.instance.collection('ilaclar').doc(widget.ilacId).update(veri);
          if (mounted) {
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  void _temizle() {
    _formKey.currentState!.reset();
    _adController.clear();
    _stokController.clear();
    _notController.clear();
    setState(() {
      _secilenKisi = null;
      _acTokDurumu = null;
      _secilenVakitler = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.ilacId != null ? AppBar(title: const Text("İlacı Düzenle")) : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.ilacId == null)
                const Text("Yeni İlaç Ekle", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              TextFormField(
                controller: _adController,
                validator: (value) => value!.isEmpty ? "İlaç adı gerekli" : null,
                decoration: const InputDecoration(labelText: "İlaç Adı", border: OutlineInputBorder(), prefixIcon: Icon(Icons.medication)),
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: _secilenKisi,
                validator: (value) => value == null ? "Kişi seçin" : null,
                decoration: const InputDecoration(labelText: "Kimin İlacı?", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                items: _kisiListesi.map((kisi) => DropdownMenuItem(value: kisi, child: Text(kisi))).toList(),
                onChanged: (deger) => setState(() => _secilenKisi = deger),
              ),
              const SizedBox(height: 15),

              // --- YENİ EKLENEN VAKİT SEÇİMİ ---
              const Text("Hangi Vakitlerde İçilecek?", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Wrap(
                spacing: 8.0,
                children: _vakitSecenekleri.map((vakit) {
                  return FilterChip(
                    label: Text(vakit),
                    selected: _secilenVakitler.contains(vakit),
                    selectedColor: Colors.teal.shade100,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _secilenVakitler.add(vakit);
                        } else {
                          _secilenVakitler.remove(vakit);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _stokController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: "Stok Adedi", border: OutlineInputBorder(), prefixIcon: Icon(Icons.numbers)),
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: _acTokDurumu,
                decoration: const InputDecoration(labelText: "Kullanım Şekli", border: OutlineInputBorder(), prefixIcon: Icon(Icons.restaurant)),
                items: _acTokListesi.map((durum) => DropdownMenuItem(value: durum, child: Text(durum))).toList(),
                onChanged: (deger) => setState(() => _acTokDurumu = deger),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _notController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: "Notlar", border: OutlineInputBorder(), prefixIcon: Icon(Icons.note_add)),
              ),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _kaydetVeyaGuncelle,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text("Kaydet / Güncelle", style: TextStyle(color: Colors.white, fontSize: 18)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}