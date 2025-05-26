import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class UrunAnalizSayfasi extends StatefulWidget {
  final String urunBarkodu;

  UrunAnalizSayfasi({required this.urunBarkodu});

  @override
  _UrunAnalizSayfasiState createState() => _UrunAnalizSayfasiState();
}
class _UrunAnalizSayfasiState extends State<UrunAnalizSayfasi> {
  late ApiService _apiService;
  Map<String, dynamic>? urunBilgisi;
  bool isLoading = true;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    String userId = user?.uid ?? 'misafir';
    _apiService = ApiService(kullaniciId: userId);
    print('Kullanıcı ID: $userId');
    getProductDetails();
  }

  Future<void> getProductDetails() async {
    if (!mounted) return;

    try {
      print('Ürün detayları alınıyor: ${widget.urunBarkodu}');

      // Node.js API çağrısı (IP adresini kontrol edin)
      final nodeUrl = 'http://10.35.218.86:3000/urunler/${widget.urunBarkodu}';
      print('Node.js API çağrısı yapılıyor: $nodeUrl');

      final nodeResponse = await http.get(
        Uri.parse(nodeUrl),
      ).timeout(Duration(seconds: 20)); // Süreyi artırdık

      print('Node.js yanıt durumu: ${nodeResponse.statusCode}');
      print('Node.js yanıt içeriği: ${nodeResponse.body}');

      if (nodeResponse.statusCode == 200) {
        final nodeData = json.decode(nodeResponse.body) as Map<String, dynamic>;
        final urunIsmi = nodeData['urun_ismi'];

        // FastAPI çağrısı (IP adresini kontrol edin)
        final fastApiUrl = 'http://10.35.218.86:8000/urun_detayi/$urunIsmi';
        print('FastAPI isteği yapılıyor: $fastApiUrl');

        final fastApiResponse = await http.get(
          Uri.parse(fastApiUrl),
        ).timeout(Duration(seconds: 20)); // Süreyi artırdık

        print('FastAPI yanıt durumu: ${fastApiResponse.statusCode}');
        print('FastAPI yanıt içeriği: ${fastApiResponse.body}');

        if (fastApiResponse.statusCode == 200) {
          final fastApiData = json.decode(fastApiResponse.body) as Map<String, dynamic>;

          // Verileri birleştir
          final tumVeriler = {
            ...nodeData,
            ...fastApiData,
          };

          if (!mounted) return;

          setState(() {
            urunBilgisi = tumVeriler;
            isLoading = false;
          });

          // Geçmişe ekle
          await _apiService.gecmiseEkle(
            urunIsmi,
            fastApiData['temizlik_yuzdesi'].toDouble(),
          );
        } else {
          throw Exception('FastAPI yanıt kodu: ${fastApiResponse.statusCode}');
        }
      } else {
        throw Exception('Node.js yanıt kodu: ${nodeResponse.statusCode}');
      }
    } catch (e) {
      print('Hata: $e');

      if (!mounted) return;

      setState(() {
        urunBilgisi = null;
        isLoading = false;
      });

      String errorMessage;
      if (e is TimeoutException) {
        errorMessage = 'Sunucu yanıt vermiyor. Lütfen internet bağlantınızı kontrol edin.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Sunucuya bağlanılamadı. Lütfen sunucunun çalıştığından emin olun.';
      } else {
        errorMessage = 'Bir hata oluştu: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Tekrar Dene',
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              getProductDetails();
            },
          ),
        ),
      );
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
    if (!_mounted) return Container();

    return Scaffold(
      appBar: AppBar(
        title: Text("Ürün Analizi"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : urunBilgisi == null
          ? Center(child: Text("Ürün bulunamadı!"))
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                urunBilgisi!["urun_ismi"] ?? "İsimsiz Ürün",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              CircularPercentIndicator(
                radius: 120.0,
                lineWidth: 15.0,
                percent: ((urunBilgisi!["temizlik_yuzdesi"] ?? 0) / 100).clamp(0.0, 1.0),
                center: Text(
                  "%${(urunBilgisi!["temizlik_yuzdesi"] ?? 0).toStringAsFixed(1)}",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                progressColor: _getTemizlikRengi(urunBilgisi!["temizlik_yuzdesi"] ?? 0),
                backgroundColor: Colors.grey.shade200,
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
              ),
              SizedBox(height: 16),
              Text(
                "Barkod: ${urunBilgisi!["urun_barkodu"] ?? "Bilinmiyor"}",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),
              if (urunBilgisi!["temiz_icerikler"] != null ||
                  urunBilgisi!["kirli_icerikler"] != null)
                _buildIcerikler(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcerikler() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "İçerik Analizi",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        _buildIcerikKategorisi(
          "Temiz İçerikler",
          urunBilgisi!["temiz_icerikler"] ?? [],
          Colors.green.shade500,
          Icons.check_circle,
        ),
        SizedBox(height: 12),
        _buildIcerikKategorisi(
          "Riskli İçerikler",
          urunBilgisi!["kirli_icerikler"] ?? [],
          Colors.red.shade500,
          Icons.warning,
        ),
      ],
    );
  }

  Widget _buildIcerikKategorisi(
      String baslik,
      List<dynamic> icerikler,
      Color renk,
      IconData icon,
      ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          baslik,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: renk,
          ),
        ),
        leading: Icon(icon, color: renk),
        children: [
          if (icerikler.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "İçerik bulunamadı",
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
              itemCount: icerikler.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(Icons.label, color: renk),
                  title: Text(
                    icerikler[index],
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}