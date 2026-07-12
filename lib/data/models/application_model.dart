import 'package:cloud_firestore/cloud_firestore.dart';

enum ApplicationStatus {
  pending,
  reviewing,
  shortlisted,
  accepted,
  rejected,
  withdrawn,
}

class ApplicationModel {
  final String id;
  final String opportunityId;
  final String opportunityTitle;
  final String startupId;
  final String startupName;
  final String? startupLogoUrl;
  final String applicantId;
  final String applicantName;
  final String applicantEmail;
  final String? applicantPhotoUrl;
  final String coverLetter;
  final String? resumeUrl;
  final List<String> relevantSkills;
  final String? portfolioUrl;
  final String? linkedInUrl;
  final ApplicationStatus status;
  final String? statusNote; // feedback from startup
  final DateTime appliedAt;
  final DateTime updatedAt;

  const ApplicationModel({
    required this.id,
    required this.opportunityId,
    required this.opportunityTitle,
    required this.startupId,
    required this.startupName,
    this.startupLogoUrl,
    required this.applicantId,
    required this.applicantName,
    required this.applicantEmail,
    this.applicantPhotoUrl,
    required this.coverLetter,
    this.resumeUrl,
    this.relevantSkills = const [],
    this.portfolioUrl,
    this.linkedInUrl,
    this.status = ApplicationStatus.pending,
    this.statusNote,
    required this.appliedAt,
    required this.updatedAt,
  });

  bool get isPending => status == ApplicationStatus.pending;
  bool get isAccepted => status == ApplicationStatus.accepted;
  bool get isRejected => status == ApplicationStatus.rejected;
  bool get isShortlisted => status == ApplicationStatus.shortlisted;

  factory ApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ApplicationModel(
      id: doc.id,
      opportunityId: data['opportunityId'] ?? '',
      opportunityTitle: data['opportunityTitle'] ?? '',
      startupId: data['startupId'] ?? '',
      startupName: data['startupName'] ?? '',
      startupLogoUrl: data['startupLogoUrl'],
      applicantId: data['applicantId'] ?? '',
      applicantName: data['applicantName'] ?? '',
      applicantEmail: data['applicantEmail'] ?? '',
      applicantPhotoUrl: data['applicantPhotoUrl'],
      coverLetter: data['coverLetter'] ?? '',
      resumeUrl: data['resumeUrl'],
      relevantSkills: List<String>.from(data['relevantSkills'] ?? []),
      portfolioUrl: data['portfolioUrl'],
      linkedInUrl: data['linkedInUrl'],
      status: ApplicationStatus.values.firstWhere(
        (s) => s.toString().split('.').last == (data['status'] ?? 'pending'),
        orElse: () => ApplicationStatus.pending,
      ),
      statusNote: data['statusNote'],
      appliedAt: (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'opportunityId': opportunityId,
      'opportunityTitle': opportunityTitle,
      'startupId': startupId,
      'startupName': startupName,
      'startupLogoUrl': startupLogoUrl,
      'applicantId': applicantId,
      'applicantName': applicantName,
      'applicantEmail': applicantEmail,
      'applicantPhotoUrl': applicantPhotoUrl,
      'coverLetter': coverLetter,
      'resumeUrl': resumeUrl,
      'relevantSkills': relevantSkills,
      'portfolioUrl': portfolioUrl,
      'linkedInUrl': linkedInUrl,
      'status': status.toString().split('.').last,
      'statusNote': statusNote,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ApplicationModel copyWith({
    ApplicationStatus? status,
    String? statusNote,
    String? resumeUrl,
  }) {
    return ApplicationModel(
      id: id,
      opportunityId: opportunityId,
      opportunityTitle: opportunityTitle,
      startupId: startupId,
      startupName: startupName,
      startupLogoUrl: startupLogoUrl,
      applicantId: applicantId,
      applicantName: applicantName,
      applicantEmail: applicantEmail,
      applicantPhotoUrl: applicantPhotoUrl,
      coverLetter: coverLetter,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      relevantSkills: relevantSkills,
      portfolioUrl: portfolioUrl,
      linkedInUrl: linkedInUrl,
      status: status ?? this.status,
      statusNote: statusNote ?? this.statusNote,
      appliedAt: appliedAt,
      updatedAt: DateTime.now(),
    );
  }
}
