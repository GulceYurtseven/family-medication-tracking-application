import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/bildirim_servisi.dart';
import '../services/zaman_yoneticisi.dart';

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

  final List<String> _kisiListesi = ["Dede", "Anane"];
  final List<String> _acTokListesi = ["Aç Karna", "Tok Karna", "Farketmez"];

  // Vakit seçenekleri
  final List<String> _vakitSecenekleri = ["Sabah", "Öğle", "Akşam", "Gece"];
  List<String> _secilenVakitler = [];

  // YENİ: Gün seçenekleri
  final List<Map<String, dynamic>> _gunSecenekleri = [
    {"ad": "Pazartesi", "kisa": "Pzt", "icon": Icons.calendar_today},
    {"ad": "Salı", "kisa": "Sal", "icon": Icons.calendar_today},
    {"ad": "Çarşamba", "kisa": "Çar", "icon": Icons.calendar_today},
    {"ad": "Perşembe", "kisa": "Per", "icon": Icons.calendar_today},
    {"ad": "Cuma", "kisa": "Cum", "icon": Icons.calendar_today},
    {"ad": "Cumartesi", "kisa": "Cmt", "icon": Icons.calendar_today},
    {"ad": "Pazar", "kisa": "Paz", "icon": Icons.calendar_today},
  ];
  List<String> _secilenGunler = [];
  bool _herGun = true; // Her gün mi yoksa seçili günler mi?

  @override
  void initState() {
    super.initState();
    _adController = TextEditingController(text: widget.mevcutVeri?['ad'] ?? '');
    _stokController = TextEditingController(text: widget.mevcutVeri?['stok']?.toString() ?? '');
    _notController = TextEditingController(text: widget.mevcutVeri?['not'] ?? '');
    _secilenKisi = widget.mevcutVeri?['sahibi'];
    _acTokDurumu = widget.mevcutVeri?['kullanim_sekli'];

    if (widget.mevcutVeri != null && widget.mevcutVeri!['vakitler'] != null) {
      _secilenVakitler = List<String>.from(widget.mevcutVeri!['vakitler']);
    }

    // YENİ: Gün bilgilerini yükle
    if (widget.mevcutVeri != null) {
      _herGun = widget.mevcutVeri?['her_gun'] ?? true;
      if (widget.mevcutVeri!['gunler'] != null) {
        _secilenGunler = List<String>.from(widget.mevcutVeri!['gunler']);
      }
    }
  }

  void _kaydetVeyaGuncelle() async {
    if (_formKey.currentState!.validate()) {
      if (_secilenVakitler.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen vakit seçin!')));
        return;
      }

      if (!_herGun && _secilenGunler.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen gün seçin veya "Her Gün" seçeneğini işaretleyin!')));
        return;
      }

      String ad = _adController.text;
      int ilacIdBase = ad.codeUnits.fold(0, (p, c) => p + c);

      Map<String, dynamic> veri = {
        'ad': ad,
        'sahibi': _secilenKisi,
        'stok': int.parse(_stokController.text),
        'kullanim_sekli': _acTokDurumu,
        'vakitler': _secilenVakitler,
        'not': _notController.text,
        'bildirim_id_base': ilacIdBase,
        'tarih': FieldValue.serverTimestamp(),
        'her_gun': _herGun,
        'gunler': _herGun ? [] : _secilenGunler, // Her gün ise boş liste
      };

      try {
        if (widget.ilacId == null) {
          // YENİ KAYIT
          veri['icilen_tarihler'] = {};
          await FirebaseFirestore.instance.collection('ilaclar').add(veri);

          // Bildirimleri kur
          for (String vakit in _secilenVakitler) {
            TimeOfDay saatAyari = ZamanYoneticisi().saatiGetir(vakit);
            await BildirimServisi().anaVakitBildirimiKur(vakit, saatAyari.hour, saatAyari.minute);
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
          // GÜNCELLEME
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
      _secilenGunler = [];
      _herGun = true;
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
                const Text("Yeni İlaç Ekle", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // İlaç Adı
              TextFormField(
                controller: _adController,
                validator: (value) => value!.isEmpty ? "İlaç adı gerekli" : null,
                decoration: const InputDecoration(
                  labelText: "İlaç Adı",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medication, color: Colors.teal),
                ),
              ),
              const SizedBox(height: 15),

              // Kişi Seçimi
              DropdownButtonFormField<String>(
                value: _secilenKisi,
                validator: (value) => value == null ? "Kişi seçin" : null,
                decoration: const InputDecoration(
                  labelText: "Kimin İlacı?",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person, color: Colors.teal),
                ),
                items: _kisiListesi.map((kisi) => DropdownMenuItem(value: kisi, child: Text(kisi))).toList(),
                onChanged: (deger) => setState(() => _secilenKisi = deger),
              ),
              const SizedBox(height: 20),

              // Vakit Seçimi
              const Text("Hangi Vakitlerde İçilecek?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: _vakitSecenekleri.map((vakit) {
                  IconData icon = Icons.access_time;
                  Color color = Colors.grey;
                  if (vakit == "Sabah") { icon = Icons.wb_twilight; color = Colors.orange; }
                  if (vakit == "Öğle") { icon = Icons.wb_sunny; color = Colors.yellow.shade800; }
                  if (vakit == "Akşam") { icon = Icons.nights_stay; color = Colors.indigo; }
                  if (vakit == "Gece") { icon = Icons.bed; color = Colors.purple; }

                  return FilterChip(
                    avatar: Icon(icon, size: 20, color: _secilenVakitler.contains(vakit) ? Colors.white : color),
                    label: Text(vakit, style: TextStyle(color: _secilenVakitler.contains(vakit) ? Colors.white : Colors.black)),
                    selected: _secilenVakitler.contains(vakit),
                    selectedColor: color,
                    checkmarkColor: Colors.white,
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
              const SizedBox(height: 20),

              // YENİ: Gün Seçimi
              const Text("Hangi Günlerde İçilecek?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // Her Gün Checkbox
              CheckboxListTile(
                title: const Text("Her Gün", style: TextStyle(fontWeight: FontWeight.bold)),
                value: _herGun,
                activeColor: Colors.teal,
                onChanged: (bool? value) {
                  setState(() {
                    _herGun = value ?? true;
                    if (_herGun) _secilenGunler.clear();
                  });
                },
              ),

              // Eğer "Her Gün" seçili değilse gün seçeneklerini göster
              if (!_herGun) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _gunSecenekleri.map((gun) {
                    bool secili = _secilenGunler.contains(gun["ad"]);
                    return ChoiceChip(
                      avatar: Icon(gun["icon"], size: 18, color: secili ? Colors.white : Colors.teal),
                      label: Text(gun["kisa"], style: TextStyle(color: secili ? Colors.white : Colors.black)),
                      selected: secili,
                      selectedColor: Colors.teal,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _secilenGunler.add(gun["ad"]);
                          } else {
                            _secilenGunler.remove(gun["ad"]);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 20),

              // Stok
              TextFormField(
                controller: _stokController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: "Stok Adedi",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory, color: Colors.teal),
                ),
              ),
              const SizedBox(height: 15),

              // Kullanım Şekli
              DropdownButtonFormField<String>(
                value: _acTokDurumu,
                decoration: const InputDecoration(
                  labelText: "Kullanım Şekli",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.restaurant, color: Colors.teal),
                ),
                items: _acTokListesi.map((durum) => DropdownMenuItem(value: durum, child: Text(durum))).toList(),
                onChanged: (deger) => setState(() => _acTokDurumu = deger),
              ),
              const SizedBox(height: 15),

              // Notlar
              TextFormField(
                controller: _notController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Notlar (Opsiyonel)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note_add, color: Colors.teal),
                ),
              ),
              const SizedBox(height: 25),

              // Kaydet Butonu
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _kaydetVeyaGuncelle,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text("Kaydet", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}