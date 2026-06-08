import 'package:flutter/material.dart';
import '../models/pet_model.dart';
import '../services/ai_recommendation_service.dart';
import '../forms/add_appointment_screen.dart';

class AiRecommendationsScreen extends StatefulWidget {
  final Pet pet;

  const AiRecommendationsScreen({
    super.key,
    required this.pet,
  });

  @override
  State<AiRecommendationsScreen> createState() =>
      _AiRecommendationsScreenState();
}

class _AiRecommendationsScreenState extends State<AiRecommendationsScreen> {
  bool loading = true;
  String recommendation = '';

  @override
  void initState() {
    super.initState();
    loadRecommendations();
  }

  Future<void> loadRecommendations() async {
    try {
      final result =
      await AiRecommendationService().generatePetRecommendations(widget.pet);

      setState(() {
        recommendation = result;
        loading = false;
      });
    } catch (e) {
      setState(() {
        recommendation = 'AI error: $e';
        loading = false;
      });
    }
  }

  void addAsReminder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAppointmentScreen(
          petId: widget.pet.id,
          initialTitle: 'AI Care Reminder',
          initialNotes: recommendation,
        ),
      ),
    );
  }

  String cleanText(String text) {
    return text
        .replaceAll('**', '')
        .replaceAll('*', '•')
        .replaceAll('#', '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final cleanRecommendation = cleanText(recommendation);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('AI Recommendations ✨'),
        backgroundColor: Colors.blue.shade50,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade300,
                  Colors.green.shade300,
                ],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🐾 AI Health Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Personalized recommendations for ${widget.pet.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _RecommendationCard(
            icon: Icons.restaurant,
            title: 'Food & Feeding',
            color: Colors.orange.shade100,
            text: _extractSection(
              cleanRecommendation,
              ['Food', 'Feeding'],
            ),
          ),

          _RecommendationCard(
            icon: Icons.vaccines,
            title: 'Vaccines',
            color: Colors.blue.shade100,
            text: _extractSection(
              cleanRecommendation,
              ['Vaccine'],
            ),
          ),

          _RecommendationCard(
            icon: Icons.health_and_safety,
            title: 'Care Reminders',
            color: Colors.green.shade100,
            text: _extractSection(
              cleanRecommendation,
              ['Care', 'Grooming', 'Dental', 'Exercise'],
            ),
          ),

          _RecommendationCard(
            icon: Icons.notes,
            title: 'Full AI Recommendation',
            color: Colors.purple.shade50,
            text: cleanRecommendation,
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: addAsReminder,
              icon: const Icon(Icons.add_alert),
              label: const Text(
                'Add recommendation as reminder',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _extractSection(String text, List<String> keywords) {
    final lines = text.split('\n');

    final filtered = lines.where((line) {
      final lower = line.toLowerCase();
      return keywords.any((k) => lower.contains(k.toLowerCase()));
    }).toList();

    if (filtered.isEmpty) {
      return 'No specific recommendation found.';
    }

    return filtered.join('\n');
  }
}

class _RecommendationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final String text;

  const _RecommendationCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    text,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}