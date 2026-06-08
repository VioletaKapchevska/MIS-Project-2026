import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment{
  final String id;
  final String title;
  final DateTime dateTime;
  final String location;
  final String notes;

  Appointment({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.location,
    required this.notes
});
  factory Appointment.fromFirestore(Map<String, dynamic> data, String docId) {
    final ts = data['dateTime'] as Timestamp?;
    return Appointment(
      id: docId,
      title: data['title'] ?? '',
      dateTime: ts?.toDate() ?? DateTime.now(),
      location: data['location'] ?? '',
      notes: data['notes'] ?? '',
    );
  }
}