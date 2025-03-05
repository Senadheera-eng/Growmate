import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class TFLiteModel {
  late Interpreter _interpreter;
  final List<String> _labels = ["Drying", "Healthy", "Yellowing"];


  /// Loads the TFLite model from assets
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/model.tflite',
        options: InterpreterOptions()..threads = 4,
      );
      print("TFLite Model Loaded Successfully");

      // Print model input and output details for debugging
      printModelDetails();
    } catch (e) {
      print("Error loading model: $e");
      rethrow;
    }
  }

  void printModelDetails() {
    final inputTensor = _interpreter.getInputTensor(0);
    final outputTensor = _interpreter.getOutputTensor(0);

    print("===== Model Tensor Details =====");
    print("Input Tensor:");
    print("  Shape: ${inputTensor.shape}");
    print("  Type: ${inputTensor.type}");
    print("  Dimensions: ${inputTensor.shape.length}");

    print("\nOutput Tensor:");
    print("  Shape: ${outputTensor.shape}");
    print("  Type: ${outputTensor.type}");
    print("  Dimensions: ${outputTensor.shape.length}");

    // If possible, add more details about the tensor
    try {
      // print("  Quantization Zero Point: ${outputTensor.quantizationZeroPoint}");
      //print("  Quantization Scale: ${outputTensor.quantizationScale}");
    } catch (e) {
      print("  Additional tensor details not available");
    }
  }

  Future<String> processImage(File imageFile) async {
    try {
      // Read the image file
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        return "Error: Could not decode image";
      }

      // Resize image to 640x640 as required by the model
      final resizedImage = img.copyResize(
        image,
        width: 640,
        height: 640,
        interpolation: img.Interpolation.linear,
      ); 
      


      // Convert image to input tensor format (normalized float values)
      final input = imageToByteList(resizedImage);

      // Prepare output buffer - ensure it matches the model's output shape
      final output = List.generate(1, (_) => List.filled(3, 0.0));

      // Before running inference, print details about input
      print("\n===== Input Tensor Details =====");
      print(
          "Input Shape: ${input.length}, ${input[0].length}, ${input[0][0].length}, ${input[0][0][0].length}");
      print("Sample Input Values:");
      print("  First pixel R: ${input[0][0][0][0]}");
      print("  First pixel G: ${input[0][0][0][1]}");
      print("  First pixel B: ${input[0][0][0][2]}");

      // Run inference
      _interpreter.run(input, output);

      // Debug print of raw outputs
      print('\n===== Model Output =====');
      print('Raw Model Outputs: $output');
      print('Raw Probabilities:');
      for (int i = 0; i < _labels.length; i++) {
        print(
            '${_labels[i]}: ${output[0][i]} (${(output[0][i] * 100).toStringAsFixed(4)}%)');
      }

      // Process the results
      return processResults(output[0]);
    } catch (e) {
      print("Error processing image: $e");
      return "Error analyzing the image: ${e.toString()}";
    }
  }

  /// Convert image to normalized input tensor
  List<List<List<List<double>>>> imageToByteList(img.Image image) {
    // Create a 4D input tensor [1, 640, 640, 3]
    final input = List.generate(
      1, // Batch size of 1
      (_) => List.generate(
        640, // Height
        (_) => List.generate(
          640, // Width
          (_) => List.filled(3, 0.0), // 3 channels for RGB
        ),
      ),
    );

    // Fill the tensor with normalized RGB values
    for (int y = 0; y < 640; y++) {
      for (int x = 0; x < 640; x++) {
        final pixel = image.getPixel(x, y);

        input[0][y][x][0] = pixel.r / 255.0;
        input[0][y][x][1] = pixel.g / 255.0;
        input[0][y][x][2] = pixel.b / 255.0;
      }
    }

    return input;
  }

  String processResults(List<double> output) {
    // Find the index with highest probability
    int bestIndex = 0;
    double bestScore = output[0];

    for (int i = 1; i < output.length; i++) {
      if (output[i] > bestScore) {
        bestIndex = i;
        bestScore = output[i];
      }
    }

    // Get the leaf condition based on the index
    final condition = _labels[bestIndex];

    // Format result with condition and confidence percentage
    final confidence = bestScore * 100;

    // Append care suggestions based on the condition
    String result =
        "Leaf Status: $condition (${confidence.toStringAsFixed(1)}% confidence)\n\n";

    // Add care recommendations based on the detected condition
    if (bestIndex == 0) {
      // Healthy
      result += "Your leaf appears healthy! Continue with regular care:\n"
          "• Water regularly but avoid overwatering\n"
          "• Ensure adequate sunlight\n"
          "• Maintain proper fertilization schedule";
    } else if (bestIndex == 1) {
      // Yellowing
      result += "Your leaf is yellowing. Possible causes:\n"
          "• Overwatering or poor drainage\n"
          "• Nutrient deficiency (especially nitrogen)\n"
          "• Insufficient light\n\n"
          "Recommendations:\n"
          "• Check soil moisture and adjust watering\n"
          "• Consider a balanced fertilizer\n"
          "• Move to a brighter location if needed";
    } else {
      // Drying
      result += "Your leaf is drying. Possible causes:\n"
          "• Underwatering\n"
          "• Too much direct sunlight\n"
          "• Low humidity or high temperatures\n\n"
          "Recommendations:\n"
          "• Increase watering frequency\n"
          "• Move away from direct, harsh sunlight\n"
          "• Consider increasing humidity around the plant";
    }

    return result;
  }

  /// Close the interpreter when not needed
  void close() {
    _interpreter.close();
    print("TFLite Interpreter Closed");
  }
}
