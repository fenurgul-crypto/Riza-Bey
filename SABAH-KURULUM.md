# Sabah Kurulumu — Maps + FM

Elinde iki uygulama olacak:
- **Maps** → senin telefonun (ebeveyn). Haritayı görürsün.
- **FM** → çocuğun telefonu. Konum gönderir.

İkisi de aynı Firebase'e bağlı; **mobil veride, her yerde** çalışır.

---

## 1) APK'ları indir

İkisi de burada (telefondan aç):
**https://github.com/fenurgul-crypto/riza-bey/releases/tag/son**

- Senin telefonuna: **Maps.apk**
- Çocuğun telefonuna: **FM.apk**

## 2) Kur (Android — "bilinmeyen kaynak")

İlk kurulumda Android "bilinmeyen kaynaktan kurma" izni ister:
1. İndirilen dosyaya dokun → "Ayarlar"a yönlendirir.
2. **"Bu kaynağa izin ver"**i aç.
3. Geri dön, **"Kur / Yükle"**ye bas.

## 3) Senin telefonun (Maps)

1. Maps'i aç.
2. İsmini yaz (örn. **Baba**).
3. Ekranda bir **AİLE KODU** görünür (örn. `K7M2-9QXP`). **Bunu not al** — çocuğun telefonuna gireceksin.
4. "Devam et". Harita açılır.

## 4) Çocuğun telefonu (FM)

1. FM'i aç.
2. Çocuğun ismini yaz (örn. **Elif**).
3. **Aile kodu** kutusuna, Maps'te gördüğün kodu yaz (aynısı).
4. "Devam et".
5. Konum izni isteyince **"İzin ver"** (mümkünse "Her zaman izin ver").
6. "Paylaşımı başlat" açık olsun.

## 5) Sonuç

Senin Maps haritanda çocuğun konumu canlı görünür. Farklı şehirde, mobil veride — fark etmez.

---

## GÜVENLİK — en üst seviye (2 küçük ayar)

Uygulama şimdiden çalışır, ama tam kilit için Firebase'de 2 ayar açman gerekiyor
(konsola ben giremiyorum). Her biri 30 saniye. Adımlar resimlerle geldiğinde yap:

### A) Anonim kimlik doğrulamayı aç
`console.firebase.google.com` → riza-bey → menü (☰) → **Authentication** →
**Get started** → **Sign-in method** → **Anonymous** → **Enable** → Save.

> Bu, uygulaman dışından kimsenin veriye erişememesini sağlar.

### B) Güvenlik kurallarını kilitle
riza-bey → Realtime Database → **Rules** sekmesi → içindekini sil, şunu yapıştır → **Publish**:

```json
{
  "rules": {
    ".read": false,
    ".write": false,
    "aile": {
      "$kod": {
        ".read": "auth != null",
        ".write": "auth != null",
        "$cihaz": {
          ".validate": "newData.hasChildren(['ad','lat','lng','ts'])",
          "ad":  { ".validate": "newData.isString() && newData.val().length <= 40" },
          "rol": { ".validate": "newData.isString()" },
          "lat": { ".validate": "newData.isNumber() && newData.val() >= -90 && newData.val() <= 90" },
          "lng": { ".validate": "newData.isNumber() && newData.val() >= -180 && newData.val() <= 180" },
          "acc": { ".validate": "newData.isNumber()" },
          "ts":  { ".validate": "newData.isNumber()" },
          "$other": { ".validate": false }
        }
      }
    }
  }
}
```

Bu kurallarla: sadece uygulamadan (kimliği doğrulanmış) ve **aile kodunu bilen** kişi
veriye erişebilir; internetten rastgele kimse giremez; veri yapısı doğrulanır.

> Aile kodu güçlü ve tahmin edilemez üretiliyor (örn. `K7M2-9QXP`) — bu da güvenliğin parçası.
> Kodu yabancılarla paylaşma.

---

## Bilinen sınır (dürüst not)

Bu ilk sürümde çocuğun konumu **FM uygulaması açıkken** gider. Telefon kilitlenip uygulama
uzun süre kapalı kalırsa arka planda gönderim durabilir. "Uygulama kapalıyken de sürekli"
takip, bir sonraki sürümde (arka plan servisi) eklenecek.
