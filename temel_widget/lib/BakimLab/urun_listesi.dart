import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'product_card.dart';
import 'urun_detay_sayfasi.dart';

class UrunListesi extends StatefulWidget {
  @override
  _UrunListesiState createState() => _UrunListesiState();
}

class _UrunListesiState extends State<UrunListesi> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _urunler;

  @override
  void initState() {
    super.initState();
    _urunler = _apiService.fetchUrunler();
  }

  Future<void> _yenileListeyi() async {
    setState(() {
      _urunler = _apiService.fetchUrunler();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Ürün Listesi",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple, // Renk değiştirildi
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _yenileListeyi,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _yenileListeyi,
        child: FutureBuilder<List<dynamic>>(
          future: _urunler,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Bir hata oluştu',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _yenileListeyi,
                      icon: Icon(Icons.refresh),
                      label: Text('Tekrar Dene'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      "Henüz ürün bulunmuyor",
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            final urunler = snapshot.data!;

            return GridView.builder(
              padding: const EdgeInsets.all(12.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 0.75,
              ),
              itemCount: urunler.length,
              itemBuilder: (context, index) {
                final urun = urunler[index];
                return ProductCard(
                  urun_ismi: urun['urun_ismi'] ?? 'Bilinmeyen Ürün',
                  urun_barkodu: urun['urun_barkodu'] ?? 'Bilinmeyen Barkod',
                  foto: urun['foto'],
                );
              },
            );
          },
        ),
      ),
    );
  }
}