# Firebase Kurulumu — Senin Yapacakların

Rıza Bey uygulamasının "beyni" Firebase olacak (iki telefonu birbirine bağlayan
ücretsiz Google servisi). Bu adımları **bir kez** yapıyorsun; sonrası bende.

> Kart bilgisi gerekmez, ücretsizdir. ~10 dakika. Bilgisayardan yapman daha kolay
> ama telefondan da olur.

---

## 1. Firebase'e gir
1. Tarayıcıda **https://console.firebase.google.com** aç.
2. Google hesabınla giriş yap (Gmail'in yeter).

## 2. Proje oluştur
1. **"Proje ekle" / "Add project"** kutusuna tıkla.
2. İsim: **`riza-bey`** yaz → İleri.
3. "Google Analytics" adımı çıkarsa → **kapat (Disable)** → İleri.
4. **"Proje oluştur"** → 30 saniye bekle → Devam.

## 3. Realtime Database aç
1. Sol menüde **Build → Realtime Database**'e tıkla.
2. **"Veritabanı oluştur / Create Database"**.
3. Konum sorarsa **Belgium (europe-west1)** seç → İleri.
4. Kurallar için şimdilik **"Test modu / Test mode"** seç → Etkinleştir.
   > Bu geçici; uygulama çalışır çalışmaz güvenliği birlikte kilitleyeceğiz.

## 4. Web uygulaması ekle (asıl ihtiyacım olan)
1. Sol üstte **"Proje genel bakış / Project Overview"**'a dön.
2. **`</>`** (web) simgesine tıkla.
3. Takma ad: **`riza-bey-web`** → **"Uygulamayı kaydet"**.
   > "Firebase Hosting" kutusunu **işaretleme**, boş bırak.
4. Ekranda şuna benzer bir kod bloğu çıkar:

   ```js
   const firebaseConfig = {
     apiKey: "AIza........",
     authDomain: "riza-bey.firebaseapp.com",
     databaseURL: "https://riza-bey-default-rtdb.europe-west1.firebasedatabase.app",
     projectId: "riza-bey",
     storageBucket: "riza-bey.appspot.com",
     messagingSenderId: "123456789",
     appId: "1:123456789:web:abc123"
   };
   ```

## 5. Bunu bana gönder
Yukarıdaki **`firebaseConfig` bloğunu olduğu gibi kopyala, buraya yapıştır.**

> Bu bilgiler **şifre/gizli değildir** — web uygulamaları için paylaşılması normaldir,
> güvenlik ayrı kurallarla sağlanır (onu birlikte yapacağız). Yine de sen rahat et
> diye söyleyeyim: burada kart, banka veya şifre bilgisi yok.

---

Bunu alınca: kodu Firebase'e bağlarım, uygulamayı barındırırım (senin telefonundan
açabileceğin bir link veririm), sonra güvenlik kurallarını birlikte kilitleriz.
İki ayrı telefon — ayrı hesap, hatta hesapsız — aynı **aile kodu** ile buluşacak.
