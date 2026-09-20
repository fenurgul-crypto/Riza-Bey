# Rıza Bey — Aile Konum Takip

Ailenin (özellikle çocukların) nerede olduğunu güvenli biçimde takip etmek için
bir aile konum uygulaması. Amaç: **çocuklar büyürken nerede ve kimlerle olduklarını
bilmek** — ebeveynin kendi çocuklarını takibi.

## Şu anki durum

`index.html` — tarayıcıda çalışan **önizleme**. Ebeveynin gördüğü canlı harita ekranı:

- Aile üyeleri haritada konum kartlarıyla (örnek veri)
- **"Konumumu paylaş"** → tarayıcının gerçek GPS'i ile kendini haritada canlı görürsün
  (yürüyünce nokta hareket eder), koordinat ve doğruluk (±m) okunur
- Aile listesi: durum (evde/okulda/yolda), son görülme, pil — düşük pil uyarısı
- Ekran Süresi ekranı (örnek veri) ve Bölgeler/Ayarlar yol haritası kartları

> Önizleme; harita kendi çizdiğimiz şematik bir şehir. Gerçek sokak haritası ve
> arka planda konum, native **Android** uygulamasına ait olacak.

## Yol haritası

1. **Konum (öncelik)** — canlı aile haritası, güvenli bölge (ev/okul) giriş-çıkış uyarısı
2. **Ekran süresi & uygulama kullanımı** — çocuğun telefonu ne kadar/ne için kullandığı
3. **Davet & aile kurma** — davet linkiyle üye ekleme, izin yönetimi

## Hedef platform

Android. (Web önizleme her telefonda açılır; native uygulama arka planda konum,
bölge uyarıları ve kullanım istatistikleri için gerekli.)

## Notlar

- Kişisel/hassas veri (konum) işleyen bir uygulama; izinler açık ve iptal edilebilir olmalı.
- Takip edilen kişilerin bunu bilmesi esas alınır.
