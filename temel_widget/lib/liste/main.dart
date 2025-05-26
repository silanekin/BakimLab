


import 'package:flutter/material.dart';

void main(){

  runApp(MaterialApp(
      home:MyApp()
  ));
}

class MyApp extends StatelessWidget {
  String mesaj = "Merhaba ilk uygulama";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(mesaj),
      ),
      body: Center(
        child: ElevatedButton(
          child: Text("sonucu gör"),
          onPressed: () {
            var alert = AlertDialog(
              title: Text("Sınav Sonucu"),
              content: Text("Geçti"),
            );
            showDialog(context: context, builder: (BuildContext context)=>alert);
          },

        ) ,
      ),
    );
  }
}