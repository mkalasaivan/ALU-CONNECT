import 'package:cloud_firestore/cloud_firestore.dart';

enum OpportunityStatus { open, closed, paused, draft }

class OpportunityModel {
  final String id;
  final String startupId;
  final String startupName;
  final String? startupLogoUrl;
  final bool startupIsVerified;
  final String title;
  final String description;
  final String type; // role type
  final List<String> requiredSkills;
  final List<String> preferredSkills;
  final String duration;
  final bool isPaid;
  final String? stipend;
  final String location; // remote, on-campus, hybrid
  final String campus;
  final int openings;
  final int applicantCount;
  final OpportunityStatus status;
  final DateTime? deadline;
  final List<String> responsibilities;
  final List<String> requirements;
  final String? applicationLink; // external if any
  final List<String> bookmarkedBy; // user UIDs
  final DateTime createdAt;
  final DateTime updatedAt;

  const OpportunityModel({
    required this.id,
    required this.startupId,
    required this.startupName,
    this.startupLogoUrl,
    this.startupIsVerified = false,
    required this.title,
    required this.description,
    required this.type,
    this.requiredSkills = const [],
    this.preferredSkills = const [],
    required this.duration,
    this.isPaid = false,
    this.stipend,
    this.location = 'remote',
    required this.campus,
    this.openings = 1,
    this.applicantCount = 0,
    this.status = OpportunityStatus.open,
    this.deadline,
    this.responsibilities = const [],
    this.requirements = const [],
    this.applicationLink,
    this.bookmarkedBy = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOpen => status == OpportunityStatus.open;
  bool get isExpired => deadline != null && deadline!.isBefore(DateTime.now());

  factory OpportunityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OpportunityModel(
      id: doc.id,
      startupId: data['startupId'] ?? '',
      startupName: data['startupName'] ?? '',
      startupLogoUrl: data['startupLogoUrl'],
      startupIsVerified: data['startupIsVerified'] ?? false,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? '',
      requiredSkills: List<String>.from(data['requiredSkills'] ?? []),
      preferredSkills: List<String>.from(data['preferredSkills'] ?? []),
      duration: data['duration'] ?? '',
      isPaid: data['isPaid'] ?? false,
      stipend: data['stipend'],
      location: data['location'] ?? 'remote',
      campus: data['campus'] ?? '',
      openings: data['openings'] ?? 1,
      applicantCount: data['applicantCount'] ?? 0,
      status: OpportunityStatus.values.firstWhere(
        (s) => s.toString().split('.').last == (data['status'] ?? 'open'),
        orElse: () => OpportunityStatus.open,
      ),
      deadline: (data['deadline'] as Timestamp?)?.toDate(),
      responsibilities: List<String>.from(data['responsibilities'] ?? []),
      requirements: List<String>.from(data['requirements'] ?? []),
      applicationLink: data['applicationLink'],
      bookmarkedBy: List<String>.from(data['bookmarkedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'startupId': startupId,
      'startupName': startupName,
      'startupLogoUrl': startupLogoUrl,
      'startupIsVerified': startupIsVerified,
      'title': title,
      'description': description,
      'type': type,
      'requiredSkills': requiredSkills,
      'preferredSkills': preferredSkills,
      'duration': duration,
      'isPaid': isPaid,
      'stipend': stipend,
      'location': location,
      'campus': campus,
      'openings': openings,
      'applicantCount': applicantCount,
      'status': status.toString().split('.').last,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'responsibilities': responsibilities,
      'requirements': requirements,
      'applicationLink': applicationLink,
      'bookmarkedBy': bookmarkedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  OpportunityModel copyWith({
    String? title,
    String? description,
    String? type,
    List<String>? requiredSkills,
    List<String>? preferredSkills,
    String? duration,
    bool? isPaid,
    String? stipend,
    String? location,
    int? openings,
    int? applicantCount,
    OpportunityStatus? status,
    DateTime? deadline,
    List<String>? responsibilities,
    List<String>? requirements,
    String? applicationLink,
    List<String>? bookmarkedBy,
    String? startupLogoUrl,
    bool? startupIsVerified,
  }) {
    return OpportunityModel(
      id: id,
      startupId: startupId,
      startupName: startupName,
      startupLogoUrl: startupLogoUrl ?? this.startupLogoUrl,
      startupIsVerified: startupIsVerified ?? this.startupIsVerified,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      preferredSkills: preferredSkills ?? this.preferredSkills,
      duration: duration ?? this.duration,
      isPaid: isPaid ?? this.isPaid,
      stipend: stipend ?? this.stipend,
      location: location ?? this.location,
      campus: campus,
      openings: openings ?? this.openings,
      applicantCount: applicantCount ?? this.applicantCount,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      responsibilities: responsibilities ?? this.responsibilities,
      requirements: requirements ?? this.requirements,
      applicationLink: applicationLink ?? this.applicationLink,
      bookmarkedBy: bookmarkedBy ?? this.bookmarkedBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
