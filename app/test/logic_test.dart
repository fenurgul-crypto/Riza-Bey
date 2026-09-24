import 'package:flutter_test/flutter_test.dart';
import 'package:riza_takip/main.dart';

void main() {
  group('parseUyeler', () {
    test('boş/null veri boş liste döner', () {
      expect(parseUyeler(null), isEmpty);
      expect(parseUyeler(<Object?, Object?>{}), isEmpty);
      expect(parseUyeler('bozuk'), isEmpty);
    });

    test('geçerli üyeleri ayıklar, eksik konumu atlar', () {
      final data = {
        'c1': {'ad': 'Elif', 'lat': 41.0, 'lng': 29.0, 'ts': 1000},
        'c2': {'ad': 'Eksik'}, // konum yok -> atlanır
        'c3': {'ad': 'Mehmet', 'lat': 40.5, 'lng': 28.9, 'ts': 2000},
      };
      final r = parseUyeler(data);
      expect(r.length, 2);
      expect(r.map((u) => u.ad), containsAll(['Elif', 'Mehmet']));
    });

    test('int koordinatları double olarak okur', () {
      final r = parseUyeler({
        'c1': {'ad': 'X', 'lat': 41, 'lng': 29, 'ts': 5}
      });
      expect(r.single.lat, 41.0);
      expect(r.single.lng, 29.0);
    });
  });

  group('agoText', () {
    final now = DateTime.fromMillisecondsSinceEpoch(1000000000);
    test('ts=0 boş', () => expect(agoText(0, now: now), ''));
    test('az önce', () => expect(agoText(now.millisecondsSinceEpoch - 5000, now: now), 'az önce'));
    test('dakika', () => expect(agoText(now.millisecondsSinceEpoch - 300000, now: now), '5 dk önce'));
    test('saat', () => expect(agoText(now.millisecondsSinceEpoch - 7200000, now: now), '2 sa önce'));
    test('gün', () => expect(agoText(now.millisecondsSinceEpoch - 172800000, now: now), '2 gün önce'));
  });

  group('uret (aile kodu)', () {
    test('istenen uzunlukta ve güvenli alfabede', () {
      final k = uret(8);
      expect(k.length, 8);
      expect(RegExp(r'^[A-HJ-NP-Z2-9]+$').hasMatch(k), isTrue);
    });
  });
}
