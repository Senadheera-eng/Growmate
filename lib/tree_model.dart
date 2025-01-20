class TreeModel {
  final String id;
  final String name;
  final int ageInMonths;
  final List<String> photoUrls;
  final bool isDiseased;
  final String? diseaseDescription;
  final String? location;
  final DateTime plantedDate;
  final String userId;
  final DateTime lastUpdated;

  TreeModel({
    required this.id,
    required this.name,
    required this.ageInMonths,
    required this.photoUrls,
    required this.isDiseased,
    this.diseaseDescription,
    this.location,
    required this.plantedDate,
    required this.userId,
    required this.lastUpdated,
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
      'plantedDate': plantedDate.toIso8601String(),
      'userId': userId,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory TreeModel.fromMap(Map<String, dynamic> map) {
    return TreeModel(
      id: map['id'],
      name: map['name'],
      ageInMonths: map['ageInMonths'],
      photoUrls: List<String>.from(map['photoUrls']),
      isDiseased: map['isDiseased'],
      diseaseDescription: map['diseaseDescription'],
      location: map['location'],
      plantedDate: DateTime.parse(map['plantedDate']),
      userId: map['userId'],
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }
}