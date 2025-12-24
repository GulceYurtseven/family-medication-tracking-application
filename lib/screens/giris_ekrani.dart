import 'package:flutter/material.dart';
import '../services/aile_yoneticisi.dart';
import 'ana_sayfa.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  final _aileKoduController = TextEditingController();
  final _aileAdiController = TextEditingController();
  bool _yukleniyor = false;
  bool _yeniAileModu = false;

  void _girisYap() async {
    if (_aileKoduController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen aile kodunu girin')),
      );
      return;
    }

    setState(() => _yukleniyor = true);

    bool basarili = await AileYoneticisi().aileKoduIleGiris(_aileKoduController.text.toUpperCase());

    setState(() => _yukleniyor = false);

    if (basarili) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AnaSayfa()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aile kodu bulunamadı. Lütfen kontrol edin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _yeniAileOlustur() async {
    if (_aileAdiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen aile adını girin')),
      );
      return;
    }

    setState(() => _yukleniyor = true);

    String? aileKodu = await AileYoneticisi().yeniAileOlustur(_aileAdiController.text);

    setState(() => _yukleniyor = false);

    if (aileKodu != null) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Aile Oluşturuldu! 🎉'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Aile kodunuz:'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.teal, width: 2),
                  ),
                  child: Text(
                    aileKodu,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Bu kodu aile üyelerinizle paylaşın. Onlar da bu kodla giriş yapabilir.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AnaSayfa()),
                  );
                },
                child: const Text('Devam Et', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aile oluşturulurken bir hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade400, Colors.teal.shade700],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/İkon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.family_restroom,
                      size: 80,
                      color: Colors.teal.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Aile İlaç Takip',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ailenizle birlikte ilaç takibi',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 50),

                  // Giriş/Kayıt Kartı
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Mod değiştirme butonları
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: !_yeniAileModu ? Colors.teal : Colors.grey.shade300,
                                  foregroundColor: !_yeniAileModu ? Colors.white : Colors.black87,
                                  elevation: !_yeniAileModu ? 4 : 0,
                                ),
                                onPressed: () => setState(() => _yeniAileModu = false),
                                child: const Text('Giriş Yap'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _yeniAileModu ? Colors.teal : Colors.grey.shade300,
                                  foregroundColor: _yeniAileModu ? Colors.white : Colors.black87,
                                  elevation: _yeniAileModu ? 4 : 0,
                                ),
                                onPressed: () => setState(() => _yeniAileModu = true),
                                child: const Text('Yeni Aile'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Giriş Modu
                        if (!_yeniAileModu) ...[
                          TextField(
                            controller: _aileKoduController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: 'Aile Kodu',
                              hintText: 'ÖRNEK: AYDIN2024',
                              prefixIcon: const Icon(Icons.vpn_key),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _yukleniyor ? null : _girisYap,
                              child: _yukleniyor
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                'Giriş Yap',
                                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],

                        // Yeni Aile Modu
                        if (_yeniAileModu) ...[
                          TextField(
                            controller: _aileAdiController,
                            decoration: InputDecoration(
                              labelText: 'Aile Adı',
                              hintText: 'Örnek: Aydın Ailesi',
                              prefixIcon: const Icon(Icons.family_restroom),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.amber.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.amber.shade800),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Otomatik aile kodu oluşturulacak',
                                    style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _yukleniyor ? null : _yeniAileOlustur,
                              child: _yukleniyor
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                'Aile Oluştur',
                                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}