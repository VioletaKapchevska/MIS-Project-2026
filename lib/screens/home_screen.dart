import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../forms/add_pet_screen.dart';
import '../screens/nearby_vets_screen.dart';
import '../widgets/pets_list.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Pets 🐾',
          style: TextStyle(color: Color(0xFF1F2D5A)),
        ),
        backgroundColor: Colors.blue.shade50,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.local_hospital),
                label: const Text('Find Nearby Vets'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NearbyVetsScreen(),
                    ),
                  );
                },
              ),
            ),
          ),

          const Expanded(
            child: PetsListWidget(),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        elevation: 8,
        child: const Icon(Icons.add, color: Colors.blue, size: 28),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPetScreen()),
          );
        },
      ),
    );
  }
}