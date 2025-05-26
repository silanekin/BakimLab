import 'package:flutter/material.dart';
import 'dart:convert';
import 'urun_analiz.dart';
import 'package:http/http.dart' as http;
import 'gecmis.dart';

class UrunDetaySayfasi extends StatelessWidget {
  final String urun_ismi;
  final String urun_barkodu;
  final String? urun_icerigi; // Eklendi
  final String? foto;

  const UrunDetaySayfasi({
    Key? key,
    required this.urun_ismi,
    required this.urun_barkodu,
    this.urun_icerigi, // Eklendi
    this.foto,
  }) : super(key: key);

  void _gecmiseEkle(BuildContext context, String urunIsmi, double temizlikYuzdesi) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.35.218.86:8000/gecmis/ekle'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'kullanici_id': 'KULLANICI_ID', // Kullanıcı ID'sini buraya ekleyin
          'urun_ismi': urunIsmi,
          'temizlik_yuzdesi': temizlikYuzdesi,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ürün geçmişe eklendi')),
        );
      }
    } catch (e) {
      print('Hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(urun_ismi),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ürün Fotoğrafı
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[200],
              ),
              child: foto != null
                  ? Image.memory(
                Base64Decoder().convert(foto!),
                fit: BoxFit.contain,
              )
                  : Icon(Icons.image_not_supported,
                  size: 100, color: Colors.grey),
            ),

            // Ürün Bilgileri
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    urun_ismi,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Barkod: $urun_barkodu',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (urun_icerigi != null && urun_icerigi!.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(
                      'İçindekiler:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      urun_icerigi!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                  SizedBox(height: 24),

                  // Analiz Butonu
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UrunAnalizSayfasi(
                              urunBarkodu: urun_barkodu,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade500,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Ürün Analizine Git',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}