// tree_model.dart
class TreeModel {
  final String id;
  final String name;
  final int ageInMonths;
  final List<String> photoUrls;
  final bool isDiseased;
  final String? diseaseDescription;
  final String? location;
  final String userId;

  TreeModel({
    required this.id,
    required this.name,
    required this.ageInMonths,
    required this.photoUrls,
    required this.isDiseased,
    this.diseaseDescription,
    this.location,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ageInMonths': ageInMonths,
      'photoUrls': photoUrls,
      'isDiseased': isDiseased,
      'diseaseDescription': diseaseDescription,
      'location': location,
      'userId': userId,
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
      location: map['location'],
      userId: map['userId'] ?? '',
    );
  }
}