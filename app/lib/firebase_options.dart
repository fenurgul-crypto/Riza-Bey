// Firebase bağlantı ayarları (riza-bey projesi).
// Bu değerler gizli/şifre değildir; istemci uygulamalara gömülmek üzere tasarlanmıştır.
// Güvenlik, Realtime Database kuralları ile sağlanır.
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => android;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAQ7KJrOyd3cSgS4EJdHAY11MdKfwtDKqQ',
    appId: '1:860534299810:web:0d5566e7cd52e22a7fcbfb',
    messagingSenderId: '860534299810',
    projectId: 'riza-bey',
    authDomain: 'riza-bey.firebaseapp.com',
    databaseURL: 'https://riza-bey-default-rtdb.firebaseio.com',
    storageBucket: 'riza-bey.firebasestorage.app',
  );
}
