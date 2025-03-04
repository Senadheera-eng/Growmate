/* import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ImageProcessingHelper {
  // Preprocess image for TFLite model
  static Future<List<List<double>>> processImage(File imageFile, {
    int inputWidth = 224,  // Adjust based on your model's input size
    int inputHeight = 224, // Adjust based on your model's input size
  }) async {
    try {
      // Read the image file
      final bytes = await imageFile.readAsBytes();
      
      // Decode the image
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize image
      img.Image resizedImage = img.copyResize(
        image, 
        width: inputWidth, 
        height: inputHeight
      );

      // Normalize image (convert to float and scale)
      List<List<double>> inputImage = List.generate(
        inputHeight, 
        (y) => List.generate(
          inputWidth, 
          (x) {
            final pixel = resizedImage.getPixel(x, y);
            
            // Normalize pixel values (0-1 range)
            // Adjust normalization based on your model's requirements
            return (img.getRed(pixel) / 255.0 - 0.5) * 2.0;    // R channel
          }
        )
      );

      return inputImage;
    } catch (e) {
      print('Image processing error: $e');
      rethrow;
    }
  }

  // Run inference with the processed image
  static Future<List<double>> runInference(
    Interpreter interpreter, 
    List<List<double>> inputImage
  ) async {
    try {
      // Prepare output tensor
      // Adjust output shape based on your model's output
      final outputTensor = List.filled(1 * 5, 0.0).reshape([1, 5]);

      // Run inference
      interpreter.run(inputImage, outputTensor);

      // Convert output to list of doubles
      return outputTensor[0].cast<double>();
    } catch (e) {
      print('Inference error: $e');
      rethrow;
    }
  }
} */