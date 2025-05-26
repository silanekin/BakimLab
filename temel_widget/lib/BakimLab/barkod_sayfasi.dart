import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert'; // JSON işlemleri için
import 'package:http/http.dart' as http;
import 'urun_detay_sayfasi.dart'; // Ürün Detay Sayfası

class BarkodSayfasi extends StatelessWidget {

  // Barkoda göre tek bir ürün detayını çeker
  Future<Map<String, dynamic>> fetchUrunDetay(String barkod) async {
    final String apiUrl = "http://10.35.218.86:3000/urunler/$barkod"; // Node.js API

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return {
          "urun_ismi": data["urun_ismi"] ?? "Bilinmeyen Ürün",
          "urun_icerigi": data["urun_icerigi"] ?? "İçerik bilgisi yok",
          "urun_barkodu": data["urun_barkodu"] ?? "Bilinmeyen Barkod",
          "foto": data["foto"], // Base64 formatında gelen fotoğraf
        };
      } else if (response.statusCode == 404) {
        throw Exception('Ürün bulunamadı!');
      } else {
        throw Exception('Bağlantı hatası: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(
          'Barkod Tarayıcı',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: MobileScanner(
        onDetect: (BarcodeCapture barcode) async {
          final List<Barcode> barcodes = barcode.barcodes;
          for (final Barcode code in barcodes) {
            if (code.rawValue != null) {
              final String barkod = code.rawValue!; // Barkod değeri

              try {
                // API'den ürün detaylarını çek
                final urunDetay = await fetchUrunDetay(barkod);

                // Ürün bilgileriyle detay sayfasına yönlendir
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UrunDetaySayfasi(
                      urun_ismi: urunDetay['urun_ismi'] ?? 'Bilinmeyen Ürün',
                      urun_barkodu: urunDetay['urun_barkodu'] ?? 'Barkod bulunamadı',
                      foto: urunDetay['foto'],
                      // urun_icerigi parametresi kaldırıldı
                    ),
                  ),
                );
                break; // İlk barkodu işledikten sonra döngüyü kır
              } catch (e) {
                // Hata durumunda kullanıcıya bildirim göster
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }
}
