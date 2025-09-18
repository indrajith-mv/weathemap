import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Weather Map",
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final String _weatherKey = '6d2fec132b89079927d07da4f96356e9';

  final TextEditingController _searchCtrl = TextEditingController();
  final MapController _mapController = MapController();

  // NEW: store the tapped position for the marker
  LatLng? _tappedPosition; // NEW

 Future<void> _getWeather(double lat, double lon) async {
  // build URL with good precision
  final url = Uri.parse(
    'https://api.openweathermap.org/data/2.5/weather'
    '?lat=${lat.toStringAsFixed(6)}&lon=${lon.toStringAsFixed(6)}&units=metric&appid=$_weatherKey',
  );

  // Debug: print the request so you can paste it in a browser and compare.
  debugPrint('OpenWeather request: $url');

  try {
    final response = await http.get(url);
    debugPrint('OpenWeather status: ${response.statusCode}');
    debugPrint('OpenWeather body: ${response.body}');

    if (response.statusCode != 200) {
      // Show full response body for easier debugging (e.g. 401 or 429)
      _showError('Weather API error ${response.statusCode}: ${response.body}');
      return;
    }

    final data = jsonDecode(response.body);

    // Safely extract fields
    final main = data['main'] ?? {};
    final weatherList = (data['weather'] as List<dynamic>?) ?? [];
    final weather0 = weatherList.isNotEmpty ? weatherList[0] : <String, dynamic>{};

    final double? temp = main['temp'] != null ? (main['temp'] as num).toDouble() : null;
    final double? feelsLike =
        main['feels_like'] != null ? (main['feels_like'] as num).toDouble() : null;
    final double? tempMin =
        main['temp_min'] != null ? (main['temp_min'] as num).toDouble() : null;
    final double? tempMax =
        main['temp_max'] != null ? (main['temp_max'] as num).toDouble() : null;
    final int? humidity = main['humidity'] != null ? (main['humidity'] as num).toInt() : null;

    final String description = (weather0['description'] ?? '').toString();
    final String iconCode = (weather0['icon'] ?? '').toString();

    final int dt = (data['dt'] ?? 0) as int;
    final int tzOffset = (data['timezone'] ?? 0) as int;

    // compute local observation time (UTC dt + timezone offset)
    final localEpochMs = (dt + tzOffset) * 1000;
    final observedTime = DateTime.fromMillisecondsSinceEpoch(localEpochMs, isUtc: true)
        .toLocal(); // nice display in device locale

    // Attempt a reverse-geocode to show a readable place name (optional)
    String placeName = '';
    try {
      final revUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${lat.toStringAsFixed(6)}&lon=${lon.toStringAsFixed(6)}&format=json',
      );
      final revResp = await http.get(revUrl, headers: {'User-Agent': 'flutter_map_example'});
      if (revResp.statusCode == 200) {
        final revJson = jsonDecode(revResp.body);
        placeName = (revJson['display_name'] ?? '').toString();
      }
    } catch (_) {
      // ignore reverse geocode failures
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (placeName.isNotEmpty)
              Text(
                placeName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              )
            else
              Text(
                'Lat: ${lat.toStringAsFixed(5)}, Lon: ${lon.toStringAsFixed(5)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 8),
            Text(
              'Observed: ${observedTime.toString().split('.').first}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (iconCode.isNotEmpty)
              Image.network(
                'https://openweathermap.org/img/wn/$iconCode@2x.png',
                width: 64,
                height: 64,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            if (temp != null) Text('Temp: ${temp.toStringAsFixed(1)} °C', style: const TextStyle(fontSize: 18)),
            if (feelsLike != null) Text('Feels like: ${feelsLike.toStringAsFixed(1)} °C'),
            if (tempMin != null && tempMax != null)
              Text('Min: ${tempMin.toStringAsFixed(1)} °C • Max: ${tempMax.toStringAsFixed(1)} °C'),
            if (humidity != null) Text('Humidity: $humidity%'),
            if (description.isNotEmpty) Text('Condition: $description', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  } catch (e) {
    _showError('Network error: $e');
  }
}


  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _searchPlace() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
    );

    try {
      final resp = await http.get(url, headers: {'User-Agent': 'flutter_map_example'});
      if (resp.statusCode == 200) {
        final results = jsonDecode(resp.body);
        if (results.isNotEmpty) {
          final lat = double.parse(results[0]['lat']);
          final lon = double.parse(results[0]['lon']);
          _mapController.move(LatLng(lat, lon), 14);
        } else {
          _showError('Place not found');
        }
      } else {
        _showError('Error searching location');
      }
    } catch (e) {
      _showError('Search failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Search place...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: _searchPlace,
            ),
          ),
        ),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(10.9034, 76.4343),
          initialZoom: 10,
          onTap: (tapPos, latlng) {
            setState(() {
              _tappedPosition = latlng; // NEW: remember tapped location
            });
            _getWeather(latlng.latitude, latlng.longitude);
          },
        ),
        children: [
          TileLayer(
            urlTemplate:
                "https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=VGFtXlKOP6b5nHC6OTA8",
            userAgentPackageName: 'com.example.weatherapp',
          ),
          // NEW: marker layer to show pointer at tapped position
          if (_tappedPosition != null)
            MarkerLayer(
              markers: [
                Marker(
                  width: 40,
                  height: 40,
                  point: _tappedPosition!,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                'OpenStreetMap contributors',
                onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
