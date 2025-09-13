import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final List<String> semesterIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.semesterIds,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory AppUser.create({
    required String uid,
    required String email,
    String? displayName,
    String? photoURL,
  }) {
    final now = DateTime.now();
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      semesterIds: [],
      createdAt: now,
      updatedAt: now,
      isActive: true,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
      semesterIds: List<String>.from(json['semesterIds'] ?? []),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'semesterIds': semesterIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser.fromJson(data);
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    List<String>? semesterIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      semesterIds: semesterIds ?? List.from(this.semesterIds),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }

  // Add semester ID to user's semester list
  AppUser addSemester(String semesterId) {
    if (!semesterIds.contains(semesterId)) {
      final updatedSemesterIds = List<String>.from(semesterIds)..add(semesterId);
      return copyWith(semesterIds: updatedSemesterIds);
    }
    return this;
  }

  // Remove semester ID from user's semester list
  AppUser removeSemester(String semesterId) {
    final updatedSemesterIds = semesterIds.where((id) => id != semesterId).toList();
    return copyWith(semesterIds: updatedSemesterIds);
  }

  // Get user's initials for avatar
  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      final names = displayName!.trim().split(' ');
      if (names.length >= 2) {
        return '${names.first[0]}${names.last[0]}'.toUpperCase();
      }
      return displayName![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  // Get display name or fallback to email
  String get nameOrEmail => displayName?.isNotEmpty == true ? displayName! : email;

  @override
  String toString() {
    return 'AppUser(uid: $uid, email: $email, displayName: $displayName, semesterIds: $semesterIds)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
