const express = require('express');
const mysql = require('mysql');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(bodyParser.json());

// MySQL Bağlantısı
const db = mysql.createConnection({
    host: '127.0.0.1', // Host adresi
    user: 'root',      // Kullanıcı adı
    password: '2135',      // Şifre (boşsa boş bırakın)
    database: 'yeni_bakimlab' // Veritabanı adı
});

// MySQL Bağlantısını Başlat
db.connect((err) => {
    if (err) {
        console.error('MySQL bağlantı hatası:', err);
        return;
    }
    console.log('MySQL veritabanına başarıyla bağlandı!');
});

// Tüm ürünleri listeleme (fotoğraflar dahil)
app.get('/urunler', (req, res) => {
    const sql = 'SELECT urun_ismi, urun_icerigi, urun_barkodu, foto FROM yeni_bakimlab';
    db.query(sql, (err, results) => {
        if (err) {
            res.status(500).json({ error: 'Veritabanı hatası' });
            return;
        }

        // Fotoğrafları Base64 formatına dönüştürerek döndür
        const urunler = results.map(row => ({
            urun_ismi: row.urun_ismi,
            urun_icerigi: row.urun_icerigi,
            urun_barkodu: row.urun_barkodu,
            foto: row.foto ? Buffer.from(row.foto).toString('base64') : null
        }));

        res.json(urunler);
    });
});

// Tek bir ürünü getirme (barkod ile)
app.get('/urunler/:barkod', (req, res) => {
    const barkod = req.params.barkod;
    const sql = 'SELECT urun_ismi, urun_icerigi, urun_barkodu, foto FROM yeni_bakimlab WHERE urun_barkodu = ?';
    db.query(sql, [barkod], (err, results) => {
        if (err) {
            res.status(500).json({ error: 'Veritabanı hatası' });
            return;
        }
        if (results.length === 0) {
            res.status(404).json({ message: 'Ürün bulunamadı' });
            return;
        }

        // Fotoğrafı Base64 formatına dönüştürerek döndür
        const urun = {
            urun_ismi: results[0].urun_ismi,
            urun_icerigi: results[0].urun_icerigi,
            urun_barkodu: results[0].urun_barkodu,
            foto: results[0].foto ? Buffer.from(results[0].foto).toString('base64') : null
        };

        res.json(urun);
    });
});

// Yeni ürün ekleme (fotoğraf dahil)
app.post('/urunler', (req, res) => {
    const { urun_ismi, urun_icerigi, urun_barkodu, foto } = req.body;

    const sql = 'INSERT INTO yeni_bakimlab (urun_ismi, urun_icerigi, urun_barkodu, foto) VALUES (?, ?, ?, ?)';
    db.query(sql, [urun_ismi, urun_icerigi, urun_barkodu, foto ? Buffer.from(foto, 'base64') : null], (err, results) => {
        if (err) {
            res.status(500).json({ error: 'Ürün ekleme sırasında bir hata oluştu' });
            return;
        }

        res.status(201).json({ message: 'Ürün başarıyla eklendi', id: results.insertId });
    });
});

// Sunucuyu başlatma
const PORT = 3000;
app.listen(PORT, () => {
    console.log(`API ${PORT} portunda çalışıyor.`);
});
