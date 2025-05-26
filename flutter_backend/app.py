from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import pandas as pd
import mysql.connector
from sqlalchemy import create_engine
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.neighbors import KNeighborsClassifier
from sklearn.metrics import accuracy_score, classification_report
import warnings
from sklearn.exceptions import UndefinedMetricWarning
import logging
from typing import List, Optional, Dict
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime
from typing import List, Dict
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.feature_extraction.text import CountVectorizer

#uvicorn app:app --reload --host 0.0.0.0 --port 8000

app = FastAPI(title="Bakım Ürünleri API")

# CORS ayarları
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Tüm originlere izin ver (geliştirme için)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
# Logging ayarları
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# FastAPI uygulamasını oluştur
app = FastAPI(title="Bakım Ürünleri API")

# Global değişkenler
df = None
scaler = None
knn = None

# Sabit listeler
temiz_kelime_listesi = [
    'aqua', 'water', 'glycerin', 'hyaluronic', 'vitamin', 'natural', 'organic', 
    'plant-based', 'pure', 'clean', 'safe', 'biodegradable', 'aloe', 'chamomile', 
    'cucumber', 'jojoba', 'olive', 'essential oil', 'shea butter', 'avocado', 
    'grapeseed', 'green tea', 'argan', 'honey', 'probiotic', 'turmeric', 
    'lavender', 'tea tree', 'rosemary'
]

kirli_kelime_listesi = [
    'paraben', 'sulfate', 'silicone', 'alcohol', 'synthetic', 'fragrance', 
    'petrochemical', 'phthalate', 'toxic', 'harmful', 'irritant', 'formaldehyde', 
    'coal tar', 'triclosan', 'benzophenone', 'mineral oil', 'microplastic',
    'propylene glycol', 'butylene glycol', 'PEG', 'DEA', 'MEA', 'TEA', 
    'artificial color', 'EDTA', 'BHA', 'BHT'
]

risk_dereceleri = {
    "paraben": 5, "sulfate": 3, "formaldehyde": 7, "synthetic": 2,
    "fragrance": 4, "toxic": 6, "harmful": 5, "artificial color": 4,
    "BHA": 6, "BHT": 5, "EDTA": 3
}

# Pydantic modelleri
class PredictionInput(BaseModel):
    temizlik_skoru: float
    kirlilik_skoru: float
    risk_skoru: float

class HistoryInput(BaseModel):
    urun_ismi: str
    temizlik_yuzdesi: float

class UrunDetay(BaseModel):
    urun_ismi: str
    temizlik_yuzdesi: float
    risk_skoru: float
    temiz_icerikler: List[str]
    kirli_icerikler: List[str]

class GecmisItem(BaseModel):
    kullanici_id: str
    urun_ismi: str
    temizlik_yuzdesi: float

# Yardımcı fonksiyonlar
def init_database():
    """Veritabanı bağlantısını başlat ve verileri yükle"""
    global df, scaler, knn
    try:
        engine = create_engine('mysql+mysqlconnector://root:2135@localhost/yeni_bakimlab')
        df = pd.read_sql_query("SELECT * FROM yeni_bakimlab", con=engine)
        process_data()
        train_model()
        logger.info("Veritabanı başarıyla yüklendi ve model eğitildi")
    except Exception as e:
        logger.error(f"Veritabanı başlatma hatası: {str(e)}")
        raise

def process_data():
    """Veriyi işle ve skorları hesapla"""
    global df
    try:
        # Skorları hesapla
        df['temizlik_skoru'] = df['urun_icerigi'].apply(lambda x: temizlik_skoru(str(x).lower()))
        df['kirlilik_skoru'] = df['urun_icerigi'].apply(lambda x: kirlilik_skoru(str(x).lower()))
        df['risk_skoru'] = df['urun_icerigi'].apply(lambda x: risk_skoru(str(x).lower()))
        
        # Temizlik yüzdesini hesapla
        df['temizlik_yuzdesi'] = df.apply(
            lambda row: (row['temizlik_skoru'] / 
                       (row['temizlik_skoru'] + row['kirlilik_skoru']) * 100) 
            if (row['temizlik_skoru'] + row['kirlilik_skoru']) > 0 
            else 0, 
            axis=1
        )

        # Debug için yazdır
        print("\nÖrnek ürün analizi:")
        ornek_urun = df[df['urun_ismi'] == "Nuxe Prodigieux Duş Yağı 200ml"].iloc[0]
        print(f"Ürün: {ornek_urun['urun_ismi']}")
        print(f"İçerik: {ornek_urun['urun_icerigi']}")
        print(f"Temizlik skoru: {ornek_urun['temizlik_skoru']}")
        print(f"Kirlilik skoru: {ornek_urun['kirlilik_skoru']}")
        print(f"Risk skoru: {ornek_urun['risk_skoru']}")
        print(f"Temizlik yüzdesi: {ornek_urun['temizlik_yuzdesi']}")
        
    except Exception as e:
        print(f"Veri işleme hatası: {str(e)}")
        raise

def train_model():
    """ML modelini eğit"""
    global df, scaler, knn
    threshold = df['temizlik_yuzdesi'].mean()
    df['temizlik_sinifi'] = df['temizlik_yuzdesi'].apply(
        lambda x: 'Yüksek' if x > threshold else 'Düşük'
    )
    
    X = df[['temizlik_skoru', 'kirlilik_skoru', 'risk_skoru']]
    y = df['temizlik_sinifi']
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    scaler = StandardScaler()
    X_train = scaler.fit_transform(X_train)
    
    knn = KNeighborsClassifier(n_neighbors=5)
    knn.fit(X_train, y_train)

def temizlik_skoru(icerik: str) -> int:
    if not isinstance(icerik, str):
        return 0
    return sum(1 for k in temiz_kelime_listesi if k in icerik.lower())

def kirlilik_skoru(icerik: str) -> int:
    if not isinstance(icerik, str):
        return 0
    return sum(1 for k in kirli_kelime_listesi if k in icerik.lower())

def risk_skoru(icerik: str) -> float:
    if not isinstance(icerik, str):
        return 0
    return sum(risk_dereceleri.get(k, 0) for k in kirli_kelime_listesi if k in icerik.lower())

# FastAPI endpoint'leri

@app.get("/oneri/{kullanici_id}")
async def get_recommendations(kullanici_id: str):
    try:
        connection = mysql.connector.connect(
            host='localhost',
            user='root',
            password='2135',
            database='yeni_bakimlab',
            charset='utf8mb4',  # UTF-8 desteği için
            collation='utf8mb4_turkish_ci'  # Türkçe karakter desteği için
        )
        cursor = connection.cursor(dictionary=True)

        # SQL sorgularında CONVERT kullanarak karakter kodlamasını düzeltelim
        cursor.execute("""
            SELECT 
                CONVERT(g.urun_ismi USING utf8mb4) as urun_ismi,
                g.temizlik_yuzdesi
            FROM (
                SELECT urun_ismi, temizlik_yuzdesi
                FROM gecmis
                WHERE kullanici_id = %s
                ORDER BY tarih DESC
                LIMIT 5
            ) g
        """, (kullanici_id,))
        
        gecmis_urunler = cursor.fetchall()

        if not gecmis_urunler:
            return {
                "kullanici_id": kullanici_id,
                "oneriler": []
            }

        oneriler = []
        for gecmis_urun in gecmis_urunler:
            cursor.execute("""
                SELECT 
                    CONVERT(u.urun_ismi USING utf8mb4) as urun_ismi,
                    COALESCE(u.temizlik_yuzdesi, 0) as temizlik_yuzdesi,
                    ABS(COALESCE(u.temizlik_yuzdesi, 0) - %s) as fark
                FROM urunler u
                WHERE u.urun_ismi != %s
                  AND u.temizlik_yuzdesi IS NOT NULL
                  AND u.temizlik_yuzdesi >= 50
                ORDER BY fark ASC
                LIMIT 3
            """, (gecmis_urun['temizlik_yuzdesi'], gecmis_urun['urun_ismi']))
            
            benzer_urunler = cursor.fetchall()
            
            if benzer_urunler:
                oneriler.append({
                    "kaynak_urun": gecmis_urun['urun_ismi'],
                    "kaynak_temizlik": float(gecmis_urun['temizlik_yuzdesi']),
                    "benzer_urunler": [{
                        "urun_ismi": urun['urun_ismi'],
                        "temizlik_yuzdesi": float(urun['temizlik_yuzdesi']),
                        "benzerlik_skoru": round(1 - (urun['fark'] / 100), 2)
                    } for urun in benzer_urunler if urun['urun_ismi'] and urun['temizlik_yuzdesi']]
                })

        return {
            "kullanici_id": kullanici_id,
            "oneriler": oneriler
        }

    except Exception as e:
        print(f"Hata oluştu: {str(e)}")
        return {
            "kullanici_id": kullanici_id,
            "oneriler": [],
            "error": str(e)
        }
    
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()

@app.get("/gecmis/{kullanici_id}")
async def gecmis_getir(kullanici_id: str):
    try:
        connection = mysql.connector.connect(
            host='localhost',
            user='root',
            password='2135',
            database='yeni_bakimlab'
        )
        cursor = connection.cursor(dictionary=True)
        
        sql = """
        SELECT urun_ismi, temizlik_yuzdesi, DATE_FORMAT(tarih, '%d.%m.%Y %H:%i') as tarih
        FROM gecmis 
        WHERE kullanici_id = %s 
        ORDER BY tarih DESC
        """
        cursor.execute(sql, (kullanici_id,))
        
        sonuclar = cursor.fetchall()
        return sonuclar
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
        
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()

@app.post("/gecmis/ekle")
async def gecmis_ekle(gecmis: GecmisItem):
    try:
        connection = mysql.connector.connect(
            host='localhost',
            user='root',
            password='2135',
            database='yeni_bakimlab'
        )
        cursor = connection.cursor()
        
        sql = """
        INSERT INTO gecmis (kullanici_id, urun_ismi, temizlik_yuzdesi)
        VALUES (%s, %s, %s)
        """
        values = (gecmis.kullanici_id, gecmis.urun_ismi, gecmis.temizlik_yuzdesi)
        
        cursor.execute(sql, values)
        connection.commit()
        
        return {"message": "Başarıyla eklendi"}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
        
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()
    
@app.on_event("startup")
async def startup_event():
    """Uygulama başlatıldığında çalışacak kod"""
    warnings.filterwarnings("ignore", category=UserWarning)
    warnings.filterwarnings("ignore", category=UndefinedMetricWarning)
    init_database()

@app.get("/")
async def home():
    return {"message": "Bakım Ürünleri API çalışıyor"}

@app.get("/hesaplanabilir-urunler")
async def get_hesaplanabilir_urunler():
    try:
        # Temizlik yüzdesi hesaplanmış ürünleri filtrele
        hesaplanabilir_urunler = df[
            (df['temizlik_yuzdesi'].notna()) &  # NaN olmayanlar
            (df['temizlik_yuzdesi'] > 0)  # 0'dan büyük olanlar
        ]

        # Sonuçları listele
        sonuclar = hesaplanabilir_urunler[['urun_ismi', 'urun_barkodu', 'temizlik_yuzdesi']].to_dict('records')
        
        print(f"Toplam hesaplanabilir ürün sayısı: {len(sonuclar)}")  # Debug için
        return sonuclar
        
    except Exception as e:
        print(f"Hata: {str(e)}")
        raise HTTPException(
            status_code=500, 
            detail=f"Hesaplanabilir ürünler listelenirken hata oluştu: {str(e)}"
        )
@app.post("/predict")
async def predict(input_data: PredictionInput):
    try:
        input_df = pd.DataFrame([input_data.dict()])
        input_scaled = scaler.transform(input_df)
        prediction = knn.predict(input_scaled)
        return {"prediction": prediction[0]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/history")
async def get_history():
    try:
        connection = mysql.connector.connect(
            host='localhost',
            user='root',
            password='2135',
            database='yeni_bakimlab'
        )
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT * FROM gecmis")
        history_records = cursor.fetchall()
        connection.close()
        return history_records
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/history")
async def add_history(history_data: HistoryInput):
    try:
        connection = mysql.connector.connect(
            host='localhost',
            user='root',
            password='2135',
            database='yeni_bakimlab'
        )
        cursor = connection.cursor()
        cursor.execute(
            "INSERT INTO gecmis (urun_ismi, temizlik_yuzdesi) VALUES (%s, %s)",
            (history_data.urun_ismi, history_data.temizlik_yuzdesi)
        )
        connection.commit()
        connection.close()
        return {"message": "Geçmişe kaydedildi"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/recommend")
async def recommend():
    try:
        connection = mysql.connector.connect(
            host='localhost',
            user='root',
            password='2135',
            database='yeni_bakimlab'
        )
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT urun_ismi FROM gecmis")
        past_products = [item['urun_ismi'] for item in cursor.fetchall()]
        connection.close()

        recommended = df[df['urun_ismi'].isin(past_products)]\
            .sort_values(by='temizlik_yuzdesi', ascending=False)\
            .head(5)
        
        return recommended[['urun_ismi', 'temizlik_yuzdesi']].to_dict(orient='records')
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/urun_detayi/{urun_ismi}")
async def urun_detayi(urun_ismi: str):
    try:
        # Debug için
        print(f"Aranan ürün: {urun_ismi}")
        
        # Ürünü bul
        urun = df[df['urun_ismi'] == urun_ismi]
        
        if urun.empty:
            print(f"Ürün bulunamadı: {urun_ismi}")
            raise HTTPException(status_code=404, detail="Ürün bulunamadı")
            
        urun = urun.iloc[0]
        
        # Debug için değerleri kontrol et
        print(f"Bulunan ürün değerleri:")
        print(f"Temizlik skoru: {urun['temizlik_skoru']}")
        print(f"Kirlilik skoru: {urun['kirlilik_skoru']}")
        print(f"Temizlik yüzdesi: {urun['temizlik_yuzdesi']}")
        
        response = {
            'urun_ismi': urun['urun_ismi'],
            'temizlik_yuzdesi': float(urun['temizlik_yuzdesi']),
            'risk_skoru': float(urun['risk_skoru']),
            'temiz_icerikler': [k for k in temiz_kelime_listesi 
                               if k in str(urun['urun_icerigi']).lower()],
            'kirli_icerikler': [k for k in kirli_kelime_listesi 
                               if k in str(urun['urun_icerigi']).lower()]
        }
        
        print(f"Dönen yanıt: {response}")
        return response
        
    except Exception as e:
        print(f"Hata: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)