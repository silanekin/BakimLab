import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'product_card.dart';

class AramaSayfasi extends StatefulWidget {
  @override
  _AramaSayfasiState createState() => _AramaSayfasiState();
}

class _AramaSayfasiState extends State<AramaSayfasi> {
  final ApiService _apiService = ApiService(); // ApiService örneği
  Future<List<dynamic>>? _urunlerFuture;
  List<dynamic> _urunler = [];
  List<dynamic> _filteredUrunler = [];

  @override
  void initState() {
    super.initState();
    _urunlerFuture = _apiService.fetchUrunler(); // ApiService üzerinden çağrı
    _urunlerFuture!.then((urunler) {
      setState(() {
        _urunler = urunler;
        _filteredUrunler = urunler.take(10).toList();
      });
    });
  }

  // Diğer metodlar ve widget yapısı aynı kalacak
  void _filterUrunler(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUrunler = _urunler.take(10).toList();
      } else {
        final filtered = _urunler
            .where((urun) =>
            urun['urun_ismi'].toLowerCase().contains(query.toLowerCase()))
            .toList();
        _filteredUrunler = filtered.take(10).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            IconButton(
              icon: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            SizedBox(width: 8),
            Text(
              "Ürün Arama Sayfası",
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: "Ürün ara",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                  prefixIcon: Icon(Icons.search, color: Colors.grey, size: 24),
                  contentPadding:
                  EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.green, width: 2),
                  ),
                ),
                style: TextStyle(color: Colors.black, fontSize: 16),
                onChanged: _filterUrunler,
              ),
              SizedBox(height: 20),
              Text(
                "Sonuçlar",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              FutureBuilder<List<dynamic>>(
                future: _urunlerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Ürünler yüklenirken bir hata oluştu!",
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        "Hiç ürün bulunamadı.",
                        style: TextStyle(color: Colors.black),
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: _filteredUrunler.length,
                    itemBuilder: (context, index) {
                      final urun = _filteredUrunler[index];
                      return ProductCard(
                        urun_ismi: urun['urun_ismi'] ?? 'Bilinmeyen Ürün',
                        urun_barkodu: urun['urun_barkodu'] ?? 'Geçersiz Barkod',
                        foto: urun['foto'],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}