import 'dart:io';
import 'package:flutter/material.dart';

class DragAndDropSection extends StatelessWidget {
  final Function()? onGalleryTap;
  final Function()? onCameraTap;
  final String resultText;
  final bool isProcessing;
  final File? selectedImage;

  const DragAndDropSection({
    Key? key,
    this.onGalleryTap,
    this.onCameraTap,
    this.resultText = "",
    this.isProcessing = false,
    this.selectedImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildAnalysisCard(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 16, left: 20, right: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00C853),
            Color(0xFF1B5E20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C853).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Detect Tree Issues',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Upload your tree photo for analysis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Add these methods to your DragAndDropSection class to fix the overflow issue

  Widget _buildResultDisplay(String resultText) {
    bool isHealthy = resultText.toLowerCase().contains('leaf status: healthy');
    bool isYellowing =
        resultText.toLowerCase().contains('leaf status: yellowing');
    bool isDrying = resultText.toLowerCase().contains('leaf status: drying');

    // Determine the icon and color based on condition
    IconData statusIcon;
    Color statusColor;
    String statusTitle;

    if (isHealthy) {
      statusIcon = Icons.check_circle_outlined;
      statusColor = const Color(0xFF00C853);
      statusTitle = "Healthy";
    } else if (isYellowing) {
      statusIcon = Icons.warning_amber_outlined;
      statusColor = Colors.amber;
      statusTitle = "Yellowing Detected";
    } else if (isDrying) {
      statusIcon = Icons.water_drop_outlined;
      statusColor = Colors.orange;
      statusTitle = "Drying Detected";
    } else {
      statusIcon = Icons.info_outline;
      statusColor = Colors.blue;
      statusTitle = "Analysis Complete";
    }

    // Extract confidence percentage if available
    String confidenceText = "";
    final RegExp confidenceRegex = RegExp(r'\((\d+\.\d+)% confidence\)');
    final match = confidenceRegex.firstMatch(resultText);
    if (match != null && match.groupCount >= 1) {
      confidenceText = "${match.group(1)}%";
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      "Tree Health Analysis",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 24),

          // Analysis details - showing the confidence score
          if (confidenceText.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.analytics_outlined,
                        color: Color(0xFF00C853),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Analysis Details",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Confidence indicator - with fixed layout
                _buildIndicatorItem(
                  icon: isHealthy
                      ? Icons.check_circle_outlined
                      : isYellowing
                          ? Icons.warning_amber_outlined
                          : isDrying
                              ? Icons.water_drop_outlined
                              : Icons.info_outline,
                  label: statusTitle,
                  percentage: confidenceText,
                  color: statusColor,
                ),

                const SizedBox(height: 16),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Text(
                resultText,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade800,
                ),
              ),
            ),

          // Recommendation box
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00C853).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline,
                        color: Color(0xFF00C853),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Recommendations",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildRecommendationItem(isHealthy, isYellowing, isDrying),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorItem({
    required IconData icon,
    required String label,
    required String percentage,
    required Color color,
  }) {
    // Convert percentage string to double for progress indicator
    double percentValue = double.tryParse(percentage.replaceAll('%', '')) ?? 0;
    percentValue = percentValue / 100; // Convert to 0-1 range

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status and percentage in first row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                percentage,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),

          // Progress bar in second row
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentValue,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(
      bool isHealthy, bool isYellowing, bool isDrying) {
    List<Map<String, dynamic>> recommendations = [];

    if (isHealthy) {
      recommendations = [
        {
          'icon': Icons.water_drop,
          'text': "Water regularly but avoid overwatering"
        },
        {'icon': Icons.wb_sunny, 'text': "Ensure adequate sunlight"},
        {'icon': Icons.spa, 'text': "Maintain proper fertilization schedule"}
      ];
    } else if (isYellowing) {
      recommendations = [
        {
          'icon': Icons.water,
          'text': "Check soil moisture and adjust watering"
        },
        {'icon': Icons.spa, 'text': "Consider a balanced fertilizer"},
        {
          'icon': Icons.wb_sunny,
          'text': "Move to a brighter location if needed"
        }
      ];
    } else if (isDrying) {
      recommendations = [
        {'icon': Icons.water_drop, 'text': "Increase watering frequency"},
        {
          'icon': Icons.wb_sunny_outlined,
          'text': "Move away from direct, harsh sunlight"
        },
        {
          'icon': Icons.water,
          'text': "Consider increasing humidity around the plant"
        }
      ];
    } else {
      recommendations = [
        {
          'icon': Icons.eco,
          'text':
              "Ensure regular care for your tree with proper watering, sunlight, and nutrients."
        }
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: recommendations.map((recommendation) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00C853).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  recommendation['icon'],
                  color: const Color(0xFF00C853),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  recommendation['text'],
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF1B5E20),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProcessingStatus() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Animated progress indicator
          Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(40),
            ),
            child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(const Color(0xFF00C853)),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),

          // Processing text
          Text(
            "Analyzing your tree...",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "We're examining leaf color, patterns, and health indicators",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Processing steps
          _buildProcessingStep(
            "Loading TensorFlow model",
            true,
          ),
          _buildProcessingStep(
            "Preprocessing image",
            true,
          ),
          _buildProcessingStep(
            "Analyzing leaf health",
            false,
          ),
          _buildProcessingStep(
            "Generating recommendations",
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingStep(String label, bool completed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFFE8F5E9) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: completed
              ? const Color(0xFF00C853).withOpacity(0.3)
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.timelapse,
            size: 18,
            color: completed ? const Color(0xFF00C853) : Colors.grey.shade400,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: completed ? FontWeight.w500 : FontWeight.normal,
                color: completed ? Colors.grey.shade800 : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Show selected image if available
                if (selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(
                        selectedImage!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                // Show result if available
                if (resultText.isNotEmpty)
                  Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isProcessing
                          ? _buildProcessingStatus()
                          : _buildResultDisplay(resultText)),

                // Upload section
                if (selectedImage == null)
                  Container(
                    height: 320,
                    child: _buildUploadSection(),
                  ),

                // Bottom buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _buildModernButton(
                          icon: Icons.photo_library_outlined,
                          label: "Gallery",
                          onTap: isProcessing ? null : onGalleryTap,
                          isPrimary: false,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildModernButton(
                          icon: Icons.camera_alt_outlined,
                          label: "Camera",
                          onTap: isProcessing ? null : onCameraTap,
                          isPrimary: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _extractPercentage(String text, String label) {
    final RegExp regex = RegExp('$label: .+? \\((.+?)\\%\\)');
    final match = regex.firstMatch(text);
    if (match != null && match.groupCount >= 1) {
      return '${match.group(1)}%';
    }
    return '';
  }

  List<String> _getPotentialCauses(
      bool isHealthy, bool isYellowing, bool isDrying) {
    if (isHealthy) {
      return [];
    } else if (isDrying) {
      return [
        "Underwatering",
        "Too much direct sunlight",
        "Low humidity or high temperatures"
      ];
    } else if (isYellowing) {
      return [
        "Overwatering or poor drainage",
        "Nutrient deficiency (especially nitrogen)",
        "Insufficient light"
      ];
    } else {
      return [];
    }
  }

  List<String> _getRecommendations(
      bool isHealthy, bool isYellowing, bool isDrying) {
    if (isHealthy) {
      return [
        "Water regularly but avoid overwatering",
        "Ensure adequate sunlight",
        "Maintain proper fertilization schedule"
      ];
    } else if (isDrying) {
      return [
        "Increase watering frequency",
        "Move away from direct, harsh sunlight",
        "Consider increasing humidity around the plant"
      ];
    } else if (isYellowing) {
      return [
        "Check soil moisture and adjust watering",
        "Consider a balanced fertilizer",
        "Move to a brighter location if needed"
      ];
    } else {
      return [];
    }
  }

  Widget _buildModernButton({
    required IconData icon,
    required String label,
    bool isPrimary = false,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: isPrimary ? const Color(0xFF00C853) : Colors.white,
      borderRadius: BorderRadius.circular(15),
      elevation: isProcessing ? 0 : 2,
      shadowColor: isPrimary
          ? const Color(0xFF00C853).withOpacity(0.3)
          : Colors.black.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withOpacity(0.2)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isPrimary ? Colors.white : const Color(0xFF00C853),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isPrimary ? Colors.white : const Color(0xFF424242),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.image_outlined,
              size: 34,
              color: const Color(0xFF00C853),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Drag and Drop Your Tree Image Here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF424242),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'or use the buttons below',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 210,
            height: 65,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      size: 22,
                      color: const Color(0xFF00C853),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Drop files here',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
