import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class PlantDiseaseDetector {
  Interpreter? _interpreter;
  List<String>? _labels;

  // Model configurations
  final int inputSize = 224; // Typical input size for many image models
  final int numClasses = 38; // Number of plant diseases your model can detect

  // Initialize the TFLite interpreter
  Future<void> initialize() async {
    try {
      // Load model
      final interpreterOptions = InterpreterOptions();

      // Load model from assets
      final modelData = await rootBundle.load('assets/model.tflite');
      final buffer = modelData.buffer;
      final model = buffer.asUint8List();

      _interpreter =
          await Interpreter.fromBuffer(model, options: interpreterOptions);
      print('Interpreter loaded successfully');

      // Load labels
      try {
        final labelData = await rootBundle.loadString('assets/labels.txt');
        _labels = labelData.split('\n');
        print('Model initialized with ${_labels?.length} labels');
      } catch (e) {
        print('Error loading labels: $e');
        // Create dummy labels if we can't load the file
        _labels = List.generate(numClasses, (index) => 'Class $index');
      }
    } catch (e) {
      print('Error initializing model: $e');
      rethrow;
    }
  }

  // Process image and detect disease
  Future<Map<String, dynamic>> detectDisease(File imageFile) async {
    if (_interpreter == null) {
      await initialize();
    }

    // Process the image
    final inputArray = await _loadImage(imageFile);

    // Run inference
    final outputBuffer = [List<double>.filled(numClasses, 0)];

    try {
      _interpreter!.run(inputArray, outputBuffer);

      // Process results
      final result = _processOutput(outputBuffer[0]);
      return result;
    } catch (e) {
      print('Error during inference: $e');
      rethrow;
    }
  }

  // Load and preprocess the image
  Future<List<List<List<List<double>>>>> _loadImage(File imageFile) async {
    // Read file as bytes
    final imageBytes = await imageFile.readAsBytes();

    // Decode the image
    final codec = await ui.instantiateImageCodec(
      imageBytes,
      targetWidth: inputSize,
      targetHeight: inputSize,
    );
    final frameInfo = await codec.getNextFrame();
    final ui.Image resizedImage = frameInfo.image;

    // Convert to byte data
    final byteData =
        await resizedImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) {
      throw Exception('Failed to convert image to bytes');
    }

    // Convert to float tensor and normalize
    final buffer = Float32List(1 * inputSize * inputSize * 3);
    int pixelIndex = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final int offset = (y * inputSize + x) * 4; // RGBA
        buffer[pixelIndex++] = byteData.getUint8(offset) / 255.0; // R
        buffer[pixelIndex++] = byteData.getUint8(offset + 1) / 255.0; // G
        buffer[pixelIndex++] = byteData.getUint8(offset + 2) / 255.0; // B
        // Ignore Alpha
      }
    }

    // Reshape to required dimensions [1, height, width, channels]
    final reshapedTensor = Float32List(1 * inputSize * inputSize * 3);
    reshapedTensor.setAll(0, buffer);

    // Create a 4D tensor of shape [1, height, width, channels]
    final result = List.generate(
      1,
      (i) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) => List.generate(
            3,
            (c) => reshapedTensor[(y * inputSize + x) * 3 + c],
          ),
        ),
      ),
    );

    return result;
  }

  // Process model output to get predictions
  Map<String, dynamic> _processOutput(List<double> output) {
    // Find index of max value
    int maxIndex = 0;
    double maxScore = output[0];

    for (int i = 1; i < output.length; i++) {
      if (output[i] > maxScore) {
        maxScore = output[i];
        maxIndex = i;
      }
    }

    // Create sorted list of results
    final List<Map<String, dynamic>> results = [];
    for (int i = 0; i < output.length; i++) {
      if (i < _labels!.length) {
        results.add({
          'label': _labels![i],
          'confidence': output[i],
        });
      }
    }

    // Sort by confidence
    results.sort((a, b) =>
        (b['confidence'] as double).compareTo(a['confidence'] as double));

    // Return top result and all results
    return {
      'topResult': {
        'label': maxIndex < _labels!.length ? _labels![maxIndex] : 'Unknown',
        'confidence': maxScore,
      },
      'allResults': results.take(5).toList(), // Top 5 results
    };
  }

  // Dispose resources
  void dispose() {
    _interpreter?.close();
  }
}
