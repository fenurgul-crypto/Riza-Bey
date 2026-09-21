# Önceki Uygulamaların Analizi (MAPS + FM_Cizgi)

Feyza/Arbesan'ın daha önce yaptırdığı iki hazır Android uygulaması (APK) çözümlendi.
Kaynak kod değil, derlenmiş APK'lar incelendi.

## Ortak yapı
- **Teknoloji:** Flutter (çapraz platform — aynı koddan Android + iPhone çıkabilir).
- **Paket adı:** `com.example.arbesan_tracker` (ikisinde de aynı; `com.example` varsayılan/geçici ad).
- **Harita:** `flutter_map` + OpenStreetMap döşemeleri
  (`https://tile.openstreetmap.org/{z}/{x}/{y}.png`) — **API anahtarı gerektirmiyor, ücretsiz.**
- **Konum:** `geolocator` paketi + `GeolocatorLocationService` (ön plan servisi).
- **İzinler:** `ACCESS_FINE/COARSE_LOCATION`, `INTERNET`, `RECEIVE_BOOT_COMPLETED`
  (açılışta başlama). **`ACCESS_BACKGROUND_LOCATION` YOK** → uygulama kapalıyken arka
  planda konum sınırlı; ön plan servisi (bildirimle) çalışırken gider.

## MAPS = Ebeveyn uygulaması (senin)
- Sunucudan konum **okur** ve haritada gösterir:
  - `GET http://192.168.1.106:3000/api/location/FM`  (çocuğun anlık konumu)
  - `GET http://192.168.1.106:3000/api/locations/FM` (konum geçmişi)
- "FM" = takip edilen çocuğun kimliği.

## FM_Cizgi = Çocuk uygulaması
- Konumunu sunucuya **gönderir**:
  - `POST http://192.168.1.107:3000/api/location`

## ⚠️ Neden ev dışında çalışmıyor (asıl eksik)
Uygulamalar sabit **yerel ağ (LAN) adreslerine** bağlanıyor:
`192.168.1.106` ve `192.168.1.107`, port `3000`. Bu adresler yalnızca **senin ev
Wi-Fi'ında** geçerli. Telefon evden çıkıp mobil veriye/başka Wi-Fi'a geçince o
sunucuya ulaşamaz → konum gitmez/görünmez.

Yani sistemin **%80'i hazır ve çalışıyor.** Eksik olan tek şey, biz de zaten onu
kurmaya çalışıyorduk: **her yerden erişilebilen halka açık bir "beyin" sunucusu**
(sabit ev IP'si yerine gerçek bir internet adresi).

## Backend (sunucu) hakkında
- Node/Express tarzı bir REST sunucusu (`:3000/api/location`, `/api/location/FM`,
  `/api/locations/FM`). **APK içinde yok** — ayrı çalışan bir programdı, elimizde değil.
- Yeniden yazması kolay (küçük bir REST sunucusu) ve halka açık barındırılabilir.

## Sonuç / yol
İki net son durum var:
1. **Uygulamayı Firebase'e bağla:** Flutter koduna `firebase_database` ekle; ayrı
   sunucu/barındırma gerekmez (bugün açtığımız Firebase projesi kullanılır).
2. **Küçük halka açık sunucu:** Aynı REST API'yi yazıp ücretsiz barındır, uygulamadaki
   `192.168.1.106:3000` adresini o genel adresle değiştir.

**Her iki yol da uygulamaların KAYNAK KODUNU gerektiriyor** (Dart/Flutter projesi:
`pubspec.yaml` + `lib/*.dart`). APK'nın içindeki adres derlenmiş; kaynak olmadan
değiştirilemez. Kaynak yoksa: aynı (kanıtlanmış) tasarımı sıfırdan Flutter ile
yeniden kurarız — sonuç aynı.
