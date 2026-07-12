import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, startup, admin }

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final UserRole role;
  final String? campus;
  final String? major;
  final String? yearOfStudy;
  final String? bio;
  final List<String> skills;
  final String? linkedInUrl;
  final String? portfolioUrl;
  final String? githubUrl;
  final bool isEmailVerified;
  final bool isProfileComplete;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.role,
    this.campus,
    this.major,
    this.yearOfStudy,
    this.bio,
    this.skills = const [],
    this.linkedInUrl,
    this.portfolioUrl,
    this.githubUrl,
    this.isEmailVerified = false,
    this.isProfileComplete = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isStudent => role == UserRole.student;
  bool get isStartup => role == UserRole.startup;
  bool get isAdmin => role == UserRole.admin;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      role: UserRole.values.firstWhere(
        (r) => r.toString().split('.').last == (data['role'] ?? 'student'),
        orElse: () => UserRole.student,
      ),
      campus: data['campus'],
      major: data['major'],
      yearOfStudy: data['yearOfStudy'],
      bio: data['bio'],
      skills: List<String>.from(data['skills'] ?? []),
      linkedInUrl: data['linkedInUrl'],
      portfolioUrl: data['portfolioUrl'],
      githubUrl: data['githubUrl'],
      isEmailVerified: data['isEmailVerified'] ?? false,
      isProfileComplete: data['isProfileComplete'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role.toString().split('.').last,
      'campus': campus,
      'major': major,
      'yearOfStudy': yearOfStudy,
      'bio': bio,
      'skills': skills,
      'linkedInUrl': linkedInUrl,
      'portfolioUrl': portfolioUrl,
      'githubUrl': githubUrl,
      'isEmailVerified': isEmailVerified,
      'isProfileComplete': isProfileComplete,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? campus,
    String? major,
    String? yearOfStudy,
    String? bio,
    List<String>? skills,
    String? linkedInUrl,
    String? portfolioUrl,
    String? githubUrl,
    bool? isEmailVerified,
    bool? isProfileComplete,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role,
      campus: campus ?? this.campus,
      major: major ?? this.major,
      yearOfStudy: yearOfStudy ?? this.yearOfStudy,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      linkedInUrl: linkedInUrl ?? this.linkedInUrl,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      githubUrl: githubUrl ?? this.githubUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
