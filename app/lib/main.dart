import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

const Color kBrand = Color(0xFF1D5FD6);

/// Rol derleme sırasında sabitlenir: "ebeveyn" (Maps) veya "cocuk" (FM).
/// Boşsa tek uygulamada kullanıcı seçer.
const String kRole = String.fromEnvironment('ROLE', defaultValue: '');
String get kAppName => kRole == 'cocuk' ? 'FM' : (kRole == 'ebeveyn' ? 'Maps' : 'Rıza Bey');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Güvenlik: her istemci anonim olarak kimlik doğrular (auth != null kuralı için).
  // Anonim giriş konsolda henüz açık değilse uygulama yine de çalışsın diye hata yutulur.
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (_) {}
  runApp(const RizaApp());
}

class RizaApp extends StatelessWidget {
  const RizaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: kBrand, useMaterial3: true),
      home: const Gate(),
    );
  }
}

String uret(int n) {
  const abc = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // karışması kolay harfler çıkarıldı
  final r = Random.secure();
  return List.generate(n, (_) => abc[r.nextInt(abc.length)]).join();
}

class Gate extends StatefulWidget {
  const Gate({super.key});
  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> {
  bool _loading = true;
  String? _rol, _ad, _kod, _cihaz;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _rol = p.getString('rol') ?? (kRole.isNotEmpty ? kRole : null);
    _ad = p.getString('ad');
    _kod = p.getString('kod');
    _cihaz = p.getString('cihaz');
    if (_cihaz == null) {
      _cihaz = 'c${DateTime.now().millisecondsSinceEpoch}${uret(4)}';
      await p.setString('cihaz', _cihaz!);
    }
    setState(() => _loading = false);
  }

  void _reset() => setState(() {
        _ad = null;
        _kod = null;
      });

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final kurulumBitti = _ad != null && _kod != null && (_rol != null);
    if (!kurulumBitti) {
      return SetupScreen(
        sabitRol: kRole.isNotEmpty ? kRole : null,
        onDone: (rol, ad, kod) => setState(() {
          _rol = rol;
          _ad = ad;
          _kod = kod;
        }),
      );
    }
    return HomeScreen(rol: _rol!, ad: _ad!, kod: _kod!, cihaz: _cihaz!, onReset: _reset);
  }
}

class SetupScreen extends StatefulWidget {
  final String? sabitRol; // derlemeyle sabit rol (Maps/FM); null ise seçtir
  final void Function(String rol, String ad, String kod) onDone;
  const SetupScreen({super.key, required this.sabitRol, required this.onDone});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  String? _rol;
  final _ad = TextEditingController();
  final _kod = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rol = widget.sabitRol;
    if (_rol == 'ebeveyn') {
      // Ebeveyn için güçlü, tahmin edilemez bir aile kodu üret.
      _kod.text = '${uret(4)}-${uret(4)}';
    }
  }

  @override
  void dispose() {
    _ad.dispose();
    _kod.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (_rol == null || _ad.text.trim().isEmpty || _kod.text.trim().isEmpty) return;
    final p = await SharedPreferences.getInstance();
    final kod = _kod.text.trim().toUpperCase();
    await p.setString('rol', _rol!);
    await p.setString('ad', _ad.text.trim());
    await p.setString('kod', kod);
    widget.onDone(_rol!, _ad.text.trim(), kod);
  }

  @override
  Widget build(BuildContext context) {
    final cocuk = _rol == 'cocuk';
    final ebeveyn = _rol == 'ebeveyn';
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            Text(kAppName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              ebeveyn
                  ? 'Ebeveyn — aileni haritada takip et'
                  : cocuk
                      ? 'Konumunu ailenle paylaş'
                      : 'Aile konum takip',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
            const SizedBox(height: 22),
            if (widget.sabitRol == null) ...[
              const Text('Bu telefonu kim kullanacak?', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _roleCard('ebeveyn', 'Ebeveyn', 'Haritayı görürüm', Icons.map_outlined),
              const SizedBox(height: 10),
              _roleCard('cocuk', 'Çocuk', 'Konumumu paylaşırım', Icons.location_on_outlined),
              const SizedBox(height: 22),
            ],
            const Text('İsim (haritada görünür)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _ad,
              decoration: InputDecoration(
                  hintText: ebeveyn ? 'örn. Baba' : 'örn. Elif', border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 18),
            if (ebeveyn) ...[
              const Text('Aile kodun', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Bu kodu çocuğun FM uygulamasına yazacaksın. Kimseyle paylaşma.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  color: kBrand.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBrand.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Expanded(
                    child: Text(_kod.text,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 2, color: kBrand)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: kBrand),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _kod.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kod kopyalandı')));
                    },
                  ),
                ]),
              ),
            ] else ...[
              const Text('Aile kodu', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Ebeveynin Maps uygulamasında gösterdiği kodu buraya yaz.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
              const SizedBox(height: 8),
              TextField(
                controller: _kod,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(hintText: 'örn. K7M2-9QXP', border: OutlineInputBorder()),
              ),
            ],
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _kaydet,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Devam et', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 14),
            Text('Konum yalnızca aynı aile kodunu kullanan aile üyelerine gösterilir.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5)),
          ]),
        ),
      ),
    );
  }

  Widget _roleCard(String key, String title, String sub, IconData icon) {
    final sel = _rol == key;
    return InkWell(
      onTap: () => setState(() => _rol = key),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: sel ? kBrand : Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Icon(icon, color: kBrand, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 3),
              Text(sub, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
            ]),
          ),
          if (sel) const Icon(Icons.check_circle, color: kBrand),
        ]),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final String rol, ad, kod, cihaz;
  final VoidCallback onReset;
  const HomeScreen(
      {super.key,
      required this.rol,
      required this.ad,
      required this.kod,
      required this.cihaz,
      required this.onReset});
  @override
  Widget build(BuildContext context) {
    return rol == 'cocuk'
        ? ChildScreen(ad: ad, kod: kod, cihaz: cihaz, onReset: onReset)
        : ParentScreen(ad: ad, kod: kod, cihaz: cihaz, onReset: onReset);
  }
}

class ChildScreen extends StatefulWidget {
  final String ad, kod, cihaz;
  final VoidCallback onReset;
  const ChildScreen(
      {super.key, required this.ad, required this.kod, required this.cihaz, required this.onReset});
  @override
  State<ChildScreen> createState() => _ChildScreenState();
}

class _ChildScreenState extends State<ChildScreen> {
  StreamSubscription<Position>? _sub;
  bool _paylasiyor = false;
  String _durum = 'Hazırlanıyor…';
  Position? _son;

  @override
  void initState() {
    super.initState();
    _basla();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _basla() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      setState(() => _durum = 'Telefonda konum kapalı. Aç ve tekrar dene.');
      return;
    }
    var izin = await Geolocator.checkPermission();
    if (izin == LocationPermission.denied) izin = await Geolocator.requestPermission();
    if (izin == LocationPermission.denied || izin == LocationPermission.deniedForever) {
      setState(() => _durum = 'Konum izni verilmedi. Ayarlardan izin ver.');
      return;
    }
    setState(() {
      _paylasiyor = true;
      _durum = 'Konumun paylaşılıyor';
    });
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen(_gonder);
  }

  Future<void> _gonder(Position p) async {
    _son = p;
    try {
      await FirebaseDatabase.instance.ref('aile/${widget.kod}/${widget.cihaz}').set({
        'ad': widget.ad,
        'rol': 'cocuk',
        'lat': p.latitude,
        'lng': p.longitude,
        'acc': p.accuracy,
        'ts': DateTime.now().millisecondsSinceEpoch,
      });
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _durdur() {
    _sub?.cancel();
    _sub = null;
    FirebaseDatabase.instance.ref('aile/${widget.kod}/${widget.cihaz}').remove();
    setState(() {
      _paylasiyor = false;
      _durum = 'Paylaşım kapalı';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FM'),
        actions: [IconButton(onPressed: widget.onReset, icon: const Icon(Icons.settings))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 10),
          Icon(_paylasiyor ? Icons.location_on : Icons.location_off,
              size: 64, color: _paylasiyor ? kBrand : Colors.grey),
          const SizedBox(height: 16),
          Text(widget.ad,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text('Aile kodu: ${widget.kod}',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Text(_durum, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (_son != null) ...[
                  const SizedBox(height: 8),
                  Text('${_son!.latitude.toStringAsFixed(5)}, ${_son!.longitude.toStringAsFixed(5)}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  Text('±${_son!.accuracy.round()} m',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _paylasiyor ? _durdur : _basla,
            icon: Icon(_paylasiyor ? Icons.stop : Icons.play_arrow),
            label: Text(_paylasiyor ? 'Paylaşımı durdur' : 'Paylaşımı başlat'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: _paylasiyor ? Colors.red.shade400 : kBrand,
            ),
          ),
          const Spacer(),
          Text('Not: Şu an uygulama açıkken konum gider. Kapalıyken çalışması sonraki sürümde eklenecek.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5)),
        ]),
      ),
    );
  }
}

class ParentScreen extends StatefulWidget {
  final String ad, kod, cihaz;
  final VoidCallback onReset;
  const ParentScreen(
      {super.key, required this.ad, required this.kod, required this.cihaz, required this.onReset});
  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  final _map = MapController();
  StreamSubscription<DatabaseEvent>? _sub;
  List<_Uye> _uyeler = [];

  @override
  void initState() {
    super.initState();
    _dinle();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _dinle() {
    _sub = FirebaseDatabase.instance.ref('aile/${widget.kod}').onValue.listen((e) {
      _uyeler = parseUyeler(e.snapshot.value);
      if (mounted) setState(() {});
      if (_uyeler.isNotEmpty) {
        _map.move(LatLng(_uyeler.first.lat, _uyeler.first.lng), 14);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maps'),
        actions: [IconButton(onPressed: widget.onReset, icon: const Icon(Icons.settings))],
      ),
      body: Column(children: [
        Container(
          width: double.infinity,
          color: kBrand.withValues(alpha: 0.08),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            const Icon(Icons.vpn_key, size: 16, color: kBrand),
            const SizedBox(width: 8),
            Text('Aile kodu: ${widget.kod}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: kBrand)),
            const Spacer(),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.copy, size: 16, color: kBrand),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.kod));
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Kod kopyalandı')));
              },
            ),
          ]),
        ),
        Expanded(
          child: FlutterMap(
            mapController: _map,
            options: const MapOptions(initialCenter: LatLng(41.015, 28.979), initialZoom: 11),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.rizabey.maps',
              ),
              MarkerLayer(
                markers: _uyeler
                    .map((u) => Marker(
                          point: LatLng(u.lat, u.lng),
                          width: 100,
                          height: 60,
                          child: Column(children: [
                            const Icon(Icons.location_on, color: kBrand, size: 34),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
                              ),
                              child: Text(u.ad,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ]),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: _uyeler.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Henüz paylaşan yok.\nÇocuğun telefonuna FM uygulamasını kurup yukarıdaki aile kodunu yazın.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  children: _uyeler
                      .map((u) => ListTile(
                            leading: CircleAvatar(
                              backgroundColor: kBrand,
                              child: Text(u.ad.isNotEmpty ? u.ad[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text(u.ad),
                            subtitle: Text(
                                '${u.lat.toStringAsFixed(4)}, ${u.lng.toStringAsFixed(4)} · ${agoText(u.ts)}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.my_location),
                              onPressed: () => _map.move(LatLng(u.lat, u.lng), 15),
                            ),
                          ))
                      .toList(),
                ),
        ),
      ]),
    );
  }
}

/// Firebase'den gelen ham veriyi üye listesine çevirir. (test edilebilir saf fonksiyon)
List<_Uye> parseUyeler(Object? val) {
  final list = <_Uye>[];
  if (val is Map) {
    val.forEach((key, v) {
      if (v is Map && v['lat'] is num && v['lng'] is num) {
        list.add(_Uye(
          id: key.toString(),
          ad: (v['ad'] ?? '—').toString(),
          lat: (v['lat'] as num).toDouble(),
          lng: (v['lng'] as num).toDouble(),
          ts: (v['ts'] is num) ? (v['ts'] as num).toInt() : 0,
        ));
      }
    });
  }
  return list;
}

/// Zaman farkını "az önce / 5 dk önce" biçiminde verir. (test edilebilir saf fonksiyon)
String agoText(int ts, {DateTime? now}) {
  if (ts == 0) return '';
  final n = now ?? DateTime.now();
  final s = (n.millisecondsSinceEpoch - ts) ~/ 1000;
  if (s < 60) return 'az önce';
  if (s < 3600) return '${s ~/ 60} dk önce';
  if (s < 86400) return '${s ~/ 3600} sa önce';
  return '${s ~/ 86400} gün önce';
}

class _Uye {
  final String id, ad;
  final double lat, lng;
  final int ts;
  _Uye({required this.id, required this.ad, required this.lat, required this.lng, required this.ts});
}
