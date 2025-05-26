import 'package:flutter/material.dart';
import 'dart:convert';
import 'urun_detay_sayfasi.dart';

class ProductCard extends StatelessWidget {
  final String urun_ismi;
  final String urun_barkodu;
  final String? foto;

  const ProductCard({
    Key? key,
    required this.urun_ismi,
    required this.urun_barkodu,
    this.foto,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UrunDetaySayfasi(
                urun_ismi: urun_ismi,
                urun_barkodu: urun_barkodu,
                foto: foto,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.all(8),
                child: foto != null
                    ? Image.memory(
                  Base64Decoder().convert(foto!),
                  fit: BoxFit.contain,
                )
                    : Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                urun_ismi,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}