const express = require('express');
const fs = require('fs');

const app = express();
const PORT = 3000;

app.get('/urunler', (req, res) => {
    fs.readFile('urunler.json', 'utf8', (err, data) => {
        if (err) {
            res.status(500).send('Dosya okunamadı');
        } else {
            res.json(JSON.parse(data));
        }
    });
});

app.listen(PORT, () => {
    console.log(`Server ${PORT} portunda çalışıyor.`);
});
