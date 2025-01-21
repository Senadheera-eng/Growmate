// tree_model.dart
class TreeModel {
  final String id;
  final String name;
  final int ageInMonths;
  final List<String> photoUrls;
  final bool isDiseased;
  final String? diseaseDescription;
  final String? diseaseId;  // Links to specific disease
  final String? location;
  final String userId;
  final DateTime? diseaseIdentifiedDate;

  TreeModel({
    required this.id,
    required this.name,
    required this.ageInMonths,
    required this.photoUrls,
    required this.isDiseased,
    this.diseaseDescription,
    this.diseaseId,
    this.location,
    required this.userId,
    this.diseaseIdentifiedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ageInMonths': ageInMonths,
      'photoUrls': photoUrls,
      'isDiseased': isDiseased,
      'diseaseDescription': diseaseDescription,
      'diseaseId': diseaseId,
      'location': location,
      'userId': userId,
      'diseaseIdentifiedDate': diseaseIdentifiedDate?.toIso8601String(),
    };
  }

  factory TreeModel.fromMap(Map<String, dynamic> map) {
    return TreeModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      ageInMonths: map['ageInMonths']?.toInt() ?? 0,
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      isDiseased: map['isDiseased'] ?? false,
      diseaseDescription: map['diseaseDescription'],
      diseaseId: map['diseaseId'],
      location: map['location'],
      userId: map['userId'] ?? '',
      diseaseIdentifiedDate: map['diseaseIdentifiedDate'] != null 
          ? DateTime.parse(map['diseaseIdentifiedDate']) 
          : null,
    );
  }
}