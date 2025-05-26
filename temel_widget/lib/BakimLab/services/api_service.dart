import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {

  String kullaniciId;
  // Node.js API için
  static const String nodeApiUrl = "http://10.35.218.86:3000";
  // FastAPI için
  static const String fastApiUrl = "http://10.35.218.86:8000";

  static const Duration timeoutDuration = Duration(seconds: 30);

  ApiService({this.kullaniciId = 'varsayilan'});

  // Kullanıcı ID'sini güncelleme metodu
  void updateKullaniciId(String yeniId) {
    kullaniciId = yeniId;
  }

// Geçmişe ekleme metodu
  Future<void> gecmiseEkle(String urunIsmi, double temizlikYuzdesi) async {
    try {
      print('Geçmişe ekleniyor - Kullanıcı: $kullaniciId, Ürün: $urunIsmi');

      final response = await http.post(
        Uri.parse('$fastApiUrl/gecmis/ekle'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'kullanici_id': kullaniciId,
          'urun_ismi': urunIsmi,
          'temizlik_yuzdesi': temizlikYuzdesi,
        }),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        print('Ürün geçmişe eklendi: $urunIsmi');
        print('API Yanıtı: ${response.body}');
      } else {
        print('Geçmişe eklenirken hata: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Geçmişe eklenirken hata: $e');
    }
  }

  Future<Map<String, dynamic>> fetchOneriler(String kullaniciId) async {
    try {
      print('Öneriler getiriliyor: $kullaniciId');

      final response = await http.get(
        Uri.parse('$fastApiUrl/oneri/$kullaniciId'),
      ).timeout(Duration(seconds: 15));

      print('Öneri yanıt durumu: ${response.statusCode}');
      print('Öneri yanıt içeriği: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Null kontrolü ekleyelim
        return data ?? {"kullanici_id": kullaniciId, "oneriler": []};
      } else {
        return {"kullanici_id": kullaniciId, "oneriler": []};
      }
    } catch (e) {
      print('Öneri hatası: $e');
      return {"kullanici_id": kullaniciId, "oneriler": []};
    }
  }

  Future<List<dynamic>> fetchUrunler() async {
    try {
      print("FastAPI çağrısı yapılıyor: $fastApiUrl/hesaplanabilir-urunler");

      final response = await http.get(
        Uri.parse('$fastApiUrl/hesaplanabilir-urunler'),
      ).timeout(timeoutDuration);

      print("API yanıt durumu: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print("Alınan veri: $data");
        return data;
      } else {
        print("API Hata: ${response.statusCode} - ${response.body}");
        throw Exception('Ürünler yüklenemedi! Hata kodu: ${response.statusCode}');
      }
    } catch (e) {
      print("Bağlantı Hatası detayı: $e");
      throw Exception('Bağlantı hatası: $e');
    }
  }

  Future<Map<String, dynamic>> fetchUrunDetay(String barkod) async {
    try {
      print('Barkod ile ürün detayı isteniyor: $barkod');

      final nodeResponse = await http.get(
        Uri.parse('$nodeApiUrl/urunler/$barkod'),
      ).timeout(Duration(seconds: 5)); // timeout süresini azalttık

      if (nodeResponse.statusCode == 200) {
        final nodeData = json.decode(nodeResponse.body) as Map<String, dynamic>;
        final urunIsmi = nodeData['urun_ismi'];

        final fastApiResponse = await http.get(
          Uri.parse('$fastApiUrl/urun_detayi/$urunIsmi'),
        ).timeout(Duration(seconds: 5)); // timeout süresini azalttık

        if (fastApiResponse.statusCode == 200) {
          final fastApiData = json.decode(fastApiResponse.body) as Map<String, dynamic>;

          // Geçmişe ekle
          await gecmiseEkle(
            urunIsmi,
            fastApiData['temizlik_yuzdesi'].toDouble(),
          ).timeout(Duration(seconds: 5)); // timeout süresini azalttık

          return {
            ...nodeData,
            ...fastApiData,
          };
        }
      }
      throw Exception('Ürün detayları alınamadı');
    } catch (e) {
      print('API Hatası: $e');
      rethrow;
    }
  }
}