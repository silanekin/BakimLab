import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'barkod_sayfasi.dart';
import 'product_card.dart';
import 'services/api_service.dart';

class AnaSayfaContent extends StatefulWidget {
  @override
  _AnaSayfaContentState createState() => _AnaSayfaContentState();
}

class _AnaSayfaContentState extends State<AnaSayfaContent> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _urunler;
  late Future<Map<String, dynamic>> _oneriler;

  @override
  @override
  void initState() {
    super.initState();
    _urunler = _apiService.fetchUrunler();
    // Varsayılan boş bir Future atayalım
    _oneriler = Future.value({"oneriler": []});

    // Kullanıcı varsa önerileri getirelim
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _oneriler = _apiService.fetchOneriler(user.uid);
      });
    }
  }

  Future<void> _yenileUrunler() async {
    setState(() {
      _urunler = _apiService.fetchUrunler();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _oneriler = _apiService.fetchOneriler(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _yenileUrunler,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Öneriler Bölümü
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Sizin İçin Öneriler",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _oneriler,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Öneriler yüklenirken bir hata oluştu',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData ||
                          !snapshot.data!.containsKey('oneriler') ||
                          (snapshot.data!['oneriler'] as List).isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Henüz öneri bulunmuyor. Daha fazla ürün inceledikçe öneriler burada görünecek.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      final oneriler = snapshot.data!['oneriler'] as List;

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: oneriler.length,
                        itemBuilder: (context, index) {
                          final oneri = oneriler[index];
                          return Container(
                            width: 300,
                            margin: EdgeInsets.only(right: 16),
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'İncelediğiniz Ürün:',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      oneri['kaynak_urun'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Divider(),
                                    Text(
                                      'Benzer Ürünler:',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: oneri['benzer_urunler'].length,
                                        itemBuilder: (context, idx) {
                                          final benzerUrun = oneri['benzer_urunler'][idx];
                                          return Card(
                                            color: Colors.grey[50],
                                            child: ListTile(
                                              dense: true,
                                              title: Text(
                                                benzerUrun['urun_ismi'],
                                                style: TextStyle(fontSize: 14),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              subtitle: Row(
                                                children: [
                                                  Icon(
                                                    Icons.cleaning_services,
                                                    size: 14,
                                                    color: _getTemizlikRengi(
                                                        benzerUrun['temizlik_yuzdesi']
                                                    ),
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    '%${benzerUrun['temizlik_yuzdesi'].toStringAsFixed(0)} temiz',
                                                    style: TextStyle(fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                              trailing: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green[50],
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '%${(benzerUrun['benzerlik_skoru'] * 100).toStringAsFixed(0)} benzer',
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // Önceden Arattıklarım Bölümü
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Tamamını gör sayfasına yönlendirme
                        },
                        child: Row(
                          children: [
                            Text(
                              "Ürünlerin Tamamını Gör",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                            Icon(Icons.arrow_forward, color: Colors.green),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Ürün Listesi
                FutureBuilder<List<dynamic>>(
                  future: _urunler,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Hata: ${snapshot.error}'),
                            ElevatedButton(
                              onPressed: _yenileUrunler,
                              child: Text('Tekrar Dene'),
                            ),
                          ],
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text("Hiç ürün bulunamadı."));
                    } else {
                      final urunler = snapshot.data!;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: urunler.length,
                        itemBuilder: (context, index) {
                          final urun = urunler[index];
                          return ProductCard(
                            urun_ismi: urun['urun_ismi'] ?? 'Bilinmeyen Ürün',
                            urun_barkodu: urun['urun_barkodu'] ?? 'Geçersiz Barkod',
                            foto: urun['foto'],
                          );
                        },
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTemizlikRengi(double yuzde) {
    if (yuzde >= 80) return Colors.green;
    if (yuzde >= 60) return Colors.lightGreen;
    if (yuzde >= 40) return Colors.orange;
    if (yuzde >= 20) return Colors.deepOrange;
    return Colors.red;
  }
}