
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mis_proekt/widgets/pet_card.dart';

import '../models/pet_model.dart';

class PetsListWidget extends StatefulWidget {
  const PetsListWidget({super.key});

  @override
  State<PetsListWidget> createState() => _PetsListWidgetState();
}

class _PetsListWidgetState extends State<PetsListWidget> {
  final TextEditingController searchCtrl = TextEditingController();
  String query = "";

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Column(
      children: [
        //search
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: TextField(
            controller: searchCtrl,
            onChanged: (v) => setState(() => query = v.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: "Search by name...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  searchCtrl.clear();
                  setState(() => query = "");
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        // LIST
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('pets')
                .where('ownerId', isEqualTo: uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No pets yet 🐾"));
              }

              final pets = snapshot.data!.docs
                  .map((doc) => Pet.fromFirestore(doc.data(), doc.id))
                  .toList();

              //filter
              final filtered = pets.where((p) {
                final name = (p.name).toLowerCase(); // ако кај тебе не е "name", смени тука
                return name.contains(query);
              }).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text("No matches 😿"));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  return PetCardWidget(pet: filtered[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}