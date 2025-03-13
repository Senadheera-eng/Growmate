// disease_model.dart
class DiseaseModel {
  final String id;
  final String name;
  final String description;
  final List<String> symptoms;
  final List<String> treatments;
  final int minimumAge;
  final int maximumAge;
  final String severity; // 'low', 'medium', 'high'
  final List<String> preventiveMeasures;

  DiseaseModel({
    required this.id,
    required this.name,
    required this.description,
    required this.symptoms,
    required this.treatments,
    required this.minimumAge,
    required this.maximumAge,
    required this.severity,
    required this.preventiveMeasures,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'symptoms': symptoms,
      'treatments': treatments,
      'minimumAge': minimumAge,
      'maximumAge': maximumAge,
      'severity': severity,
      'preventiveMeasures': preventiveMeasures,
    };
  }

  factory DiseaseModel.fromMap(Map<String, dynamic> map) {
    return DiseaseModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      symptoms: List<String>.from(map['symptoms'] ?? []),
      treatments: List<String>.from(map['treatments'] ?? []),
      minimumAge: map['minimumAge']?.toInt() ?? 0,
      maximumAge: map['maximumAge']?.toInt() ?? 0,
      severity: map['severity'] ?? 'medium',
      preventiveMeasures: List<String>.from(map['preventiveMeasures'] ?? []),
    );
  }
}