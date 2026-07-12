import 'package:cloud_firestore/cloud_firestore.dart';

enum VerificationStatus { pending, verified, rejected }

class StartupModel {
  final String id;
  final String ownerId;
  final String name;
  final String tagline;
  final String description;
  final String category;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? websiteUrl;
  final String? linkedInUrl;
  final String? instagramUrl;
  final String? twitterUrl;
  final VerificationStatus verificationStatus;
  final String? verificationNote;
  final String? aluProgramName; // e.g., ALU Ventures, ALU Entrepreneurship
  final String campus;
  final List<String> teamMembers; // user UIDs
  final int teamSize;
  final String stage; // idea, mvp, growth, scale
  final List<String> tags;
  final double averageRating;
  final int reviewCount;
  final int opportunityCount;
  final DateTime foundedDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StartupModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.tagline,
    required this.description,
    required this.category,
    this.logoUrl,
    this.coverImageUrl,
    this.websiteUrl,
    this.linkedInUrl,
    this.instagramUrl,
    this.twitterUrl,
    this.verificationStatus = VerificationStatus.pending,
    this.verificationNote,
    this.aluProgramName,
    required this.campus,
    this.teamMembers = const [],
    this.teamSize = 1,
    this.stage = 'mvp',
    this.tags = const [],
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.opportunityCount = 0,
    required this.foundedDate,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isVerified => verificationStatus == VerificationStatus.verified;
  bool get isPending => verificationStatus == VerificationStatus.pending;
  bool get isRejected => verificationStatus == VerificationStatus.rejected;

  factory StartupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StartupModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      tagline: data['tagline'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      logoUrl: data['logoUrl'],
      coverImageUrl: data['coverImageUrl'],
      websiteUrl: data['websiteUrl'],
      linkedInUrl: data['linkedInUrl'],
      instagramUrl: data['instagramUrl'],
      twitterUrl: data['twitterUrl'],
      verificationStatus: VerificationStatus.values.firstWhere(
        (s) => s.toString().split('.').last == (data['verificationStatus'] ?? 'pending'),
        orElse: () => VerificationStatus.pending,
      ),
      verificationNote: data['verificationNote'],
      aluProgramName: data['aluProgramName'],
      campus: data['campus'] ?? '',
      teamMembers: List<String>.from(data['teamMembers'] ?? []),
      teamSize: data['teamSize'] ?? 1,
      stage: data['stage'] ?? 'mvp',
      tags: List<String>.from(data['tags'] ?? []),
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      opportunityCount: data['opportunityCount'] ?? 0,
      foundedDate: (data['foundedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'name': name,
      'tagline': tagline,
      'description': description,
      'category': category,
      'logoUrl': logoUrl,
      'coverImageUrl': coverImageUrl,
      'websiteUrl': websiteUrl,
      'linkedInUrl': linkedInUrl,
      'instagramUrl': instagramUrl,
      'twitterUrl': twitterUrl,
      'verificationStatus': verificationStatus.toString().split('.').last,
      'verificationNote': verificationNote,
      'aluProgramName': aluProgramName,
      'campus': campus,
      'teamMembers': teamMembers,
      'teamSize': teamSize,
      'stage': stage,
      'tags': tags,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'opportunityCount': opportunityCount,
      'foundedDate': Timestamp.fromDate(foundedDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  StartupModel copyWith({
    String? name,
    String? tagline,
    String? description,
    String? category,
    String? logoUrl,
    String? coverImageUrl,
    String? websiteUrl,
    String? linkedInUrl,
    String? instagramUrl,
    String? twitterUrl,
    VerificationStatus? verificationStatus,
    String? verificationNote,
    String? aluProgramName,
    String? campus,
    List<String>? teamMembers,
    int? teamSize,
    String? stage,
    List<String>? tags,
    double? averageRating,
    int? reviewCount,
    int? opportunityCount,
  }) {
    return StartupModel(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      description: description ?? this.description,
      category: category ?? this.category,
      logoUrl: logoUrl ?? this.logoUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      linkedInUrl: linkedInUrl ?? this.linkedInUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      twitterUrl: twitterUrl ?? this.twitterUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationNote: verificationNote ?? this.verificationNote,
      aluProgramName: aluProgramName ?? this.aluProgramName,
      campus: campus ?? this.campus,
      teamMembers: teamMembers ?? this.teamMembers,
      teamSize: teamSize ?? this.teamSize,
      stage: stage ?? this.stage,
      tags: tags ?? this.tags,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      opportunityCount: opportunityCount ?? this.opportunityCount,
      foundedDate: foundedDate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
