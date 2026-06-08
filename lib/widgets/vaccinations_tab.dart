import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../forms/add_vaccination_screen.dart';
import '../forms/edit_vaccination_screen.dart';
import '../models/vaccination_model.dart';


class VaccinationsTab extends StatelessWidget {
  final String petId;

  const VaccinationsTab({super.key, required this.petId});

  @override
  Widget build(BuildContext context) {
    final List<Color> cardColors = [
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.orange.shade100,
      Colors.purple.shade100,
      Colors.teal.shade100,
      Colors.red.shade100,
      Colors.indigo.shade100,
    ];

    final vaccinesRef = FirebaseFirestore.instance
        .collection('pets')
        .doc(petId)
        .collection('vaccinations')
        .orderBy('date', descending: true);

    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: vaccinesRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No vaccinations yet 💉"));
          }

          final vaccines = snapshot.data!.docs
              .map((d) => Vaccination.fromFirestore(d.data(), d.id))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: vaccines.length,
            itemBuilder: (context, i) {
              final v = vaccines[i];
              final d = "${v.date.day.toString().padLeft(2, '0')}"
                  ".${v.date.month.toString().padLeft(2, '0')}"
                  ".${v.date.year}";

              return Card(
                elevation: 3,
                color: cardColors[i % cardColors.length],
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.vaccines),
                  title: Text(
                    v.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Date: $d"),
                      if (v.notes.isNotEmpty) Text("Notes: ${v.notes}"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditVaccinationScreen(
                                petId: petId,
                                vaccination: v,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteVaccination(context, petId, v.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      //add vaccination btn
      floatingActionButton: FloatingActionButton(
        elevation: 8,
        child: const Icon(Icons.add,color: Colors.blue,size: 28,),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddVaccinationScreen(petId: petId)),
          );
        },
      ),
    );
  }

  // ✅ delete single vaccine
  Future<void> _deleteVaccination(
      BuildContext context,
      String petId,
      String vaccinationId,
      ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete vaccination?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection('pets')
        .doc(petId)
        .collection('vaccinations')
        .doc(vaccinationId) // ✅ FIXED
        .delete();
  }
}