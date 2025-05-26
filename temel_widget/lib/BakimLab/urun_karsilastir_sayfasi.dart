import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'services/api_service.dart';
import 'karsilastirma_sayfasi.dart';

class UrunKarsilastirSayfasi extends StatefulWidget {
  @override
  _UrunKarsilastirSayfasiState createState() => _UrunKarsilastirSayfasiState();
}

class _UrunKarsilastirSayfasiState extends State<UrunKarsilastirSayfasi> {
  final ApiService _apiService = ApiService();
  final TextEditingController _controller1 = TextEditingController();
  final TextEditingController _controller2 = TextEditingController();

  String? barkod1;
  String? barkod2;
  Future<List<dynamic>>? _urunlerFuture;
  List<dynamic> _urunler = [];
  List<dynamic> _filteredUrunler1 = [];
  List<dynamic> _filteredUrunler2 = [];

  @override
  void initState() {
    super.initState();
    _urunlerFuture = _apiService.fetchUrunler();
    _urunlerFuture!.then((urunler) {
      setState(() {
        _urunler = urunler;
        _filteredUrunler1 = [];
        _filteredUrunler2 = [];
      });
    }).catchError((error) {
      print("Ürünler yüklenirken bir hata oluştu: $error");
    });
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  void _filterUrunler1(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUrunler1 = [];
      } else {
        _filteredUrunler1 = _urunler
            .where((urun) => urun['urun_ismi']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _filterUrunler2(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUrunler2 = [];
      } else {
        _filteredUrunler2 = _urunler
            .where((urun) => urun['urun_ismi']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _selectUrun1(dynamic urun) {
    setState(() {
      barkod1 = urun['urun_barkodu'];
      _controller1.clear();
      _filteredUrunler1 = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${urun['urun_ismi']} seçildi!")),
    );
  }

  void _selectUrun2(dynamic urun) {
    setState(() {
      barkod2 = urun['urun_barkodu'];
      _controller2.clear();
      _filteredUrunler2 = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${urun['urun_ismi']} seçildi!")),
    );
  }

  Future<void> _scanBarcode1() async {
    try {
      var result = await BarcodeScanner.scan();
      setState(() {
        barkod1 = result.rawContent;
        final urun = _urunler.firstWhere(
              (urun) => urun['urun_barkodu'] == barkod1,
          orElse: () => null,
        );
        if (urun != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${urun['urun_ismi']} seçildi!")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Barkodla eşleşen ürün bulunamadı!")),
          );
        }
      });
    } catch (e) {
      print("Hata: $e");
    }
  }

  Future<void> _scanBarcode2() async {
    try {
      var result = await BarcodeScanner.scan();
      setState(() {
        barkod2 = result.rawContent;
        final urun = _urunler.firstWhere(
              (urun) => urun['urun_barkodu'] == barkod2,
          orElse: () => null,
        );
        if (urun != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${urun['urun_ismi']} seçildi!")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Barkodla eşleşen ürün bulunamadı!")),
          );
        }
      });
    } catch (e) {
      print("Hata: $e");
    }
  }

  void _karsilastir() {
    if (barkod1 == null || barkod2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Her iki ürünü de seçin!")),
      );
    } else {
      // Seçilen ürünlerin isimlerini bul
      final urun1 = _urunler.firstWhere(
            (urun) => urun['urun_barkodu'] == barkod1,
        orElse: () => null,
      );
      final urun2 = _urunler.firstWhere(
            (urun) => urun['urun_barkodu'] == barkod2,
        orElse: () => null,
      );

      if (urun1 != null && urun2 != null) {
        print('Karşılaştırılacak ürünler: ${urun1['urun_ismi']} ve ${urun2['urun_ismi']}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ComparisonPage(
              urunIsmi1: urun1['urun_ismi'],
              urunIsmi2: urun2['urun_ismi'],
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Ürün Karşılaştır",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
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

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 1. Ürün Arama
                  TextField(
                    controller: _controller1,
                    decoration: InputDecoration(
                      hintText: "Karşılaştırmak istediğiniz 1. ürünün ismini giriniz",
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                    onChanged: _filterUrunler1,
                  ),
                  if (_filteredUrunler1.isNotEmpty)
                    Container(
                      constraints: BoxConstraints(maxHeight: 200),
                      child: Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filteredUrunler1.length,
                          itemBuilder: (context, index) {
                            final urun = _filteredUrunler1[index];
                            return ListTile(
                              title: Text(urun['urun_ismi']),
                              onTap: () => _selectUrun1(urun),
                            );
                          },
                        ),
                      ),
                    ),

                  SizedBox(height: 10),
                  Text("ya da barkodla taratın",
                      style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 10),

                  GestureDetector(
                    onTap: _scanBarcode1,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.green.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 40),
                    ),
                  ),

                  Divider(height: 40),

                  // 2. Ürün Arama
                  TextField(
                    controller: _controller2,
                    decoration: InputDecoration(
                      hintText: "Karşılaştırmak istediğiniz 2. ürünün ismini giriniz",
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                    onChanged: _filterUrunler2,
                  ),
                  if (_filteredUrunler2.isNotEmpty)
                    Container(
                      constraints: BoxConstraints(maxHeight: 200),
                      child: Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filteredUrunler2.length,
                          itemBuilder: (context, index) {
                            final urun = _filteredUrunler2[index];
                            return ListTile(
                              title: Text(urun['urun_ismi']),
                              onTap: () => _selectUrun2(urun),
                            );
                          },
                        ),
                      ),
                    ),

                  SizedBox(height: 10),
                  Text("ya da barkodla taratın",
                      style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 10),

                  GestureDetector(
                    onTap: _scanBarcode2,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.green.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 40),
                    ),
                  ),

                  SizedBox(height: 30),

                  // Karşılaştır Butonu
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _karsilastir,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade500,
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        "Ürünleri Karşılaştır",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}