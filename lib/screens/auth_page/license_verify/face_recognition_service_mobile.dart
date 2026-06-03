





import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';

class FaceRecognitionService {
  Interpreter? _interpreter;

  // --- INIT MODEL ---
  Future<void> initModel() async {
    if (_interpreter != null) return;
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/mobile_face_net.tflite',
      );
      debugPrint("DEBUG: TFLite model loaded successfully.");
    } catch (e) {
      debugPrint("DEBUG: Failed to load model: $e");
    }
  }

  void close() {
    _interpreter?.close();
    _interpreter = null;
  }

  // --- MAIN INFERENCE FUNCTION ---
  Future<List<double>?> runInference(img.Image image) async {
    if (_interpreter == null) {
      await initModel();
    }

    if (_interpreter == null) {
      debugPrint("ERROR: Model not loaded into memory.");
      return null;
    }

    // ALWAYS RESIZE TO EXACT MODEL REQUIREMENTS (112x112)
    img.Image resizedInput = img.copyResize(image, width: 112, height: 112);

    // Initialize 4D Tensor Input: [1, 112, 112, 3]
    var input = List.generate(
      1,
          (_) => List.generate(
        112,
            (_) => List.generate(112, (_) => List.filled(3, 0.0)),
      ),
    );

    try {
      // Loop exactly through the bounds of the resized 112x112 matrix
      for (int y = 0; y < 112; y++) {
        for (int x = 0; x < 112; x++) {
          final pixel = resizedInput.getPixel(x, y); // FIXED: Using resizedInput instead of image

          // Normalize channels to [-1, 1] range as required by MobileFaceNet
          input[0][y][x][0] = (pixel.r.toDouble() - 127.5) / 128.0;
          input[0][y][x][1] = (pixel.g.toDouble() - 127.5) / 128.0;
          input[0][y][x][2] = (pixel.b.toDouble() - 127.5) / 128.0;
        }
      }

      // MobileFaceNet produces a 128-dimensional biometric embedding array vector
      //var output = List.generate(1, (_) => List.filled(128, 0.0));
      var output = List.filled(1 * 192, 0.0).reshape([1, 192]);

      debugPrint("DEBUG: Running TFLite interpreter execution loop...");
      _interpreter!.run(input, output);
      debugPrint("DEBUG: 🎉 Inference finished successfully!");

      return List<double>.from(output[0]);
    } catch (e) {
      debugPrint("ERROR during inference array parsing: $e");
      return null;
    }
  }

  // --- FACE DETECTION + CROP EXTRACTION ---
  Future<List<double>?> extractFaceEmbedding(XFile file, {required bool isDocument}) async {
    FaceDetector? faceDetector;
    try {
      final options = FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: isDocument ? 0.05 : 0.1,
      );

      faceDetector = FaceDetector(options: options);
      final inputImage = InputImage.fromFilePath(file.path);

      debugPrint("DEBUG: Processing ML Kit Image Detection...");
      final faces = await faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        debugPrint("DEBUG: ❌ ML Kit found ZERO faces.");
        await faceDetector.close();
        return null;
      }

      debugPrint("DEBUG: Found ${faces.length} face(s). Extracting boundaries...");
      final face = faces.first;
      final rect = face.boundingBox;

      final bytes = await File(file.path).readAsBytes();
      img.Image? decoded = img.decodeImage(bytes);

      if (decoded == null) {
        debugPrint("DEBUG: ❌ Image library failed to decode raw bytes.");
        await faceDetector.close();
        return null;
      }

      // Safe bound bounding-box calculations to avoid canvas sizing errors
      int x = rect.left.toInt().clamp(0, decoded.width - 1);
      int y = rect.top.toInt().clamp(0, decoded.height - 1);
      int w = rect.width.toInt().clamp(1, decoded.width - x);
      int h = rect.height.toInt().clamp(1, decoded.height - y);

      debugPrint("DEBUG: Cropping image zone: x=$x, y=$y, w=$w, h=$h");
      img.Image cropped = img.copyCrop(
        decoded,
        x: x,
        y: y,
        width: w,
        height: h,
      );

      await faceDetector.close();
      return await runInference(cropped);
    } catch (e) {
      debugPrint("Face extraction error pipeline: $e");
      if (faceDetector != null) await faceDetector.close();
      return null;
    }
  }
}



/*import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceRecognitionService {
  Interpreter? _interpreter;

  // INIT MODEL
  Future<void> initModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/mobile_face_net.tflite',
      );

      debugPrint("DEBUG: TFLite model loaded successfully.");
    } catch (e) {
      debugPrint("DEBUG: Failed to load model: $e");
    }
  }

  void close() {
    _interpreter?.close();
  }

  // MAIN INFERENCE FUNCTION
  Future<List<double>?> runInference(img.Image image) async {
    if (_interpreter == null) {
      await initModel();
    }

    if (_interpreter == null) {
      debugPrint("ERROR: Model not loaded.");
      return null;
    }

    // ALWAYS RESIZE FIRST (CRITICAL FIX)
    img.Image inputImage = img.copyResize(image, width: 112, height: 112);

    var input = List.generate(
      1,
          (_) => List.generate(
        112,
            (_) => List.generate(112, (_) => List.filled(3, 0.0)),
      ),
    );

    try {
      for (int y = 0; y < 112; y++) {
        for (int x = 0; x < 112; x++) {
          final pixel = inputImage.getPixel(x, y);

          input[0][y][x][0] =
              (pixel.r.toDouble() - 127.5) / 128.0;
          input[0][y][x][1] =
              (pixel.g.toDouble() - 127.5) / 128.0;
          input[0][y][x][2] =
              (pixel.b.toDouble() - 127.5) / 128.0;
        }
      }

      var output = List.generate(1, (_) => List.filled(128, 0.0));

      _interpreter!.run(input, output);

      return List<double>.from(output[0]);
    } catch (e) {
      debugPrint("ERROR during inference: $e");
      return null;
    }
  }

  // FACE DETECTION + EXTRACTION
  Future<List<double>?> extractFaceEmbedding(
      XFile file, {
        required bool isDocument,
      }) async {
    try {
      final options = FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.01,
        enableLandmarks: false,
        enableContours: false,
      );

      final faceDetector = FaceDetector(options: options);

      final inputImage = InputImage.fromFilePath(file.path);

      final faces = await faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        await faceDetector.close();
        debugPrint("No face detected.");
        return null;
      }

      final face = faces.first;

      final bytes = await file.readAsBytes();
      img.Image? decoded = img.decodeImage(bytes);

      if (decoded == null) {
        await faceDetector.close();
        return null;
      }

      // Crop face safely
      final rect = face.boundingBox;

      int x = rect.left.toInt().clamp(0, decoded.width - 1);
      int y = rect.top.toInt().clamp(0, decoded.height - 1);
      int w = rect.width.toInt().clamp(1, decoded.width - x);
      int h = rect.height.toInt().clamp(1, decoded.height - y);

      img.Image cropped = img.copyCrop(
        decoded,
        x: x,
        y: y,
        width: w,
        height: h,
      );

      img.Image resized = img.copyResize(cropped, width: 112, height: 112);

      await faceDetector.close();

      return runInference(resized);
    } catch (e) {
      debugPrint("Face extraction error: $e");
      return null;
    }
  }


  // DISTANCE CALCULATION
  double calculateDistance(List<double> e1, List<double> e2) {
    if (e1.length != e2.length) return 999.0;

    double sum = 0;

    for (int i = 0; i < e1.length; i++) {
      double diff = e1[i] - e2[i];
      sum += diff * diff;
    }

    return sum;
  }
}
*/





/*import 'package:flutter/foundation.dart';
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

  Future<List<double>?> runInference(img.Image image) async {
    // FALLBACK: If interpreter hasn't finished initializing yet, load it right now!
    if (_interpreter == null) {
      debugPrint("DEBUG: Interpreter was null. Attempting on-the-fly lazy initialization...");
      await initModel();
    }

    // Double check safety line
    if (_interpreter == null) {
      debugPrint("DEBUG: ❌ Inference failed because model asset could not be loaded into memory.");
      return null;
    }

    var input = List.generate(
      1,
          (_) => List.generate(
        112,
            (_) => List.generate(112, (_) => List.filled(3, 0.0)),
      ),
    );

    try {
      int targetWidth = image.width;
      int targetHeight = image.height;

      for (int y = 0; y < targetHeight; y++) {
        for (int x = 0; x < targetWidth; x++) {
          final pixel = image.getPixel(x, y);
          input[0][y][x][0] = (pixel.r.toDouble() - 127.5) / 128.0;
          input[0][y][x][1] = (pixel.g.toDouble() - 127.5) / 128.0;
          input[0][y][x][2] = (pixel.b.toDouble() - 127.5) / 128.0;
        }
      }

      var output = List.generate(1, (_) => List.filled(128, 0.0));

      debugPrint("DEBUG: Running TFLite interpreter execution loop...");
      _interpreter!.run(input, output);

      debugPrint("DEBUG: 🎉 Inference finished successfully!");
      return List<double>.from(output[0]);

    } catch (e) {
      debugPrint("DEBUG: 🚨 Matrix parsing or inference runtime error: $e");
      return null;
    }
  }

}
*/