import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:percent_indicator/circular_percent_indicator.dart';

class ComparisonPage extends StatefulWidget {
  final String urunIsmi1;
  final String urunIsmi2;

  ComparisonPage({
    required this.urunIsmi1,
    required this.urunIsmi2,
  });

  @override
  _ComparisonPageState createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<ComparisonPage> {
  Future<Map<String, dynamic>> getProductDetails(String urunIsmi) async {
    try {
      // Türkçe karakterleri düzelt
      String normalizedUrunIsmi = urunIsmi
          .replaceAll('ı', 'i')
          .replaceAll('ğ', 'g')
          .replaceAll('ü', 'u')
          .replaceAll('ş', 's')
          .replaceAll('ö', 'o')
          .replaceAll('ç', 'c')
          .replaceAll('İ', 'I')
          .replaceAll('Ğ', 'G')
          .replaceAll('Ü', 'U')
          .replaceAll('Ş', 'S')
          .replaceAll('Ö', 'O')
          .replaceAll('Ç', 'C');

      final encodedUrunIsmi = Uri.encodeComponent(normalizedUrunIsmi);
      final url = 'http://10.35.218.86:8000/urun_detayi/$encodedUrunIsmi';

      print('API çağrısı yapılıyor: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Connection': 'keep-alive',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ).timeout(Duration(seconds: 30));

      print('API yanıt kodu: ${response.statusCode}');
      print('API yanıt içeriği: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Çözümlenen veri: $data');
        return data;
      }

      if (response.statusCode == 404 || response.statusCode == 500) {
        return {
          'urun_ismi': urunIsmi,
          'temizlik_yuzdesi': 0.0,
          'risk_skoru': 0.0,
          'temiz_icerikler': [],
          'kirli_icerikler': [],
        };
      }

      throw Exception('API Hatası: ${response.statusCode}');
    } catch (e) {
      print('Hata: $e');
      return {
        'urun_ismi': urunIsmi,
        'temizlik_yuzdesi': 0.0,
        'risk_skoru': 0.0,
        'temiz_icerikler': [],
        'kirli_icerikler': [],
      };
    }
  }

  Color _getTemizlikRengi(double yuzde) {
    if (yuzde >= 80) return Colors.green.shade500;
    if (yuzde >= 60) return Colors.lightGreen.shade500;
    if (yuzde >= 40) return Colors.orange.shade500;
    if (yuzde >= 20) return Colors.deepOrange.shade500;
    return Colors.red.shade500;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Karşılaştırma'),
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder(
        future: Future.wait([
          getProductDetails(widget.urunIsmi1),
          getProductDetails(widget.urunIsmi2),
        ]),
        builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('FutureBuilder hatası: ${snapshot.error}');
            return Center(
              child: Text('Hata oluştu: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('Ürün bilgileri alınamadı'),
            );
          }

          final product1 = snapshot.data![0];
          final product2 = snapshot.data![1];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildProductColumn(product1)),
                  Container(
                    width: 1,
                    color: Colors.grey.shade300,
                    margin: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  Expanded(child: _buildProductColumn(product2)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductColumn(Map<String, dynamic> product) {
    return Column(
      children: [
        // Ürün İsmi
        Text(
          product['urun_ismi'] ?? 'Bilinmeyen Ürün',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),

        SizedBox(height: 24),

        // Temizlik Yüzdesi Çemberi ve Ürün Resmi
        Stack(
          alignment: Alignment.center,
          children: [
            CircularPercentIndicator(
              radius: 80.0,
              lineWidth: 12.0,
              animation: true,
              percent: (product['temizlik_yuzdesi'] ?? 0.0) / 100,
              progressColor: _getTemizlikRengi(product['temizlik_yuzdesi'] ?? 0.0),
              backgroundColor: Colors.grey.shade200,
              circularStrokeCap: CircularStrokeCap.round,
              center: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: product['foto'] != null
                      ? Image.memory(
                    Base64Decoder().convert(product['foto']),
                    fit: BoxFit.cover,
                  )
                      : Icon(Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 16),

        // Temizlik Yüzdesi
        Text(
          "%${(product['temizlik_yuzdesi'] ?? 0.0).toStringAsFixed(1)}",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _getTemizlikRengi(product['temizlik_yuzdesi'] ?? 0.0),
          ),
        ),

        Text(
          "Temizlik Oranı",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),

        SizedBox(height: 16),

        // Risk Skoru
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: (product['risk_skoru'] ?? 0.0) <= 3
                ? Colors.green.shade100
                : Colors.red.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "Risk: ${(product['risk_skoru'] ?? 0.0).toStringAsFixed(1)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: (product['risk_skoru'] ?? 0.0) <= 3
                  ? Colors.green.shade700
                  : Colors.red.shade700,
            ),
          ),
        ),

        SizedBox(height: 24),

        // İçerikler
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildIngredientsList('Temiz İçerikler', product['temiz_icerikler'] ?? [], Colors.green.shade600),
              Divider(height: 1, color: Colors.grey.shade300),
              _buildIngredientsList('Riskli İçerikler', product['kirli_icerikler'] ?? [], Colors.red.shade600),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsList(String title, List<dynamic> ingredients,
      Color color) {
    return ExpansionTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      children: [
        if (ingredients.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'İçerik bulunamadı',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: ingredients.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Icon(Icons.circle, color: color, size: 8),
                title: Text(
                  ingredients[index],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
                dense: true,
                visualDensity: VisualDensity.compact,
              );
            },
          ),
      ],
      iconColor: color,
      collapsedIconColor: color,
      childrenPadding: EdgeInsets.symmetric(horizontal: 8),
    );
  }
}