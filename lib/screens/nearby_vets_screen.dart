import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/vet_place.dart';
import '../services/nearby_vets_service.dart';

class NearbyVetsScreen extends StatefulWidget {
  const NearbyVetsScreen({super.key});

  @override
  State<NearbyVetsScreen> createState() => _NearbyVetsScreenState();
}

class _NearbyVetsScreenState extends State<NearbyVetsScreen> {
  bool loading = true;
  String? error;
  List<VetPlace> vets = [];

  @override
  void initState() {
    super.initState();
    loadNearbyVets();
  }

  Future<void> loadNearbyVets() async {
    try {
      final result = await NearbyVetsService().getNearbyVets();

      setState(() {
        vets = result;
        loading = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> openInMaps(VetPlace vet) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${vet.latitude},${vet.longitude}',
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open Google Maps');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Nearby Veterinarians 🏥'),
        backgroundColor: Colors.blue.shade50,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            error!,
            textAlign: TextAlign.center,
          ),
        ),
      )
          : vets.isEmpty
          ? const Center(
        child: Text('No nearby veterinarians found.'),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vets.length,
        itemBuilder: (context, index) {
          final vet = vets[index];

          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vet.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (vet.address.isNotEmpty)
                    Text('📍 ${vet.address}'),

                  const SizedBox(height: 6),

                  Text(
                    vet.rating > 0
                        ? '⭐ Rating: ${vet.rating}'
                        : '⭐ Rating: Not available',
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => openInMaps(vet),
                      icon: const Icon(Icons.map),
                      label: const Text('Open in Maps'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}