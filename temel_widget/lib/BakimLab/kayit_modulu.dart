import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'giris_sayfasi.dart'; // LoginPage dosyasını import edin

class RegisterPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> registerUser(BuildContext context) async {
    final String firstName = firstNameController.text.trim();
    final String lastName = lastNameController.text.trim();
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();
    final String confirmPassword = confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Şifreler eşleşmiyor")),
      );
      return;
    }

    try {
      // Kullanıcı Firebase Authentication ile kaydedilir
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore’a kullanıcı bilgilerini kaydedin
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'created_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Kayıt başarılı!")),
      );

      // Kayıt başarılıysa giriş sayfasına yönlendirin
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Kayıt sırasında hata: $e")),
      );
    }
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
      ),
      body: SingleChildScrollView( // Scroll özelliği ekleniyor
        child: Padding(
          padding: const EdgeInsets.all(0.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(
                    "Temiz Bakım, Güzel Seçim!",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      Text(
                        "Aramıza Hoşgeldiniz!",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: TextFormField(
                    controller: firstNameController,
                    decoration: InputDecoration(
                      labelText: 'Ad',
                      labelStyle: TextStyle(color: Colors.grey[700]),
                      border: UnderlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen adınızı girin';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: TextFormField(
                    controller: lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Soyad',
                      labelStyle: TextStyle(color: Colors.grey[700]),
                      border: UnderlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen soyadınızı girin';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'E-posta',
                      labelStyle: TextStyle(color: Colors.grey[700]),
                      border: UnderlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen e-posta adresinizi girin';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      labelStyle: TextStyle(color: Colors.grey[700]),
                      border: UnderlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen şifrenizi girin';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: TextFormField(
                    controller: confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Şifreyi tekrar giriniz',
                      labelStyle: TextStyle(color: Colors.grey[700]),
                      border: UnderlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen şifrenizi tekrar girin';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        registerUser(context);
                      }
                    },
                    child: Text(
                      'KAYIT OL',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: 'Zaten bir hesabım var. ',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        children: [
                          TextSpan(
                            text: 'Giriş Yap!',
                            style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
