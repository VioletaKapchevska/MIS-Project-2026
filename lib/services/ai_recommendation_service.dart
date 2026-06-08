import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pet_model.dart';

class AiRecommendationService {

  static const String apiKey = 'AIzaSyA8lrtYEZiRHHkGsrNM3I7TA_nBakt5824';

  Future<String> generatePetRecommendations(Pet pet) async {

    final prompt = '''
Generate short and practical pet care recommendations.

Pet information:
Name: ${pet.name}
Type: ${pet.type}
Breed: ${pet.breed}
Age: ${pet.age}
Weight: ${pet.weight} kg

Include:
- Food recommendation
- Feeding frequency
- Vaccine suggestions
- Care reminders

Keep recommendations short.
''';

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
    );

    final response = await http.post(
      url,

      headers: {
        'Content-Type': 'application/json',
      },

      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text": prompt
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      return data['candidates'][0]['content']['parts'][0]['text'];

    } else {
      throw Exception(
        'Failed: ${response.statusCode} - ${response.body}',
      );
    }
  }
}