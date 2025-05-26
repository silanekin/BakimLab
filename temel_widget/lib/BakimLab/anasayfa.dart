import 'package:flutter/material.dart';
import 'package:temel_widget/BakimLab/gecmis.dart';
import 'package:temel_widget/BakimLab/urun_karsilastir_sayfasi.dart';
import 'barkod_sayfasi.dart';
import 'arama_sayfasi.dart';
import 'anasayfa_content.dart';
import 'profil_sayfasi.dart';

class AnaSayfa extends StatefulWidget {
  @override
  _AnaSayfaState createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  int _currentIndex = 0;
  final String kullaniciId = 'test_kullanici'; // Test için sabit bir kullanıcı ID'si

  // Alt menüdeki sayfalar
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      AnaSayfaContent(),
      AramaSayfasi(),
      BarkodSayfasi(),
      UrunKarsilastirSayfasi(),
      GecmisSayfasi(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
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
            Image.asset(
              'lib/BakimLab/bakimLabLogo.png',
              fit: BoxFit.contain,
              height: 60,
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilSayfasi()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 25,
                backgroundImage: AssetImage('lib/BakimLab/default_image.jpg'),
              ),
            ),
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 5 öğe olduğu için fixed type kullanıyoruz
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Ara',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Barkod',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.compare),
            label: 'Karşılaştır',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Geçmiş',
          ),
        ],
      ),
    );
  }
}
