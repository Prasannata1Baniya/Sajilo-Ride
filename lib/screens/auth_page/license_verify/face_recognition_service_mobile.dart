import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceRecognitionService {
  Interpreter? _interpreter;

  Future<void> initModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/mobile_face_net.tflite');
      debugPrint("DEBUG: TFLite Face Recognition Model loaded successfully on Mobile.");
    } catch (e) {
      debugPrint("DEBUG: Failed to load TFLite model on Mobile: $e");
    }
  }

  void close() {
    _interpreter?.close();
  }

  List<double>? runInference(img.Image image) {
    if (_interpreter == null) return null;

    var convertedBytes = Float32List(1 * 112 * 112 * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        var pixel = image.getPixel(x, y);
        buffer[pixelIndex++] = (pixel.r - 127.5) / 127.5;
        buffer[pixelIndex++] = (pixel.g - 127.5) / 127.5;
        buffer[pixelIndex++] = (pixel.b - 127.5) / 127.5;
      }
    }

    var input = convertedBytes.reshape([1, 112, 112, 3]);
    var output = List.filled(1 * 128, 0.0).reshape([1, 128]);

    _interpreter!.run(input, output);
    return List<double>.from(output[0]);
  }
}