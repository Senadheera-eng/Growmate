// care_tip_tracking_model.dart

class CareTip {
  final String id;
  final String title;
  final String description;
  final String category; // 'watering', 'pest', 'fertilization'
  final int minimumAge; // in months
  final int maximumAge; // in months
  final String source; // API source or reference

  CareTip({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.minimumAge,
    required this.maximumAge,
    required this.source,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'minimumAge': minimumAge,
      'maximumAge': maximumAge,
      'source': source,
    };
  }

  factory CareTip.fromMap(Map<String, dynamic> map) {
    return CareTip(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      minimumAge: map['minimumAge']?.toInt() ?? 0,
      maximumAge: map['maximumAge']?.toInt() ?? 0,
      source: map['source'] ?? '',
    );
  }
}

class CareTipCompletion {
  final String id;
  final String tipId;
  final String treeId;
  final String userId;
  final DateTime completedDate;
  
  CareTipCompletion({
    required this.id,
    required this.tipId,
    required this.treeId,
    required this.userId,
    required this.completedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipId': tipId,
      'treeId': treeId,
      'userId': userId,
      'completedDate': completedDate.toIso8601String(),
    };
  }

  factory CareTipCompletion.fromMap(Map<String, dynamic> map) {
    return CareTipCompletion(
      id: map['id'] ?? '',
      tipId: map['tipId'] ?? '',
      treeId: map['treeId'] ?? '',
      userId: map['userId'] ?? '',
      completedDate: DateTime.parse(map['completedDate']),
    );
  }
}