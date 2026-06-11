import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/vet_place.dart';

class NearbyVetsService {

  static const String apiKey = 'AIzaSyC_KGLO8vlLNBSp6qx7VpTkIOIVdd6GUCM';

  Future<List<VetPlace>> getNearbyVets() async {

    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied');
    }

    final position = await Geolocator.getCurrentPosition();

    final response = await http.post(
      Uri.parse(
        'https://places.googleapis.com/v1/places:searchNearby',
      ),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask':
        'places.displayName,places.formattedAddress,places.rating,places.location',
      },
      body: jsonEncode({
        "includedTypes": ["veterinary_care"],
        "maxResultCount": 10,
        "locationRestriction": {
          "circle": {
            "center": {
              "latitude": position.latitude,
              "longitude": position.longitude,
            },
            "radius": 5000.0
          }
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    final data = jsonDecode(response.body);

    final List places = data['places'] ?? [];

    return places.map((p) {
      return VetPlace(
        name: p['displayName']?['text'] ?? 'Unknown',
        address: p['formattedAddress'] ?? '',
        rating: (p['rating'] ?? 0).toDouble(),
        latitude: p['location']['latitude'],
        longitude: p['location']['longitude'],
      );
    }).toList();
  }
}