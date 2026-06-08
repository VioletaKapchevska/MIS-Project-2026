import 'package:cloud_firestore/cloud_firestore.dart';

class Vaccination{
  final String id;
  final String name;
  final DateTime date;
  final String notes;
  Vaccination({
    required this.id,
    required this.name,
    required this.date,
    required this.notes
});
  factory Vaccination.fromFirestore(Map<String, dynamic> data, String docId) {
    final ts = data['date'] as Timestamp?;
    return Vaccination(
      id : docId,
      name : data['name'] ?? '',
      date : ts?.toDate() ?? DateTime.now(),
      notes : data['notes'] ?? '',
    );
  }

}