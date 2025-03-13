class UserModel {
  final String id;
  final String? name;
  final String? email;
  final String? hometown;
  final String? phone;
  final String? profilePhotoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    this.name,
    this.email,
    this.hometown,
    this.phone,
    this.profilePhotoUrl,
    this.createdAt,
    this.updatedAt,
  });

  // Create a UserModel from a Firestore document
  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      name: data['name'],
      email: data['email'],
      hometown: data['hometown'],
      phone: data['phone'],
      profilePhotoUrl: data['profilePhotoUrl'],
      createdAt: data['createdAt']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
    );
  }

  // Convert UserModel to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'hometown': hometown,
      'phone': phone,
      'profilePhotoUrl': profilePhotoUrl,
      'updatedAt': DateTime.now(),
    };
  }

  // Create a copy of current UserModel with some fields modified
  UserModel copyWith({
    String? name,
    String? email,
    String? hometown,
    String? phone,
    String? profilePhotoUrl,
  }) {
    return UserModel(
      id: this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      hometown: hometown ?? this.hometown,
      phone: phone ?? this.phone,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
    );
  }
}