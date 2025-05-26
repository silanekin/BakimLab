import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProfilSayfasi extends StatefulWidget {
  @override
  _ProfilSayfasiState createState() => _ProfilSayfasiState();
}

class _ProfilSayfasiState extends State<ProfilSayfasi> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  User? currentUser;
  String? profileImageUrl; // Profil resminin URL'si
  final String defaultProfileImage = 'lib/BakimLab/default_image.jpg'; // Varsayılan resim

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadProfilePicture();
  }

  Future<void> _loadUserData() async {
    try {
      currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        DocumentSnapshot<Map<String, dynamic>> userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();

        setState(() {
          firstNameController.text = userData['first_name'] ?? '';
          lastNameController.text = userData['last_name'] ?? '';
          emailController.text = userData['email'] ?? '';
        });
      }
    } catch (e) {
      print("Hata: $e");
    }
  }

  Future<void> _loadProfilePicture() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      setState(() {
        profileImageUrl = userData['profile_picture'] ?? defaultProfileImage;
      });
    } catch (e) {
      print("Hata: $e");
      setState(() {
        profileImageUrl = defaultProfileImage;
      });
    }
  }

  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File file = File(pickedFile.path);

      try {
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures/${currentUser!.uid}.jpg');

        UploadTask uploadTask = storageRef.putFile(file);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .update({'profile_picture': downloadUrl});

        setState(() {
          profileImageUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profil resmi başarıyla yüklendi!")),
        );
      } catch (e) {
        print("Hata: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profil resmi yüklenirken bir hata oluştu.")),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Firestore üzerinde kullanıcı bilgilerini güncelle
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .update({
          'first_name': firstNameController.text.trim(),
          'last_name': lastNameController.text.trim(),
          'email': emailController.text.trim(),
        });

        if (passwordController.text.isNotEmpty) {
          await currentUser!.updatePassword(passwordController.text.trim());
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bilgiler başarıyla güncellendi!")),
        );
      } catch (e) {
        print("Güncelleme Hatası: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bilgiler güncellenirken bir hata oluştu.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Kişisel Bilgiler",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              FirebaseAuth.instance.signOut();
              Navigator.pop(context);
            },
            child: Row(
              children: [
                Text(
                  "Çıkış Yap",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.exit_to_app, color: Colors.red),
                SizedBox(width: 16),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: profileImageUrl != null
                          ? NetworkImage(profileImageUrl!)
                          : AssetImage(defaultProfileImage) as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _uploadProfilePicture,
                        child: Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: firstNameController,
                  decoration: InputDecoration(
                    labelText: "Ad",
                    border: UnderlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ad alanı boş bırakılamaz';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: lastNameController,
                  decoration: InputDecoration(
                    labelText: "Soyad",
                    border: UnderlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Soyad alanı boş bırakılamaz';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "E-posta",
                    border: UnderlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'E-posta alanı boş bırakılamaz';
                    }
                    if (!value.contains('@')) {
                      return 'Geçerli bir e-posta adresi girin';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: "Yeni Şifre (Değiştirmek için doldurun)",
                    border: UnderlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _saveChanges,
                  child: Text(
                    "DEĞİŞİKLİKLERİ KAYDET",
                    style: TextStyle(color: Colors.white, fontSize: 16),
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