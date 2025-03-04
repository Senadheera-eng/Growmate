import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'tflite_service.dart';

class PlantDiseaseDetectionScreen extends StatefulWidget {
  const PlantDiseaseDetectionScreen({Key? key}) : super(key: key);

  @override
  _PlantDiseaseDetectionScreenState createState() =>
      _PlantDiseaseDetectionScreenState();
}

class _PlantDiseaseDetectionScreenState
    extends State<PlantDiseaseDetectionScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  final PlantDiseaseDetector _detector = PlantDiseaseDetector();
  bool _isProcessing = false;
  Map<String, dynamic>? _detectionResult;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _detector.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _detector.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle state changes for camera
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController = CameraController(
        _cameras![0], // Use the first camera (back camera)
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile imageXFile = await _cameraController!.takePicture();

      setState(() {
        _isProcessing = true;
        _imageFile = File(imageXFile.path);
      });

      // Process the captured image
      final result = await _detector.detectDisease(_imageFile!);

      setState(() {
        _detectionResult = result;
        _isProcessing = false;
      });
    } catch (e) {
      print('Error capturing image: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _pickImage() async {
    // Implementation for picking image from gallery
    // You would use image_picker package for this
    // This is where your existing code from drag_and_drop_section would integrate
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildCameraPreview(),
          _buildResultSection(),
        ],
      ),
      floatingActionButton: _buildActionButtons(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Expanded(
        flex: 3,
        child: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Expanded(
      flex: 3,
      child: _imageFile != null
          ? Image.file(_imageFile!, fit: BoxFit.cover)
          : CameraPreview(_cameraController!),
    );
  }

  Widget _buildResultSection() {
    return Expanded(
      flex: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: _isProcessing
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Analyzing your plant...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : _detectionResult != null
                ? _buildDetectionResults()
                : _buildInstructions(),
      ),
    );
  }

  Widget _buildInstructions() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.eco_rounded,
          size: 48,
          color: Colors.green.shade300,
        ),
        const SizedBox(height: 16),
        const Text(
          'Take a clear photo of the affected plant',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Position the camera so that the affected area is clearly visible',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDetectionResults() {
    final topResult = _detectionResult!['topResult'];
    final allResults = _detectionResult!['allResults'] as List<dynamic>;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detection Results',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topResult['label'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Confidence: ${(topResult['confidence'] * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  // Here you would add more information about the disease
                  // such as treatment options, cause, etc.
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Other Possibilities',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...allResults.skip(1).take(3).map((result) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      result['label'],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    '${(result['confidence'] * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _imageFile = null;
                  _detectionResult = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Scan Another Plant',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_imageFile == null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _buildActionButton(
              icon: Icons.photo_library_rounded,
              label: "Browse",
              onTap: _pickImage,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _buildActionButton(
              icon: Icons.camera_alt_rounded,
              label: "Take Photo",
              isPrimary: true,
              onTap: _captureImage,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    bool isPrimary = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isPrimary ? const Color(0xFF00C853) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 8,
      shadowColor:
          isPrimary ? const Color(0xFF00C853).withOpacity(0.5) : Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : const Color(0xFF00C853),
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : const Color(0xFF424242),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
