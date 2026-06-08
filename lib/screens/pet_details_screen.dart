import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mis_proekt/models/pet_model.dart';
import 'package:mis_proekt/widgets/appointments_tab.dart';
import 'package:mis_proekt/widgets/vaccinations_tab.dart';
import 'package:mis_proekt/screens/ai_recommendation_screen.dart';

class PetDetailsScreen extends StatelessWidget {
  final Pet pet;

  const PetDetailsScreen({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(pet.name),
          backgroundColor: Colors.blue.shade50,
          bottom: const TabBar(
            tabs: [
              Tab(text: "Overview"),
              Tab(text: "Vaccines"),
              Tab(text: "Appointments"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(pet: pet),
            VaccinationsTab(petId: pet.id),
            AppointmentsTab(petId: pet.id),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Pet pet;
  const _OverviewTab({required this.pet});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        /// IMAGE + NAME
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: pet.imgUrl.isNotEmpty
                  ? Image.network(
                pet.imgUrl,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 110,
                height: 110,
                color: Colors.grey.shade200,
                child: const Icon(Icons.pets, size: 48),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                pet.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        /// PET INFO CARD
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                const Text(
                  "Pet info",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _InfoRow(label: "Type", value: pet.type),
                _InfoRow(label: "Age", value: "${pet.age} years"),
                if (pet.breed.isNotEmpty)
                  _InfoRow(label: "Breed", value: pet.breed),
                if (pet.weight > 0)
                  _InfoRow(label: "Weight", value: "${pet.weight} kg"),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),
        //NOVO DODADENO
        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.auto_awesome),
            label: const Text("AI Recommendations"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AiRecommendationsScreen(pet: pet),
                ),
              );
            },
          ),
        ),
        /// LAST VACCINATION
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Last vaccination",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('pets')
                      .doc(pet.id)
                      .collection('vaccinations')
                      .orderBy('date', descending: true)
                      .limit(1)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text("No vaccinations yet");
                    }

                    final data = snapshot.data!.docs.first.data();
                    final date = (data['date'] as Timestamp).toDate();

                    final formattedDate =
                        "${date.day.toString().padLeft(2, '0')}"
                        ".${date.month.toString().padLeft(2, '0')}"
                        ".${date.year}";

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((data['name'] ?? "Unknown").toString()),
                        Text(formattedDate),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        /// NEXT APPOINTMENT ✅ (real)
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Next appointment",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),

                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('pets')
                      .doc(pet.id)
                      .collection('appointments')
                      .where(
                    'dateTime',
                    isGreaterThanOrEqualTo:
                    Timestamp.fromDate(DateTime.now()),
                  )
                      .orderBy('dateTime', descending: false)
                      .limit(1)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text("No upcoming appointments");
                    }

                    final data = snapshot.data!.docs.first.data();
                    final dt = (data['dateTime'] as Timestamp).toDate();

                    final dateStr =
                        "${dt.day.toString().padLeft(2, '0')}"
                        ".${dt.month.toString().padLeft(2, '0')}"
                        ".${dt.year}";
                    final timeStr =
                        "${dt.hour.toString().padLeft(2, '0')}"
                        ":${dt.minute.toString().padLeft(2, '0')}";

                    final title = (data['title'] ?? "Appointment").toString();
                    final location = (data['location'] ?? "").toString();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title),
                        Text("$dateStr • $timeStr"),
                        if (location.isNotEmpty) Text("Location: $location"),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}