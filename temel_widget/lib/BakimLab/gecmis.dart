import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class GecmisSayfasi extends StatefulWidget {
  @override
  _GecmisSayfasiState createState() => _GecmisSayfasiState();
}

class _GecmisSayfasiState extends State<GecmisSayfasi> {
  Future<List<Map<String, dynamic>>> getGecmis() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'misafir';

      print('Geçmiş getiriliyor için kullanıcı ID: $userId');

      final response = await http.get(
        Uri.parse('http://10.35.218.86:8000/gecmis/$userId'),
      ).timeout(Duration(seconds: 15));

      print('API yanıtı: ${response.statusCode}');
      print('API yanıt içeriği: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Geçmiş yüklenemedi');
      }
    } catch (e) {
      print('Hata: $e');
      throw e;
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
        title: Text('Geçmiş'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getGecmis(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Bir hata oluştu',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Sayfayı yenile
                    },
                    child: Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          final gecmis = snapshot.data ?? [];

          if (gecmis.isEmpty) {
            return Center(
              child: Text(
                'Henüz geçmiş kaydınız bulunmuyor',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: gecmis.length,
            itemBuilder: (context, index) {
              final kayit = gecmis[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    kayit['urun_ismi'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Temizlik: %${kayit['temizlik_yuzdesi'].toStringAsFixed(1)}\n'
                        'Tarih: ${kayit['tarih']}',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: CircularPercentIndicator(
                    radius: 25.0,
                    lineWidth: 4.0,
                    percent: (kayit['temizlik_yuzdesi'] / 100).clamp(0.0, 1.0),
                    center: Text(
                      '${kayit['temizlik_yuzdesi'].toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 10),
                    ),
                    progressColor: _getTemizlikRengi(kayit['temizlik_yuzdesi'].toDouble()),
                    backgroundColor: Colors.grey.shade300,
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}