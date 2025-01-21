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
  final String? notes;
  final String? variety; // Type of coconut tree
  final Map<String, dynamic>? lastCareActions; // Track last care actions

  TreeModel({
    required this.id,
    required this.name,
    required this.ageInMonths,
    required this.photoUrls,
    required this.isDiseased,
    this.diseaseDescription,
    this.location,
    required this.userId,
    this.notes,
    this.variety,
    this.lastCareActions,
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
      'notes': notes,
      'variety': variety,
      'lastCareActions': lastCareActions ?? {},
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
      notes: map['notes'],
      variety: map['variety'],
      lastCareActions: Map<String, dynamic>.from(map['lastCareActions'] ?? {}),
    );
  }

  // Create a copy of the tree with updated fields
  TreeModel copyWith({
    String? id,
    String? name,
    int? ageInMonths,
    List<String>? photoUrls,
    bool? isDiseased,
    String? diseaseDescription,
    String? location,
    String? userId,
    String? notes,
    String? variety,
    Map<String, dynamic>? lastCareActions,
  }) {
    return TreeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ageInMonths: ageInMonths ?? this.ageInMonths,
      photoUrls: photoUrls ?? this.photoUrls,
      isDiseased: isDiseased ?? this.isDiseased,
      diseaseDescription: diseaseDescription ?? this.diseaseDescription,
      location: location ?? this.location,
      userId: userId ?? this.userId,
      notes: notes ?? this.notes,
      variety: variety ?? this.variety,
      lastCareActions: lastCareActions ?? this.lastCareActions,
    );
  }

  // Helper method to update last care action
  TreeModel updateLastCareAction(String category, DateTime date) {
    final updatedActions = Map<String, dynamic>.from(lastCareActions ?? {});
    updatedActions[category] = date.toIso8601String();
    return copyWith(lastCareActions: updatedActions);
  }

  // Helper method to get the last care action date for a category
  DateTime? getLastCareActionDate(String category) {
    final dateStr = lastCareActions?[category];
    if (dateStr != null) {
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Helper method to check if tree needs care based on frequency
  bool needsCare(String category, String frequency) {
    final lastAction = getLastCareActionDate(category);
    if (lastAction == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastAction);

    switch (frequency.toLowerCase()) {
      case 'daily':
      case 'once daily':
      case 'twice daily':
        return difference.inDays >= 1;
      case 'weekly':
        return difference.inDays >= 7;
      case 'bi-weekly':
        return difference.inDays >= 14;
      case 'monthly':
        return difference.inDays >= 30;
      case 'every 2 weeks':
        return difference.inDays >= 14;
      case 'every 3 weeks':
        return difference.inDays >= 21;
      case 'every other day':
        return difference.inDays >= 2;
      default:
        return true;
    }
  }

  // Helper method to calculate next care date
  DateTime calculateNextCareDate(String frequency) {
    final lastAction = getLastCareActionDate(frequency) ?? DateTime.now();
    
    switch (frequency.toLowerCase()) {
      case 'daily':
      case 'once daily':
      case 'twice daily':
        return lastAction.add(const Duration(days: 1));
      case 'weekly':
        return lastAction.add(const Duration(days: 7));
      case 'bi-weekly':
        return lastAction.add(const Duration(days: 14));
      case 'monthly':
        return lastAction.add(const Duration(days: 30));
      case 'every 2 weeks':
        return lastAction.add(const Duration(days: 14));
      case 'every 3 weeks':
        return lastAction.add(const Duration(days: 21));
      case 'every other day':
        return lastAction.add(const Duration(days: 2));
      default:
        return lastAction.add(const Duration(days: 1));
    }
  }
}