import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';

class AiTryOnService {
  final _model = FirebaseAI.googleAI(useLimitedUseAppCheckTokens: true)
      .generativeModel(
        model: 'gemini-3.1-flash-image',
        generationConfig: GenerationConfig(
          responseModalities: [
            ResponseModalities.text,
            ResponseModalities.image,
          ],
        ),
      );

  Future<Uint8List> generateStylePreview({
    required File originalPhoto,
    required String serviceName,
    required String serviceDescription,
  }) async {
    final imageBytes = await originalPhoto.readAsBytes();

    final prompt =
        '''
Toma la foto de esta persona y aplícale este estilo de barbería: "$serviceName" ($serviceDescription).
Mantén el rostro, la identidad, la expresión y el fondo de la foto original lo más fieles posible.
Cambia únicamente el cabello y/o la barba según el estilo descrito.
Genera una imagen fotorrealista, como si fuera una foto real.
''';

    final response = await _model.generateContent([
      Content.multi([
        TextPart(prompt),
        InlineDataPart('image/jpeg', imageBytes),
      ]),
    ]);

    for (final part in response.candidates.first.content.parts) {
      if (part is InlineDataPart) {
        return part.bytes;
      }
    }

    throw Exception('La IA no devolvió ninguna imagen. Intenta con otra foto.');
  }
}
