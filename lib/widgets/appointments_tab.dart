import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../forms/add_appointment_screen.dart';
import '../forms/edit_appointment_screen.dart';
import '../models/appointment_model.dart';


class AppointmentsTab extends StatelessWidget {
  final String petId;
  const AppointmentsTab({super.key, required this.petId});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection('pets')
        .doc(petId)
        .collection('appointments')
        .orderBy('dateTime', descending: false);

    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: ref.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No appointments yet 📅"));
          }

          final items = snapshot.data!.docs
              .map((d) => Appointment.fromFirestore(d.data(), d.id))
              .toList();

          return ListView.builder(
            //pominati - zeleni, idni - crveni
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final a = items[i];
              final dt = a.dateTime;

              final now = DateTime.now();
              final isPast = a.dateTime.isBefore(now);

              final dateStr =
                  "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}";
              final timeStr =
                  "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

              return Card(
                //zeleni - pominat, crveni - idni
                elevation: 3,
                color: isPast ? Colors.green.shade200 : Colors.red.shade200,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: Icon(Icons.event,color: isPast ? Colors.green.shade50 : Colors.red,),
                  title: Text(
                    a.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("$dateStr • $timeStr"),
                      if (a.location.isNotEmpty) Text("Location: ${a.location}"),
                      if (a.notes.isNotEmpty) Text("Notes: ${a.notes}"),
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
                              builder: (_) => EditAppointmentScreen(
                                petId: petId,
                                appointment: a,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _delete(context, petId, a.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 8,
        child: const Icon(Icons.add,color: Colors.blue,size: 28,),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddAppointmentScreen(petId: petId)),
          );
        },
      ),
    );
  }

  Future<void> _delete(BuildContext context, String petId, String appointmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete appointment?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection('pets')
        .doc(petId)
        .collection('appointments')
        .doc(appointmentId)
        .delete();
  }
}